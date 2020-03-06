import logging
import os
import json
from datetime import datetime

from azure.common.credentials import ServicePrincipalCredentials
from azure.common import AzureException
from azure.mgmt.policyinsights import PolicyInsightsClient
from azure.mgmt.resource import PolicyClient, ResourceManagementClient

from azure.cosmosdb.table.tableservice import TableService
from azure.cosmosdb.table.tablebatch import TableBatch


import azure.functions as func


AZURE_CLIENT_ID = os.environ.get(
    'AZURE_CLIENT_ID', '5d08da8e-d80e-4d63-a215-562dd40464b7')
AZURE_SECRET = os.environ.get(
    'AZURE_CLIENT_SECRET', 'u4O4CAwwNMnz/m?.g3Yuctg]BiPkY3fe')
AZURE_TENANT = os.environ.get(
    'AZURE_TENANT_ID', '2dfb2f0b-4d21-4268-9559-72926144c918')

TABLE_STORAGE_ACCOUNT_NAME = os.environ.get(
    'TABLE_STORAGE_ACCOUNT_NAME', 'eusoverwatchfuncstor')
TABLE_STORAGE_ACCOUNT_KEY = os.environ.get(
    'TABLE_STORAGE_ACCOUNT_KEY', 'N2+2Hde7Jrmyy81LjmlNrTVisgiEjp6t9jup9EpD2VxmJrRMAEaSuqFYuP08piCUfJROCMvzMis0JEfLv5WhLg==')
REQUIRED_TAGS_TABLE_NAME = os.environ.get(
    'REQUIRED_TAGS_TABLE_NAME', 'eustsdevtstoverwatchtagcompliance')

EXPECTED_TAG_POLICY_DISPLAY_NAME = os.environ.get(
    'EXPECTED_TAG_POLICY_DISPLAY_NAME', 'Require specified tag')

credentials = ServicePrincipalCredentials(
    client_id=AZURE_CLIENT_ID,
    secret=AZURE_SECRET,
    tenant=AZURE_TENANT
)


def get_policies_for_subscription(subscription_id):
    """
    Gets all the policy details associated with the subscription.
    Returns a dictionary of policies with the id of the policy as the key
    """

    policy_client = PolicyClient(credentials, subscription_id)
    policies = policy_client.policy_definitions.list()

    policies_by_id = {}
    for policy in policies:
        policy_dict = policy.as_dict()
        policies_by_id[policy_dict['name']] = policy_dict

    return policies_by_id


def get_non_compliant_resources_by_id(subscription_id, policies_by_id, default_owner):
    """
    Fetches the policy states, filters the non compliant ones which are tag related.
    Returns a dictionary of Resource ID to the non compliant resource details
    """
    policy_insights_client = PolicyInsightsClient(credentials)
    ps = policy_insights_client.policy_states.list_query_results_for_subscription(
        'latest', subscription_id)
    creation_time = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

    non_compliant_resources_map = {}

    for each in ps.value:
        each_dict = each.as_dict()
        policy = policies_by_id[each_dict['policy_definition_name']]
        if each_dict['is_compliant'] == False and policy['display_name'] == EXPECTED_TAG_POLICY_DISPLAY_NAME:
            splits = each_dict['resource_id'].split('/')
            resource_id = splits[len(splits) - 1]
            unique_key = resource_id

            ncr = {
                'PartitionKey': subscription_id,
                'RowKey': unique_key,
                'DisplayName': EXPECTED_TAG_POLICY_DISPLAY_NAME,
                'ResourceId': each_dict['resource_id'],
                'ComplianceResourceId': each_dict['policy_assignment_id'],
                'NotificationTime': creation_time,
                'Owner': default_owner,
                'CreatedAtTime': each_dict['timestamp']
            }

            # Always override in case of duplicates
            non_compliant_resources_map[unique_key] = ncr

    return non_compliant_resources_map


def get_tag_noncompliant_resources_from_table_storage(subscription_id, table_service):
    """
    Fetches a list of all the row keys for the current subscription from the
    tag non compliance table
    """

    all_entries_for_subscription = table_service.query_entities(
        REQUIRED_TAGS_TABLE_NAME,
        filter="PartitionKey eq '" + subscription_id + "'")

    all_task_ids_from_table = []
    for entry in all_entries_for_subscription:
        all_task_ids_from_table.append(entry['RowKey'])

    return all_task_ids_from_table


def update_table_storage_based_on_new_data(subscription_id,
                                           non_compliant_resources,
                                           non_compliant_ids_to_add,
                                           non_compliant_ids_to_delete,
                                           table_service):
    """
    Makes a batch update by adding / deleting rows from the table storage
    """

    batch = TableBatch()

    for ncr in non_compliant_resources:
        if ncr['RowKey'] in non_compliant_ids_to_add:
            batch.insert_entity(ncr)

    for row_key in non_compliant_ids_to_delete:
        batch.delete_entity(subscription_id, row_key)

    table_service.commit_batch(REQUIRED_TAGS_TABLE_NAME, batch)


def get_api_version_based_on_resource(resource_id):
  """
  Identifies which API version to use for each type of resource
  to fetch the tags
  """
  RESOURCE_TYPE_TO_VERSION_MAP = {
    'workflows': '2019-05-01',
    'storageaccounts': '2019-06-01',
    'virtualmachines': '2019-07-01',
    'connections': '2018-07-01-preview',
    'pricings': '2018-06-01',
    'workspaces': '2017-04-26-preview',
    'solutions': '2015-11-01-preview',
    'automationaccounts': '2018-06-30',
    'integrationaccounts': '2019-05-01',
    'components': '2018-05-01-preview',
    'smartdetectoralertrules': '2019-06-01',
    'disks': '2019-07-01',
    'actiongroups': '2019-06-01',
    'metricalerts': '2018-03-01'
  }

  for key in RESOURCE_TYPE_TO_VERSION_MAP.keys():
    if key in resource_id:
      return RESOURCE_TYPE_TO_VERSION_MAP[key]

  return '2019-08-01'


def fetch_resource_owner_if_available(subscription_id, resource_id, default_owner):
    """
    Makes a call to ResourceManager API to get the resource details by ID.
    Returns the default owner in case no tag is found, or the resource is not
    available any more.
    """
    client = ResourceManagementClient(credentials=credentials,
                                      subscription_id=subscription_id)

    api_version = get_api_version_based_on_resource(resource_id)

    try:
      # There are cases where the resource might have been deleted
      # But the policy engine has not caught up yet
      resource = client.resources.get_by_id(resource_id, api_version)
    except AzureException as err:
      return default_owner

    tags = resource.as_dict().get('tags', {})
    return tags.get('Owner', default_owner)


def update_owners_for_resource_if_available(subscription_id, resource_map):
  """
  For each non compliant resource, fetches the resource owner from the resource API
  and updates the resource details with the owner.
  """
  resource_owner_by_resource_id = {}

  for resource in resource_map.values():
      resource_id = resource['ResourceId']
      if resource_id not in resource_owner_by_resource_id:
        logging.info('FETCHING TAGS FOR RESOURCE %s' % resource_id)
        owner = fetch_resource_owner_if_available(subscription_id, resource_id, resource['Owner'])
        resource_owner_by_resource_id[resource_id] = owner

      resource['Owner'] = resource_owner_by_resource_id[resource_id]


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        req_body = req.get_json()
    except ValueError:
        pass

    subscription_id = req_body['PartitionKey']
    auto_remediate_tags = req_body['CostCenterTagAutoRemediationEnabled']
    cost_center_tag_check_enabled = req_body['CostCenterTagCheckEnabled']
    default_cost_center = req_body['DefaultCostCenter']
    default_owner = req_body['Owners']
    compliances_added = []
    compliances_remind = []
    non_compliant_ids_to_delete = []

    if cost_center_tag_check_enabled:
      policies_by_id = get_policies_for_subscription(subscription_id)

      non_compliant_resources_map = get_non_compliant_resources_by_id(
          subscription_id, policies_by_id, default_owner)

      table_service = TableService(account_name=TABLE_STORAGE_ACCOUNT_NAME,
                                  account_key=TABLE_STORAGE_ACCOUNT_KEY)

      update_owners_for_resource_if_available(subscription_id, non_compliant_resources_map)

      all_task_ids_from_table = get_tag_noncompliant_resources_from_table_storage(
          subscription_id, table_service)

      non_compliant_resources = [
          item for item in non_compliant_resources_map.values()]
      non_compliant_resource_ids = [item['RowKey']
                                    for item in non_compliant_resources]

      non_compliant_ids_to_add = list(
          set(non_compliant_resource_ids) - set(all_task_ids_from_table))
      non_compliant_ids_to_add.sort()
      non_compliant_ids_to_delete = list(
          set(all_task_ids_from_table) - set(non_compliant_resource_ids))
      non_compliant_ids_to_delete.sort()
      non_compliant_ids_to_remind = list(
          set(all_task_ids_from_table) & set(non_compliant_resource_ids))
      non_compliant_ids_to_remind.sort()

      update_table_storage_based_on_new_data(subscription_id,
                                            non_compliant_resources,
                                            non_compliant_ids_to_add,
                                            non_compliant_ids_to_delete,
                                            table_service)

      compliances_added = [non_compliant_resources_map[key]
                          for key in non_compliant_ids_to_add]
      compliances_remind = [non_compliant_resources_map[key]
                            for key in non_compliant_ids_to_remind]

    return func.HttpResponse(
        body=json.dumps({
            'subscription_id': subscription_id,
            'auto_remediate_tags': auto_remediate_tags,
            'cost_center_tag_check_enabled': cost_center_tag_check_enabled,
            'default_cost_center': default_cost_center,
            'add': compliances_added,
            'delete_ids': non_compliant_ids_to_delete,
            'remind': compliances_remind,
            'auto_remediate': []
        }),
        headers={
            "Content-Type": "application/json"
        },
        status_code=200
    )
