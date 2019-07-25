import csv
import multiprocessing
import os
import socket
import traceback
import datetime
import pytz
import logging
import sys

from StringIO import StringIO as StringBuffer
from joblib import Parallel, delayed
from logging.handlers import RotatingFileHandler

from logicmonitor_core import const as lm_const
from logicmonitor_core.LogicMonitor import LogicMonitor
from servicenow_core import const as sn_const
from servicenow_core.ServiceNow import ServiceNow


class CmdbSync:
    ############################################################################
    # CMDB SYNC CONFIGURATION SETTINGS
    ############################################################################

    GROUP_CACHE = {}

    CMDB_TYPE = 'ServiceNow'

    # Classes to be synced from cmdb to LogicMonitor
    CMDB_SYNC_CLASSES = [sn_const.CI_LINUX,
                         sn_const.CI_STORAGE,
                         sn_const.CI_ESX,
                         sn_const.CI_SOLARIS]

    # Two way map of cmdb class name to class display name
    CLASS_NAME_MAP = {sn_const.CI_LINUX: 'Linux Server',
                      sn_const.CI_STORAGE: 'Mass Storage Device',
                      sn_const.CI_ESX: 'ESX Server',
                      sn_const.CI_SOLARIS: 'Solaris Server',
                      'Linux Server': sn_const.CI_LINUX,
                      'Mass Storage Device': sn_const.CI_STORAGE,
                      'ESX Server': sn_const.CI_ESX,
                      'Solaris Server': sn_const.CI_SOLARIS}

    # ServiceNow property names to LogicMonitor property name mapping and
    # and whether they are required properties.
    DIRECT_PROPERTIES = [[sn_const.SN_NAME, lm_const.OBJ_DISPLAY_NAME, True],
                         [sn_const.SN_IP_ADDRESS, lm_const.OBJ_NAME, True]]

    # ServiceNow property names to LogicMonitor custom property name mapping and
    # and whether they are required properties.
    CUSTOM_PROPERTIES = [[sn_const.SN_CLASS_NAME, 'sn.sys_class_name', True],
                         [sn_const.SN_MANUFACTURER, 'sn.manufacturer', False],
                         [sn_const.SN_SUPPORT_TIER, 'sn.u_support_tier', True],
                         [sn_const.SN_ENVIRONMENT, 'sn.u_used_for', True],
                         [sn_const.SN_SUPPORT_GROUP, 'sn.support_group', True],
                         [sn_const.SN_OPERATIONAL_STATUS, 'sn.operational_status', True],
                         [sn_const.SN_ID, 'sn.sys_id', True],
                         [sn_const.SN_OS, 'sn.os', False],
                         [sn_const.SN_LOCATION, lm_const.OBJ_LOCATION, False]]

    # Enable/disable if code is executing in AWS used for logging to stdout
    IS_AWS = True
    # Path and file to store logging related to the cmdb sync
    LOG_FILENAME = '/tmp/autodesk_cmdb_sync.log'
    # Path and file to store the last run datetime for incremental syncing
    LASTRUN_FILENAME = '/tmp/autodesk_cmdb_sync_lastrun.log'
    # Filename containing the device to collector mapping
    COLLECTOR_MAPPING = 'collector_mapping.csv'
    # Enable/disable using device to collector mapping feature
    USE_MAPPING = True
    # If USE_MAPPING is disabled specify a collector ID for device creation
    COLLECTOR_MAPPING_ID = 5
    # Enable/disable the use of incremental syncing
    # USE_INCREMENTAL_SYNC = True
    USE_INCREMENTAL_SYNC = os.environ['use_incremental_sync'] == 'True'
    # Enable/disable updating of existing devices.
    ALLOW_UPDATE = True
    # Maximum number of devices to be fetched from the cmdb
    MAX_CMDB_DEVICES_TO_FETCH = 3000
    # Schedule that the code is expected to run on.
    # SYNC_SCHEDULE_MINUTES = 60
    SYNC_SCHEDULE_MINUTES = int(os.environ['sync_schedule_minutes'])

    # ServiceNow CMDB account credentials
    SN_INSTANCE = 'autodesk'
    SN_USER = 'logicmon'
    SN_PASSWORD = 'L0g1c_M0n!'

    # LogicMonitor portal account credentials
    LM_PORTAL = 'autodesk'
    LM_ID = 'A4X9nssR9SF2MN6bU9eK'
    LM_KEY = '8+3}6-[$]+D376=zA5}=^d2kQ3-4J9%jKNaG76G_'
    LM_AUTH = lm_const.AUTH_TYPE_TOKEN

    ############################################################################

    def __init__(self):
        self.__last_run_datetime = None
        self.__lm_client = None
        self.__cmdb_client = None
        self.__collectors = None
        self.__collector_map = None

        self.__configure_logging()
        self.__configure_clients()

    def __configure_logging(self):
        self._logger = logging.getLogger('cmdbSync')

        file_handler = RotatingFileHandler(self.LOG_FILENAME, maxBytes=10000000,
                                           backupCount=1)
        self._logger.addHandler(file_handler)

        if not self.IS_AWS:
            console_handler = logging.StreamHandler()
            self._logger.addHandler(console_handler)

        self._logger.setLevel(logging.INFO)

    def __configure_clients(self):
        self.__lm_client = LogicMonitor(self.LM_PORTAL, self.LM_ID, self.LM_KEY,
                                        self.LM_AUTH, self._logger)
        self.__cmdb_client = ServiceNow(self.SN_INSTANCE, self.SN_USER,
                                        self.SN_PASSWORD)

    def __configure_collector_mapping(self):
        self.__log_message('Reading LogicMonitor device to collector mapping.')

        # Read in all collectors from portal and create a name to ID map
        collectors = self.__lm_client.get_collectors()
        self.__collectors = {}
        for collector in collectors:
            k = collector[lm_const.OBJ_HOSTNAME]
            v = [collector[lm_const.OBJ_ID],
                 collector[lm_const.OBJ_NUM_HOSTS]]
            self.__collectors[k] = v

        self.__collector_map = {}
        with open(self.COLLECTOR_MAPPING, mode='r') as infile:
            reader = csv.reader(infile)
            reader.next()
            for rows in reader:
                k = rows[0] + ':' + rows[2] + ':' + rows[3]
                collectors_to_map = []
                collector_names = rows[4].split(':')
                for collector_name in collector_names:
                    if collector_name not in self.__collectors:
                        self.__log_message(
                            'Could not find collector in LogicMonitor '
                            'portal with name [' + collector_name +
                            ']. Mapping not created.')
                    else:
                        collectors_to_map.append(collector_name)
                v = collectors_to_map
                self.__collector_map[k] = v

        self.__log_message('Reading LogicMonitor device to collector mapping.')

    # def __configure_incremental_sync(self):
    #     fname = self.LASTRUN_FILENAME
    #     if self.USE_INCREMENTAL_SYNC:
    #         if os.path.isfile(fname):
    #             with open(fname, 'r') as f:
    #                 last_run_datetime = f.read()
    #                 if last_run_datetime:
    #                     self.__last_run_datetime = last_run_datetime
    #         elif self.IS_AWS:
    #             # Since we do not have direct access to modify the last
    #             # run log in AWS we have hard coded the incremental sync
    #             # to back off one day.
    #             tz = pytz.timezone('US/Pacific')
    #             utc_time = datetime.datetime.utcnow()
    #             rollback_datetime = pytz.utc.localize(utc_time, is_dst=None). \
    #                 astimezone(tz) - datetime.timedelta(days=1)
    #             self.__last_run_datetime = \
    #                 rollback_datetime.strftime("%Y-%m-%d %H:%M:%S")
    #         else:
    #             self.__log_message('Cannot use incremental sync. Sync has not '
    #                                'been previously run before. Try '
    #                                'running again with incremental sync '
    #                                'disabled.', logging.ERROR)
    #             return False
    #
    #     with open(fname, 'w+') as f:
    #         tz = pytz.timezone('US/Pacific')
    #         utc_time = datetime.datetime.utcnow()
    #         current_time = pytz.utc.localize(utc_time, is_dst=None). \
    #             astimezone(tz).strftime("%Y-%m-%d %H:%M:%S")
    #         f.write(current_time)
    #
    #     self.__configure_collector_mapping()
    #     return True

    def __configure_incremental_sync(self):
        if self.USE_INCREMENTAL_SYNC:
            tz = pytz.timezone('US/Pacific')
            utc_time = datetime.datetime.utcnow()
            rollback_datetime = pytz.utc.localize(utc_time, is_dst=None). \
                astimezone(tz) - datetime.timedelta(minutes=self.SYNC_SCHEDULE_MINUTES)
            self.__last_run_datetime = \
                rollback_datetime.strftime("%Y-%m-%d %H:%M:%S")
        self.__configure_collector_mapping()
        return True

    def __log_message(self, message, level=logging.INFO):
        message = str(datetime.datetime.now()) + ': ' + message
        self._logger.log(level, message)

    def __get_cmdb_devices(self):
        self.__log_message('Requesting CMDB devices.')

        cmdb_devices = []
        for ci_type in self.CMDB_SYNC_CLASSES:
            self.__log_message('Requesting ServiceNow devices of type ' +
                               ci_type + '...')
            if not self.USE_INCREMENTAL_SYNC:
                response = self.__cmdb_client.get_cis(ci_type,
                                                      self.MAX_CMDB_DEVICES_TO_FETCH, 0,
                                                      True)
            else:
                min_date = self.__last_run_datetime.split(' ')[0]
                min_time = self.__last_run_datetime.split(' ')[1]
                response = self.__cmdb_client.get_cis_date(ci_type, min_date,
                                                           min_time,
                                                           self.MAX_CMDB_DEVICES_TO_FETCH,
                                                           0, True)
            if response is not None and len(response) > 0 and \
                            'result' in response:
                cmdb_devices.extend(response['result'])
                self.__log_message(str(len(response['result'])) + ' ' +
                                   ci_type + '(s) were received.')

        if len(cmdb_devices) > 0:
            self.__log_message('Fetched a total of ' +
                               str(len(cmdb_devices)) + ' CMDB devices')
        else:
            self.__log_message('No CMDB devices fetched.')

        self.__log_message('Completed getting CMDB devices.')
        return cmdb_devices

    def __get_collector_id(self, device_name, ci_type, group, collector_id=None):
        lookup_key = None
        device_name = device_name[:5].lower()
        if device_name + ':' + ci_type + ':' + group in self.__collector_map:
            lookup_key = device_name + ':' + ci_type + ':' + group
        elif device_name + ':' + 'Any' + ':' + group in self.__collector_map:
            lookup_key = device_name + ':' + 'Any' + ':' + group
        elif device_name + ':' + ci_type + ':' + 'Any' in self.__collector_map:
            lookup_key = device_name + ':' + ci_type + ':' + 'Any'
        elif device_name + ':' + 'Any' + ':' + 'Any' in self.__collector_map:
            lookup_key = device_name + ':' + 'Any' + ':' + 'Any'

        if lookup_key is not None:
            collector_names = self.__collector_map[lookup_key]
            sel_collector_name = None
            sel_collector_id = None
            sel_size = sys.maxint
            collector_ids = []
            for collector_name in collector_names:
                collector = self.__collectors[collector_name]
                collector_ids.append(collector[0])
                if collector[1] < sel_size:
                    sel_collector_name = collector_name
                    sel_collector_id = collector[0]
                    sel_size = collector[1]
            if collector_id is not None and collector_id in collector_ids:
                return collector_id
            elif sel_collector_id is not None:
                self.__collectors[sel_collector_name][1] += 1
            return sel_collector_id
        else:
            return None

    def __create_or_update_lm_devices(self, lm_devices):
        if len(lm_devices) is 0:
            self.__log_message('No LogicMonitor devices to create')
            return
        self.__log_message('Creating, updating, and deleting LogicMonitor '
                           'devices.')

        num_cores = multiprocessing.cpu_count()
        self.__log_message('Number of cores: ' + str(num_cores))
        results = Parallel(n_jobs=num_cores)(
            delayed(async_create_lm_device)(lm_device) for
            lm_device in lm_devices)

        type_count = {'Linux Server': 0,
                      'Solaris Server': 0,
                      'Mass Storage Device': 0,
                      'ESX Server': 0}

        for result in results:
            if result[0] is not None:
                if result[0] == 'Failure':
                    self.__log_message(result[1])
                else:
                    type_count[result[0]] += 1
                    self.__log_message(result[1])

        count = 0
        for key, value in type_count.iteritems():
            count += value
            self.__log_message(str(value) + ' ' + key +
                               '(s) were created or updated.')
        self.__log_message('Successfully generated a total of ' + str(count) +
                           ' LogicMonitor devices.')
        self.__log_message('Completed creating, updating, and deleting '
                           'LogicMonitor devices.')

    def __map_cmdb_to_lm_devices(self, cmdb_devices):
        if len(cmdb_devices) is 0:
            self.__log_message('No CMDB devices to map to LogicMonitor '
                               'devices.')
            return []
        self.__log_message('Generating LM devices from CMDB devices.')

        devices_cache = self.__lm_client.get_devices()

        lm_devices = []
        for cmdb_device in cmdb_devices:
            operational_status = cmdb_device[sn_const.SN_OPERATIONAL_STATUS]
            if not (operational_status == 'Decommissioned' or
                            operational_status == 'Operational' or
                            operational_status == 'Maintenance' or
                            operational_status == 'DR Standby' or
                            operational_status == 'Non-Operational' or
                            operational_status == 'Archive'):
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'CMDB device does not have valid operational'
                                   ' status: ' + operational_status)
                continue

            try:
                socket.inet_aton(cmdb_device[sn_const.SN_IP_ADDRESS])
            except socket.error:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'CMDB device does not have valid IP '
                                   'address:' +
                                   cmdb_device[sn_const.SN_IP_ADDRESS])
                continue
            lm_device = {}
            # devices = self.__lm_client.get_device_by_display_name(
            #     cmdb_device[sn_const.SN_NAME].rstrip())
            devices = filter(lambda x: x['displayName'] == cmdb_device[sn_const.SN_NAME].rstrip(), devices_cache)
            if len(devices) == 1:
                if not self.ALLOW_UPDATE:
                    continue
                device = devices[0]
                self.__log_message(
                    'Found existing device in LogicMonitor portal '
                    'with display name: ' +
                    device[lm_const.OBJ_DISPLAY_NAME])
                if operational_status == 'Decommissioned':
                    self.__lm_client.delete_device_by_id(
                        device[lm_const.OBJ_ID])
                    self.__log_message('Operational status is set to '
                                       'Decommissioned. Device is deleted [' +
                                       cmdb_device[sn_const.SN_NAME] + '].')
                    continue
                elif operational_status == 'DR Standby' or \
                                operational_status == 'Archive' or \
                                operational_status == 'Non-Operational':
                    custom_properties = device[lm_const.OBJ_CUSTOM_PROPERTIES]
                    custom_properties = update_custom_property(
                        custom_properties, 'sn.operational_status',
                        operational_status)
                    device[lm_const.OBJ_CUSTOM_PROPERTIES] = custom_properties
                    lm_device = device
                    self.__log_message('Operational status is set to ' +
                                       operational_status +
                                       '. Device will be updated with this '
                                       'status [' +
                                       cmdb_device[sn_const.SN_NAME] + '].')
                else:
                    lm_device = self.__create_direct_properties(cmdb_device,
                                                                device)
                    if lm_device is None:
                        continue
                    custom_properties = self.__create_custom_properties(
                        cmdb_device,
                        device[
                            lm_const.OBJ_CUSTOM_PROPERTIES])
                    if custom_properties is None:
                        continue

                    group_id = self.__get_lm_device_group_id(cmdb_device)
                    if group_id is None:
                        continue
                    lm_device[lm_const.OBJ_HOST_GROUP_IDS] = group_id
                    lm_device[
                        lm_const.OBJ_CUSTOM_PROPERTIES] = custom_properties
                    self.__log_message('Device will be updated [' +
                                       cmdb_device[sn_const.SN_NAME] + '].')
            elif operational_status == 'Decommissioned' or \
                            operational_status == 'Archive' or \
                            operational_status == 'Non-Operational' or \
                            operational_status == 'DR Standby':
                self.__log_message(
                    'Device not created [' + cmdb_device[sn_const.SN_NAME] +
                    ']. Operational status set to ' +
                    operational_status)
                continue
            else:
                lm_device = self.__create_direct_properties(cmdb_device)
                if lm_device is None:
                    continue
                custom_properties = self.__create_custom_properties(cmdb_device)
                if custom_properties is None:
                    continue
                lm_device[lm_const.OBJ_CUSTOM_PROPERTIES] = custom_properties
                group_id = self.__get_lm_device_group_id(cmdb_device)
                if group_id is None:
                    continue
                lm_device[lm_const.OBJ_HOST_GROUP_IDS] = group_id

            if self.USE_MAPPING:
                if sn_const.SN_SUPPORT_GROUP in cmdb_device and \
                        cmdb_device[sn_const.SN_SUPPORT_GROUP][
                            sn_const.SN_DISPLAY_VALUE]:
                    group = cmdb_device[sn_const.SN_SUPPORT_GROUP][
                        sn_const.SN_DISPLAY_VALUE]
                else:
                    group = ''
                if lm_const.OBJ_COLLECTOR_ID in lm_device:
                    existing_id = lm_device[lm_const.OBJ_COLLECTOR_ID]
                else:
                    existing_id = None
                preferred_collector_id = self.__get_collector_id(
                    lm_device[lm_const.OBJ_DISPLAY_NAME], cmdb_device[
                        sn_const.SN_CLASS_NAME], group, existing_id)
                if preferred_collector_id is None:
                    self.__log_message('Device not created [' +
                                       cmdb_device[sn_const.SN_NAME] + ']. '
                                       'Could not find a collector mapping for'
                                       ' LogicMonitor device.')
                    continue
            else:
                preferred_collector_id = self.COLLECTOR_MAPPING_ID

            custom_properties = lm_device[lm_const.OBJ_CUSTOM_PROPERTIES]
            custom_properties = update_custom_property(custom_properties,
                                                              'sn.ci_def',
                                                              self.CLASS_NAME_MAP[cmdb_device[sn_const.SN_CLASS_NAME]] + '__' +
                                                              lm_device[lm_const.OBJ_DISPLAY_NAME])
            lm_device[lm_const.OBJ_CUSTOM_PROPERTIES] = custom_properties
            lm_device[lm_const.OBJ_COLLECTOR_ID] = preferred_collector_id
            lm_device = self.__check_if_disable_alerting(lm_device)
            if lm_device is not None:
                self.__log_message('Added device for creation [' +
                                   cmdb_device[sn_const.SN_NAME] + '].')
                lm_devices.append(lm_device)

        self.__log_message('Successfully mapped a total of ' +
                           str(len(lm_devices)) + ' CMDB devices to LM devices')
        self.__log_message('Completed generating LM devices from CMDB devices.')
        return lm_devices

    def __check_if_disable_alerting(self, lm_device):
        operational_status = get_custom_property_value(lm_device,
                                                              'sn.operational_status')
        if operational_status == 'Maintenance':
            lm_device['disableAlerting'] = True
        else:
            lm_device['disableAlerting'] = False
        return lm_device

    def __create_direct_properties(self, cmdb_device, device=None):
        if device is None:
            device = {}
        for prop in self.DIRECT_PROPERTIES:
            cmdb_prop_name = prop[0]
            lm_prop_name = prop[1]
            required = prop[2]
            if required and not cmdb_device[cmdb_prop_name]:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                                                   'CMDB device is missing '
                                                                   'property: ' + cmdb_prop_name)
                return None
            else:
                if cmdb_prop_name not in cmdb_device:
                    continue
                elif type(cmdb_device[cmdb_prop_name]) is not dict:
                    value = cmdb_device[cmdb_prop_name]
                    if value is None:
                        value = ''
                    device[lm_prop_name] = value
                elif sn_const.SN_DISPLAY_VALUE in cmdb_device[cmdb_prop_name]:
                    value = cmdb_device[cmdb_prop_name][
                        sn_const.SN_DISPLAY_VALUE]
                    if value is None:
                        value = ''
                    device[lm_prop_name] = value
        return device

    def __create_custom_properties(self, cmdb_device, custom_properties=None):
        if custom_properties is None:
            custom_properties = []
        for prop in self.CUSTOM_PROPERTIES:
            cmdb_prop_name = prop[0]
            lm_prop_name = prop[1]
            required = prop[2]
            if required and (cmdb_prop_name not in cmdb_device or not
                cmdb_device[cmdb_prop_name]):
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'CMDB device is missing '
                                   'property: ' + cmdb_prop_name)
                return None
            else:
                if cmdb_prop_name not in cmdb_device:
                    continue
                elif cmdb_prop_name in cmdb_device and \
                                type(cmdb_device[cmdb_prop_name]) is not dict:
                    value = cmdb_device[cmdb_prop_name]
                    if value is None:
                        value = ''
                    custom_properties = \
                        update_custom_property(custom_properties,
                                                      lm_prop_name, value)
                elif sn_const.SN_DISPLAY_VALUE in cmdb_device[cmdb_prop_name]:
                    value = cmdb_device[cmdb_prop_name][
                        sn_const.SN_DISPLAY_VALUE]
                    if value is None:
                        value = ''
                    custom_properties = \
                        update_custom_property(custom_properties,
                                                      lm_prop_name, value)
        return custom_properties

    def __get_lm_device_group_id(self, cmdb_device):
        class_mapping = {'Linux Server': 'Linux',
                         'Solaris Server': 'Solaris',
                         'Mass Storage Device': 'Storage',
                         'ESX Server': 'VMware'}

        tier_mapping = ['Tier 1', 'Tier 2', 'Tier 3']

        env_mapping = ['Production', 'Development', 'Staging', 'QA', 'Lab']

        storage_vendors = ['Brocade', 'CleverSafe', 'NetApp',
                           'Pure Storage', 'Tintri']

        env_mapping_storage = ['Production', 'Development', 'Staging',
                               'Disaster Recovery']

        esx_mapping = {'Ent': 'ECS',
                       'EIS': 'EIS'}

        ecs_locations = ['China Shanghai Pudong', 'Singapore',
                         'US Carlstadt NJ', 'US East', 'US Santa Clara',
                         'US West']

        eis_locations = ['Canada Toronto', 'China Shanghai Pudong',
                         'Switzerland Neuchatel', 'US Carlstadt NJ',
                         'US Santa Clara']

        if 'ESX Server' == cmdb_device[sn_const.SN_CLASS_NAME]:
            path = '/VMware/'
            if sn_const.SN_SUPPORT_GROUP in cmdb_device and \
                    cmdb_device[sn_const.SN_SUPPORT_GROUP][
                    sn_const.SN_DISPLAY_VALUE][:3] in esx_mapping:
                esx_type = esx_mapping[cmdb_device[sn_const.SN_SUPPORT_GROUP]
                                    [sn_const.SN_DISPLAY_VALUE][:3]]
                path += esx_type
            else:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'Invalid support group '
                                   'specified for CMDB device.')
                return None

            if esx_type == 'ECS':
                if len(cmdb_device[sn_const.SN_LOCATION]) > 0 and \
                        cmdb_device[sn_const.SN_LOCATION][
                        sn_const.SN_DISPLAY_VALUE] in ecs_locations:
                    path += '/' + cmdb_device[sn_const.SN_LOCATION][
                        sn_const.SN_DISPLAY_VALUE]
                else:
                    self.__log_message('Device not created [' +
                                       cmdb_device[sn_const.SN_NAME] + ']. '
                                       'Invalid location '
                                       'specified for CMDB device.')
                    return None
            elif esx_type == 'EIS':
                if len(cmdb_device[sn_const.SN_LOCATION]) > 0 and \
                        cmdb_device[sn_const.SN_LOCATION][
                        sn_const.SN_DISPLAY_VALUE] in eis_locations:
                    path += '/' + cmdb_device[sn_const.SN_LOCATION][
                        sn_const.SN_DISPLAY_VALUE]
                else:
                    self.__log_message('Device not created [' +
                                       cmdb_device[sn_const.SN_NAME] + ']. '
                                       'Invalid location '
                                       'specified for CMDB device.')
                    return None
        elif 'Mass Storage Device' == cmdb_device[sn_const.SN_CLASS_NAME]:
            path = '/' + class_mapping[cmdb_device[sn_const.SN_CLASS_NAME]]
            if sn_const.SN_MANUFACTURER in cmdb_device and \
                            cmdb_device[sn_const.SN_MANUFACTURER][
                                sn_const.SN_DISPLAY_VALUE] in storage_vendors:
                path += '/' + cmdb_device[sn_const.SN_MANUFACTURER][
                    sn_const.SN_DISPLAY_VALUE]
            else:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'Invalid storage vendor '
                                   'specified for CMDB device.')
                return None
            if cmdb_device[sn_const.SN_ENVIRONMENT] in env_mapping_storage:
                path += '/' + cmdb_device[sn_const.SN_ENVIRONMENT]
            else:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'Invalid environment '
                                   'specified for CMDB device.')
                return None
        else:
            if sn_const.SN_OS in cmdb_device and \
                            cmdb_device[sn_const.SN_OS] is not None and \
                            'cluster' in cmdb_device[sn_const.SN_OS].lower():
                path = '/Linux Cluster'
            else:
                path = '/' + class_mapping[cmdb_device[sn_const.SN_CLASS_NAME]]

            if cmdb_device[sn_const.SN_SUPPORT_TIER] in tier_mapping:
                path += '/' + cmdb_device[sn_const.SN_SUPPORT_TIER]
            else:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'Invalid tier specified for CMDB device.')
                return None
            if cmdb_device[sn_const.SN_ENVIRONMENT] in env_mapping:
                path += '/' + cmdb_device[sn_const.SN_ENVIRONMENT]
            else:
                self.__log_message('Device not created [' +
                                   cmdb_device[sn_const.SN_NAME] + ']. '
                                   'Invalid environment '
                                   'specified for CMDB device.')
                return None

        if path not in self.GROUP_CACHE:
            groups = self.__lm_client.create_group_by_full_path(lm_const.TAB_DEVICE,
                                                                path)
            self.GROUP_CACHE[path] = groups[0]['id']
            group_id = groups[0]['id']
        else:
            group_id = self.GROUP_CACHE[path]
        return group_id

    def execute(self):
        try:
            success = self.__configure_incremental_sync()
            if success:
                self.__log_message(
                    'ServiceNow CMDB and LogicMonitor Portal sync started.')

                cmdb_devices = self.__get_cmdb_devices()
                if len(cmdb_devices) > 0:
                    lm_devices = self.__map_cmdb_to_lm_devices(cmdb_devices)
                    self.__create_or_update_lm_devices(lm_devices)

                self.__log_message(
                    'ServiceNow CMDB and LogicMonitor Portal sync completed.')
        except Exception, e:
            self.__log_message('Exception: ' + str(e) + ' Message: ' +
                               e.message + ' Stack: ' +
                               str(traceback.format_exc()), logging.ERROR)


def update_custom_property(custom_properties, property_name, property_value):
    for custom_property in custom_properties:
        if custom_property[lm_const.OBJ_NAME] == property_name:
            custom_property[lm_const.OBJ_VALUE] = property_value
            return custom_properties
    custom_properties.append({lm_const.OBJ_NAME: property_name,
                              lm_const.OBJ_VALUE: property_value})
    return custom_properties


def get_custom_property_value(lm_device, property_name):
    custom_properties = lm_device[lm_const.OBJ_CUSTOM_PROPERTIES]
    for custom_property in custom_properties:
        if custom_property[lm_const.OBJ_NAME] == property_name:
            return custom_property[lm_const.OBJ_VALUE]
    return None


def async_create_lm_device(lm_device):
    logger = logging.getLogger('parrallel_logger')
    logger.setLevel(logging.INFO)
    log_capture_string = StringBuffer()
    string_handler = logging.StreamHandler(log_capture_string)
    logger.addHandler(string_handler)

    lm_client = LogicMonitor(CmdbSync.LM_PORTAL, CmdbSync.LM_ID,
                             CmdbSync.LM_KEY, CmdbSync.LM_AUTH, logger)

    lm_device[lm_const.OBJ_CUSTOM_PROPERTIES]
    class_type = get_custom_property_value(lm_device, 'sn.sys_class_name')
    if lm_const.OBJ_ID not in lm_device:
        response = lm_client.create_device(lm_device)
        if response is not None and len(response) > 0:
            return [class_type, 'Created device in LogicMonitor with name: ' +
                    response[0][lm_const.OBJ_DISPLAY_NAME]]
        else:
            log_contents = log_capture_string.getvalue()
            log_capture_string.close()
            return ['Failure', log_contents]
    else:
        response = lm_client.update_device(lm_device)
        if response is not None and len(response) > 0:
            return [class_type, 'Updated device in LogicMonitor with name: ' +
                    response[0][lm_const.OBJ_DISPLAY_NAME]]
        else:
            log_contents = log_capture_string.getvalue()
            log_capture_string.close()
            return ['Failure', log_contents]


def lambda_handler(event, context):
    main()


def main():
    cmdb_sync = CmdbSync()
    cmdb_sync.execute()


main()
