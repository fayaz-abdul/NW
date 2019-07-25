from servicenow_core import const as sn_const
from servicenow_core.ServiceNow import ServiceNow
from pprint import pprint
import os, elasticsearch, datetime, time
from elasticsearch.helpers import bulk, scan
# esuser:3mcXw6jHghx7RUen

ENV_VARS = {

"DEBUG": "true",
"ES_HOST": "vpc-catchpoint-xpkjoysrybinopvx33jaldu4li.us-west-2.es.amazonaws.com",
"ES_REGION": "us-west-1",
"ES_INDEX": "servicenow",
"ES_DOCNAME": "cmdb"
}

os.environ.update(ENV_VARS)

def lambda_handler(event, context):
    main()


CI_UNIX = 'cmdb_ci_unix_server'
CI_SOLARIS = 'cmdb_ci_solaris_server'
CI_LINUX = 'cmdb_ci_linux_server'
CI_WIN = 'cmdb_ci_win_server'
CI_ROUTER = 'cmdb_ci_ip_router'
CI_SWITCH = 'cmdb_ci_ip_switch'
CI_UPS = 'cmdb_ci_ups'
CI_VCENTER = 'cmdb_ci_vcenter'
CI_ESX = 'cmdb_ci_esx_server'
CI_STORAGE = 'cmdb_ci_msd'
CI_NETWORK_ADAPTER = 'cmdb_ci_network_adapter'

def convert(input):
    if isinstance(input, dict):
        return {convert(key): convert(value) for key, value in input.iteritems()}
    elif isinstance(input, list):
        return [convert(element) for element in input]
    elif isinstance(input, unicode):
        return input.encode('utf-8')
    else:
        return input

def main():
    start_time = time.time()
    # ServiceNow CMDB account credentials
    SN_INSTANCE = 'autodesk'
    # SN_USER = 't_abduf'
    # SN_PASSWORD = 'Icecream_123'
    SN_USER = 'logicmon'
    SN_PASSWORD = 'L0g1c_M0n!'
    MAX_CMDB_DEVICES_TO_FETCH = 3000
    CMDB_SYNC_CLASSES = [
                        # sn_const.CI_UNIX,
                        # sn_const.CI_SOLARIS,
                        sn_const.CI_LINUX
                         # sn_const.CI_ROUTER,
                         # sn_const.CI_SWITCH,
                         # sn_const.CI_UPS,
                         # sn_const.CI_VCENTER,
                         # sn_const.CI_ESX,
                         # sn_const.CI_STORAGE,
                         #  sn_const.CI_WIN,
                         # sn_const.CI_NETWORK_ADAPTER
    ]


    client = ServiceNow(SN_INSTANCE, SN_USER,
                        SN_PASSWORD)
    print client
    #print time.strftime("%Y%m%dT%H%M%SZ",

    es = elasticsearch.Elasticsearch(
        hosts=[{'host': os.environ['ES_HOST'], 'port': 443}],
        region=os.environ['ES_REGION'],
        use_ssl=True,
        verify_certs=True,
        connection_class=elasticsearch.connection.RequestsHttpConnection)
    print es
    # try:
    #     create_index = es.indices.create("servicenow")
    #     if "acknowledged" in create_index and create_index["acknowledged"] != True:
    #         print "Index creation failed..." + str(create_index)
    # except Exception, e:
    #     print str(e)

    bulk_deletes = []
    # Start the initial search.
    hits = es.search(
        q="name:fake",
        index="servicenow",
        size=5
    )
    if hits["hits"]["total"]:
        print "match"
        es.delete_by_query(body={"query":{"match": {"name": "fake"}}},index="servicenow", doc_type="cmdb")
        es.ingest()
    docs = []
    fake = {'_index': 'servicenow',
 '_source': {'@timestamp': '20180606T154114Z',
             u'asset': u'',
             u'asset_tag': u'4962934-5',
             u'assigned': u'2005-02-01 00:00:00',
             u'assigned_to': {u'display_value': u'Neil Reuben',
                              u'link': u'https://autodesk.service-now.com/api/now/table/sys_user/bbed286f0a0a3c550197ccf64eba0ce7'},
             u'assignment_group': u'',
             u'attributes': u'',
             u'can_print': u'false',
             u'category': u'Hardware',
             u'cd_rom': u'false',
             u'cd_speed': u'',
             u'cfg_auto_management_server': u'',
             u'change_control': u'',
             u'change_request': u'',
             u'chassis_type': None,
             u'checked_in': u'',
             u'checked_out': u'',
             u'classification': u'Production',
             u'comments': u'CHG0046399',
             u'company': u'',
             u'correlation_id': u'',
             u'cost': u'',
             u'cost_cc': u'USD',
             u'cost_center': {u'display_value': u'',
                               u'link': u''},
             u'cpu_core_count': u'1',
             u'cpu_core_thread': u'2',
             u'cpu_count': u'2',
             u'cpu_manufacturer': {u'display_value': u'sparcv9',
                                   u'link': u'https://autodesk.service-now.com/api/now/table/core_company/819e78136fa5f1081560e4bc5d3ee439'},
             u'cpu_name': u'',
             u'cpu_speed': u'1,280',
             u'cpu_type': u'sparcv9',
             u'default_gateway': u'',
             u'delivery_date': u'',
             u'department': {u'display_value': u'EIS-Information Infrastructure',
                             u'link': u'https://autodesk.service-now.com/api/now/table/cmn_department/bbeb6cd50a0a3c5500938a401e53e1c2'},
             u'discovery_source': u'Service-now',
             u'disk_space': u'410',
             u'dns_domain': u'ads.autodesk.com',
             u'dr_backup': u'',
             u'due': u'',
             u'due_in': None,
             u'fault_count': u'0',
             u'firewall_status': u'Intranet',
             u'first_discovered': u'2012-01-31 10:05:55',
             u'floppy': None,
             u'form_factor': None,
             u'fqdn': u'mannbu01.autodesk.com',
             u'gl_account': u'',
             u'hardware_status': u'Installed',
             u'host_domain': u'',
             u'host_name': u'mannbu01',
             u'install_date': u'',
             u'install_status': u'',
             u'invoice_number': u'',
             u'ip_address': u'144.111.72.79',
             u'justification': u'',
             u'last_discovered': u'2016-04-09 09:03:03',
             u'lease_id': u'',
             u'location': {u'display_value': u'US Manchester',
                           u'link': u'https://autodesk.service-now.com/api/now/table/cmn_location/d11a5a0b0a0a3c5501900c7bea73677b'},
             u'mac_address': u'',
             u'managed_by': u'',
             u'manufacturer': {u'display_value': u'Sun Microsystems',
                               u'link': u'https://autodesk.service-now.com/api/now/table/core_company/d6a719600a0a3c55002a0ba273edc44d'},
             u'metric_type': u'',
             u'model_id': {u'display_value': u'Sun Microsystems Sun Fire V240',
                           u'link': u'https://autodesk.service-now.com/api/now/table/cmdb_model/6b31302c0a0a3c5500b713cf7c06d894'},
             u'model_number': {u'display_value': u'',
                               u'link': u''},
             u'monitor': u'false',
             u'name': u'fake',
             u'ng_assignment_flag': u'Ready',
             u'object_id': u'',
             u'operational_status': u'Decommissioned',
             u'order_date': u'',
             u'os': u'Solaris',
             u'os_address_width': u'',
             u'os_domain': u'',
             u'os_service_pack': u'',
             u'os_version': u'5.9',
             u'owned_by': {u'display_value': u'Satish Kumar',
                           u'link': u'https://autodesk.service-now.com/api/now/table/sys_user/ec832bba872ce88092ebfcca7e434d01'},
             u'po_number': u'4590247',
             u'purchase_date': u'2004-08-12',
             u'ram': u'8,192',
             u'repair_contract_id': u'',
             u'returned_from_repair': u'',
             u'sent_for_repair': u'',
             u'serial_number': u'FN43210525',
             u'short_description': u'SunOS mannbu01 5.9 Generic_122300-61 sun4u sparc SUNW,Sun-Fire-V240 Solaris',
             u'skip_sync': u'false',
             u'start_date': u'2015-01-29 03:48:00',
             u'subcategory': u'Computer',
             u'support_group': {u'display_value': u'EIS EO Storage Operations',
                                u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/85d876a86854614c161ac25c553fe4db'},
             u'supported_by': u'',
             u'sys_class_name': u'Solaris Server',
             u'sys_class_path': u'/!!/!O/!!/!$/!1/!$',
             u'sys_created_by': u'bob.mitchell',
             u'sys_created_on': u'2010-05-26 12:17:43',
             u'sys_domain': {u'display_value': u'global',
                             u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/global'},
             u'sys_domain_path': u'',
             u'sys_id': u'd60c81d80a0a3c5500fe3e692489de3b',
             u'sys_mod_count': u'45',
             u'sys_tags': u'',
             u'sys_updated_by': u'system',
             u'sys_updated_on': u'2018-05-15 00:18:44',
             u'u_access_review': {u'display_value': u'', u'link': u''},
             u'u_auto_ops': u'false',
             u'u_back_up_performed': u'false',
             u'u_bios_version': u'',
             u'u_blade_bay': u'',
             u'u_blade_enclosure': {u'display_value': u'', u'link': u''},
             u'u_business_contact': {u'display_value': u'', u'link': u''},
             u'u_change_freeze_approval': {u'display_value': u'Craig Aufenkamp',
                                           u'link': u'https://autodesk.service-now.com/api/now/table/sys_user/22009a3a6fefb5c04f6d04caea3ee4f5'},
             u'u_change_manager_group': u'',
             u'u_ci_source': u'Physical Audit',
             u'u_contract': u'',
             u'u_criticality': u'N/A',
             u'u_customer_base': None,
             u'u_data_accuracy_validated': u'false',
             u'u_device_age': u'13.76',
             u'u_disaster_recovery': None,
             u'u_disposition_reference_number': u'',
             u'u_dl_email_adsk': u'',
             u'u_dl_email_sev1': u'1155944bf4336844161a655712355492',
             u'u_dl_email_sev2': u'1d55944bf4336844161a655712355493',
             u'u_dr_location': {u'display_value': u'', u'link': u''},
             u'u_end_date': u'',
             u'u_end_of_life_date': u'',
             u'u_end_of_software_support': u'',
             u'u_environment': u'Production',
             u'u_escalation_level_1': {u'display_value': u'EIS EO Unix Operations',
                                       u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/89d876a86854614c161ac25c553fe4d4'},
             u'u_escalation_level_2': {u'display_value': u'EIS EO Unix Operations',
                                       u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/89d876a86854614c161ac25c553fe4d4'},
             u'u_escalation_level_3': {u'display_value': u'EIS EO Unix Operations',
                                       u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/89d876a86854614c161ac25c553fe4d4'},
             u'u_escalation_level_4': {u'display_value': u'EIS EO Unix Operations',
                                       u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/89d876a86854614c161ac25c553fe4d4'},
             u'u_escalation_level_5':{u'display_value': u'EIS EO Unix Operations',
                                       u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/89d876a86854614c161ac25c553fe4d4'},
             u'u_external_vendor': u'',
             u'u_external_vendor_contact': u'',
             u'u_floor': u'4North',
             u'u_heartbeat': u'',
             u'u_incident_count': u'0',
             u'u_last_sccm_heartbeat': u'',
             u'u_last_test_date': u'',
             u'u_logical_ownership': {u'display_value': u'DES Storage Operations Team',
                                      u'link': u'https://autodesk.service-now.com/api/now/table/sys_user_group/44a18c0d6858254c161ac25c553fe43d'},
             u'u_maintenance_po': u'',
             u'u_management_type': u'EIS',
             u'u_managing_system': u'IPCENTER',
             u'u_monitored_by': {u'display_value': u'LogicMonitor',
                                 u'link': u'https://autodesk.service-now.com/api/now/table/core_company/4fd4cc0d6ff371041560e4bc5d3ee462'},
             u'u_non_operational_status': None,
             u'u_oob_access_method': u'',
             u'u_oob_management_ip_address': u'',
             u'u_po_line_number': u'',
             u'u_policy_exception': u'false',
             u'u_primary_division': u'',
             u'u_rack': u'1',
             u'u_recovery_point_objective': None,
             u'u_recovery_point_objective__rp': u'Not identified',
             u'u_recovery_time_objective__rto': None,
             u'u_related_application': {u'display_value': u'Backup Systems',
                                        u'link': u'https://autodesk.service-now.com/api/now/table/cmdb_ci/f73bd3f741bece40ea13800fb855c6eb'},
             u'u_retired_status': None,
             u'u_room': u'IDF',
             u'u_row': u'',
             u'u_ru': u'',
             u'u_sap_number': u'',
             u'u_sla': {u'display_value': u'',
                               u'link': u''},
             u'u_snmp_ro_string': u'',
             u'u_snmp_version': u'3',
             u'u_soc_indicator': u'false',
             u'u_sox_approval_group': u'',
             u'u_sox_approver': {u'display_value': u'',
                               u'link': u''},
             u'u_sox_indicator': u'false',
             u'u_spare_status': None,
             u'u_suggested_lifespan': u'3 Years',
             u'u_support_level': u'',
             u'u_support_tier': u'Tier 3',
             u'u_support_type': None,
             u'u_technical_business_contact': {u'display_value': u'',
                               u'link': u''},
             u'u_technical_review_group': {u'display_value': u'',
                               u'link': u''},
             u'u_technical_reviewer': u'',
             u'u_used_for': u'Production',
             u'u_vendor_billing_information': None,
             u'unverified': u'false',
             u'used_for': u'Production',
             u'vendor': {u'display_value': u'',
                               u'link': u''},
             u'virtual': u'false',
             u'warranty_expiration': u'',
             u'x_ever_metro_porta_primary_computer': u'false'},
 # '_type': 'cmdb'
            }
    docs.append(fake)
    # success, _ = bulk(es, docs, index=os.environ['ES_INDEX'], raise_on_error=True)
    # docs.remove(fake)

    es.search(index=os.environ['ES_INDEX'], doc_type= 'cmdb', body={})
    es.search()
    return ""
    count = 0
    docs = []
    for cmsycl in  CMDB_SYNC_CLASSES:
        response = None
        try:
            response = client.get_cis(cmsycl, MAX_CMDB_DEVICES_TO_FETCH, 0, True)
        except Exception, e:
            print "Exception for %s: %s" % (cmsycl, str(e))

        if not response or not response["result"]:
            continue
        print "%s: %s" %(cmsycl, len(response["result"]))
        for abc in response["result"]:
            doc = {
                "_index": os.environ['ES_INDEX'],
                "_type": os.environ['ES_DOCNAME'],
                "_source": {
                    "@timestamp": datetime.datetime.now().strftime("%Y%m%dT%H%M%SZ")
                }
            }

            for i in ["u_escalation_level_1", "u_escalation_level_2", "u_escalation_level_3", "u_escalation_level_4",
                      "u_escalation_level_5", "department", "u_logical_ownership", "u_related_application",
                      "cpu_manufacturer","model_number", "manufacturer", "u_dr_location", "cost_center", "u_technical_business_contact",
                      "owned_by", "vendor", "u_access_review", "model_id", "u_sox_approver", "u_technical_review_group",
                      "location", "u_sla", "u_blade_enclosure", "u_change_freeze_approval", "assigned_to", "support_group",
                      "u_business_contact"]:
                if i not in abc:
                    abc[i] = {"link": "", "display_value": ""}
                if "display_value" not in abc[i]:
                    abc[i] = {"link": "", "display_value": ""}
            for i in ["purchase_date"]:
                if i not in abc:
                    abc[i] = "1970-01-01"
                if not abc[i]:
                    abc[i] = "1970-01-01"


            doc["_source"].update(abc)
            docs.append(doc)
    success, _ = bulk(es, docs, index=os.environ['ES_INDEX'], raise_on_error=True)
    count += success
    print("INFO: inserted %s documents" % (count))
    print("--- %s seconds ---" % (time.time() - start_time))

main()