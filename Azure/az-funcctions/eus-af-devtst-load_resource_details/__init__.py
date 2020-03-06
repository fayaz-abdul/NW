import logging
import os
import json

from azure.common.credentials import ServicePrincipalCredentials

import azure.functions as func
from azure.mgmt.resource import ResourceManagementClient


credentials = ServicePrincipalCredentials(
    client_id='5d08da8e-d80e-4d63-a215-562dd40464b7', # os.environ['AZURE_CLIENT_ID'],
    secret='u4O4CAwwNMnz/m?.g3Yuctg]BiPkY3fe', #os.environ['AZURE_CLIENT_SECRET'],
    tenant='2dfb2f0b-4d21-4268-9559-72926144c918' # os.environ['AZURE_TENANT_ID']
)


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    try:
        req_body = req.get_json()
    except ValueError:
        pass

    subscription_id = req_body['SubscriptionId']
    resource_id = req_body['ResourceId']

    client = ResourceManagementClient(credentials=credentials,
                        subscription_id=subscription_id)

    logging.info('REQUEST BODY ----')
    logging.info(req_body)

    resource = client.resources.get_by_id(resource_id, '2019-07-01')

    tags = resource.as_dict().get('tags', {})
    technical_owner = tags.get('TechnicalOwner', None)

    return func.HttpResponse(
          body=json.dumps({
            'ResourceId': resource_id,
            'TechnicalOwner': technical_owner,
            'resource': resource.as_dict()
          }),
          headers={
            "Content-Type": "application/json"
          },
          status_code=200
    )
