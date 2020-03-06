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

credentials = ServicePrincipalCredentials(
    client_id=AZURE_CLIENT_ID,
    secret=AZURE_SECRET,
    tenant=AZURE_TENANT
)


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


def fetch_tags_if_available(subscription_id, resource_id):
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
    # except AzureException as err:
    except:
      return {}

    return resource.as_dict().get('tags', {})


def update_tags_for_resource(subscription_id, resource_id, tags):
  client = ResourceManagementClient(credentials=credentials,
                                    subscription_id=subscription_id)

  api_version = get_api_version_based_on_resource(resource_id)

  logging.info('Trying to add %s tags to %s resource' % (tags, resource_id))
  # There are cases where the resource might have been deleted
  # But the policy engine has not caught up yet
  # resource = client.resources.update_by_id(resource_id, api_version, {
  client.resources.update_by_id(resource_id, api_version, {
    'tags': tags
  })


def remove_entry_for_resource(subscription_id, row_keys, table_service):
  batch = TableBatch()

  for row_key in row_keys:
    batch.delete_entity(subscription_id, row_key)

  table_service.commit_batch(REQUIRED_TAGS_TABLE_NAME, batch)


def remediate_tags_for_resources(subscription_id, default_cost_center, resources):
  row_keys_remediated = []
  resources_to_email = list(resources)
  for resource in resources:
    resource_id = resource['ResourceId']
    tags = fetch_tags_if_available(subscription_id, resource_id)
    cost_center = tags.get('CostCenter', default_cost_center)
    tags['CostCenter'] = cost_center
    try:
      update_tags_for_resource(subscription_id, resource_id, tags)
      row_keys_remediated.append(resource['RowKey'])
      resources_to_email.remove(resource)
    except AzureException as err:
      logging.warn('Unable to add tags to resource id %s' % resource_id)
      logging.error(err)
    except Exception as err:
      logging.warn('Unable to add tags to resource id %s' % resource_id)
      logging.error(err)

  return row_keys_remediated, resources_to_email


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        req_body = req.get_json()
    except ValueError:
        pass


    subscription_id = req_body['subscription_id']
    auto_remediate_tags = req_body['auto_remediate_tags']
    cost_center_tag_check_enabled = req_body['cost_center_tag_check_enabled']
    default_cost_center = req_body['default_cost_center']
    failed_compliances_added = req_body['add']
    failed_compliances_remind = req_body['remind']

    added_resources_left = failed_compliances_added
    remind_resources_left = failed_compliances_remind
    auto_remediate_resources = []

    if cost_center_tag_check_enabled and auto_remediate_tags:
      table_service = TableService(account_name=TABLE_STORAGE_ACCOUNT_NAME,
                                  account_key=TABLE_STORAGE_ACCOUNT_KEY)

      row_keys_removed = []

      removed_rows, added_resources_left = remediate_tags_for_resources(
        subscription_id, default_cost_center, failed_compliances_added)

      for resource in failed_compliances_added:	
        if resource['RowKey'] in removed_rows:	
          auto_remediate_resources.append(resource)

      row_keys_removed.extend(removed_rows)

      removed_rows, remind_resources_left = remediate_tags_for_resources(
        subscription_id, default_cost_center, failed_compliances_remind)

      for resource in failed_compliances_remind:	
        if resource['RowKey'] in removed_rows:	
          auto_remediate_resources.append(resource)

      row_keys_removed.extend(removed_rows)

      remove_entry_for_resource(subscription_id, row_keys_removed, table_service)

    return func.HttpResponse(
        body=json.dumps({
          'add': added_resources_left,
          'remind': remind_resources_left,
          'subscription_id': subscription_id,	
          'auto_remediate': auto_remediate_resources
        }),
        headers={
            "Content-Type": "application/json"
        },
        status_code=200
    )
