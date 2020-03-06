import logging
import os
import json

from azure.common.credentials import ServicePrincipalCredentials
from azure.mgmt.security import SecurityCenter

import azure.functions as func
from azure.mgmt.resource import ResourceManagementClient


    #os.environ.get(
    #'AZURE_SUBSCRIPTION_ID',
    # ) # your Azure Subscription Id
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

    subscription_id = req_body['PartitionKey'] # '40fb353a-d355-4197-b2a5-92e71f07f063'
    alert_id = req_body['RowKey']

    client = SecurityCenter(credentials=credentials,
                        subscription_id=subscription_id,
                        asc_location='eastus')

    logging.info('REQUEST BODY ----')
    logging.info(req_body)

    state = 'NotFound'
    alerts = client.alerts.list()
    logging.info('ALERTS CALL MADE')

    for alert in alerts:
      alert_dict = alert.as_dict()
      if alert_dict['name'] == alert_id:
        logging.info('ALERT FOUND WITH NAME %s  AND STATE %s' % (alert_id, alert_dict['state']))
        state = alert_dict['state']

    return func.HttpResponse(
          body=json.dumps({
            'name': alert_id,
            'state': state
          }),
          headers={
            "Content-Type": "application/json"
          },
          status_code=200
    )
