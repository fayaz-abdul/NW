import base64
import hashlib
import hmac
import json
import time
import datetime
import logging
import requests

import const


class LogicMonitor(object):
    #####################################################
    #                  REST CLIENT                      #
    #####################################################

    def __init__(self, portal, identity, key, auth_type, logger=None):
        """
        Constructor for LM REST API client
        :param portal: portal
        :param identity: username or token ID
        :param key: password or token key
        :param auth_type: authentication type (token or key)
        """
        self.portal = portal
        self._identity = identity
        self._key = key
        self._auth_type = auth_type
        if logger is None:
            self._logger = logging.getLogger()
        else:
            self._logger = logger

    def rest(self, method, url, data=''):
        """
        Method for requesting from REST API
        :param method: request method (e.g. POST, GET, PUT, DELETE)
        :param url: url for request
        :param data: payload for request
        :return: json response from request
        """
        response = None
        if self._auth_type == const.AUTH_TYPE_TOKEN:
            resource_path = self.__create_resource_path(url)
            headers = self.__create_token_header(resource_path, method, data)
            if method == const.HTTP_VERB_POST:
                response = requests.post(url, data=data, headers=headers)
            elif method == const.HTTP_VERB_GET:
                response = requests.get(url, data=data, headers=headers)
            elif method == const.HTTP_VERB_PUT:
                response = requests.put(url, data=data, headers=headers)
            elif method == const.HTTP_VERB_DELETE:
                response = requests.delete(url, data=data, headers=headers)
        elif self._auth_type == const.AUTH_TYPE_BASIC:
            if method == const.HTTP_VERB_POST:
                response = requests.post(url, data=data,
                                         auth=(self._identity, self._key))
            elif method == const.HTTP_VERB_GET:
                response = requests.get(url, data=data,
                                        auth=(self._identity, self._key))
            elif method == const.HTTP_VERB_PUT:
                response = requests.put(url, data=data,
                                        auth=(self._identity, self._key))
            elif method == const.HTTP_VERB_DELETE:
                response = requests.delete(url, data=data,
                                           auth=(self._identity, self._key))
        return response.json()

    def __create_resource_path(self, url):
        """
        Extracts LM resource path from url
        :param url: full url
        :return: resource path from full url
        """
        position = url.find('/santaba/rest/') + 13
        resource_path = url[position:]
        if '?' in resource_path:
            resource_path = resource_path[:resource_path.find('?')]
        return resource_path

    def __create_token_header(self, resource_path, http_verb, data):
        """
        Creates header for the token authentication type
        :param resource_path: REST resource path
        :param http_verb: Method
        :param data: payload
        :return: header
        """
        epoch = str(int(time.time() * 1000))
        request_vars = http_verb + epoch + data + resource_path
        signature = base64.b64encode(hmac.new(self._key, msg=request_vars,
                                              digestmod=hashlib.sha256).hexdigest())
        auth = 'LMv1 ' + self._identity + ':' + signature + ':' + epoch
        headers = {'Content-Type': 'application/json', 'Authorization': auth}
        return headers

    def __extract_objects_from_json(self, json_response):
        """
        Converts json string to array of objects
        :param json_response: json string
        :return: array of objects
        """
        if json_response[const.OBJ_STATUS] is 200:
            data = json_response[const.OBJ_DATA]
            if const.OBJ_ITEMS not in data:
                return [data]
            else:
                return data[const.OBJ_ITEMS]
        error_text = 'Error: ' + str(json_response[const.OBJ_STATUS]) + ' ' + \
                        json_response[const.OBJ_ERROR_MESSAGE]
        self._logger.log(logging.ERROR, error_text)
        print error_text
        return None

    #####################################################
    #                      GET                          #
    #####################################################

    def get_group_by_path(self, tab, path):
        """
        Generic way to get a group
        :param tab: tab where the group exists (const.TAB_SERVICE, etc)
        :param path: full path of group
        :return: list with the group object with specified path
        """
        item = const.ITEM_GROUPS
        url = (const.LM_REST_URL + const.LM_REST_FILTER_FULLPATH).format(
            self.portal, tab, item, path)
        json_response = self.rest(const.HTTP_VERB_GET, url)
        return self.__extract_objects_from_json(json_response)

    def get_device(self, name):
        """
        Gets a device by name
        :param name: name of device
        :return: device object
        """
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = (const.LM_REST_URL + const.LM_REST_FILTER_NAME).format(
            self.portal, tab, item, name)
        json_response = self.rest(const.HTTP_VERB_GET, url)
        return self.__extract_objects_from_json(json_response)

    def get_devices(self):
        """
        Generic way to get all groups.
        :param tab: tab where the group exists (const.TAB_SERVICE,
        const.TAB_DEVICE, etc...)
        :return: list with all group objects
        """
        groups = []
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = const.LM_REST_URL.format(self.portal, tab, item) + '?size=300'
        response = self.rest(const.HTTP_VERB_GET, url)
        groups.extend(response[const.OBJ_DATA][const.OBJ_ITEMS])
        total = response[const.OBJ_DATA]['total']
        for x in range(1, (total / 300) + 1):
            url = const.LM_REST_URL.format(self.portal, tab, item) \
                  + '?size=300&offset={0}'.format(str(x * 300))
            response = self.rest(const.HTTP_VERB_GET, url)
            groups.extend(response[const.OBJ_DATA][const.OBJ_ITEMS])
        return groups

    def get_device_by_display_name(self, display_name):
        """
        Gets a device by display name
        :param display_name: display name of device
        :return: device object
        """
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = (const.LM_REST_URL + const.LM_REST_FILTER_DISPLAYNAME).format(
            self.portal, tab, item, display_name)
        json_response = self.rest(const.HTTP_VERB_GET, url)
        return self.__extract_objects_from_json(json_response)

    def get_collectors(self):
        """
        Gets all the collectors in the customer portal
        :return: list of collectors
        """
        tab = const.TAB_SETTING
        item = const.ITEM_COLLECTOR
        url = const.LM_REST_URL.format(self.portal, tab, item)
        json_response = self.rest(const.HTTP_VERB_GET, url)
        return self.__extract_objects_from_json(json_response)

    #####################################################
    #                    CREATE                         #
    #####################################################

    def create_group(self, tab, name, description='', parent_id=1):
        """
        Generic way to create a group
        :param tab: tab where the group exists (const.TAB_SERVICE,
        const.TAB_DEVICE, etc...)
        :param name: name of group to be created
        :param description: description of group
        :param parent_id: ID for the parent group
        :return: list with the group object
        """
        item = const.ITEM_GROUPS
        data = {'name': name,
                'description': description,
                'parentId': parent_id}
        json_data = json.dumps(data, ensure_ascii=True)
        url = const.LM_REST_URL.format(self.portal, tab, item)
        json_response = self.rest(const.HTTP_VERB_POST, url, json_data)
        return self.__extract_objects_from_json(json_response)

    def create_group_by_full_path(self, tab, full_path):
        """
        Generic way to create groups by a specified path.
        :param tab: tab where the group exists (const.TAB_SERVICE,
        const.TAB_DEVICE, etc...)
        :param full_path: name of group to be created
        :return: list with the group object
        """
        groups = full_path.split('/')
        for index in range(0, len(groups)):
            path = ''
            for i in range(0, index + 1):
                if i < 2:
                    path += groups[i]
                else:
                    path += '/' + groups[i]
            group_obj = self.get_group_by_path(tab, path)
            if len(group_obj) == 0:
                group_obj = self.create_group(tab, groups[index], parent_id=parent_id)
            parent_id = group_obj[0]['id']

        return group_obj

    def create_device(self, host_name, display_name, preferred_collector_id,
                      host_group_ids=[], custom_properties=[]):
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = const.LM_REST_URL.format(self.portal, tab, item)
        data = {'name': host_name,
                'displayName': display_name,
                'preferredCollectorId': preferred_collector_id,
                'customProperties': custom_properties,
                'description': '',
                'disableAlerting': False,
                'enableNetflow': False,
                'hostGroupIds': ','.join(str(x) for x in host_group_ids),
                'link': '',
                'netflowCollectorId': ''}
        json_data = json.dumps(data, ensure_ascii=True)
        json_response = self.rest(const.HTTP_VERB_POST, url, json_data)
        return self.__extract_objects_from_json(json_response)

    def create_device(self, device):
        """
        Creates the device in portal
        :param device: device object to be created
        :return: result
        """
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = const.LM_REST_URL.format(self.portal, tab, item)
        json_data = json.dumps(device, ensure_ascii=True)
        json_response = self.rest(const.HTTP_VERB_POST, url, json_data)
        return self.__extract_objects_from_json(json_response)

    #####################################################
    #                    DELETE                         #
    #####################################################

    def delete_device_by_id(self, device_id):
        """
        Generic way to delete a device.
        :param device_id: ID of device to be deleted
        :return: json response
        """
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = const.LM_REST_URL_ID.format(self.portal, tab, item, device_id)
        json_response = self.rest(const.HTTP_VERB_DELETE, url)
        return json_response

    #####################################################
    #                    UTILITY                        #
    #####################################################

    def __unix_time_millis(self, dt):
        """
        Converts datetime object to epoch time
        :param dt: datetime
        :return: epoch time
        """
        epoch = datetime.datetime.utcfromtimestamp(0)
        return (dt - epoch).total_seconds() * 1000.0

    #####################################################
    #                    UPDATE                         #
    #####################################################

    def update_device(self, device):
        """
        Updates a device with new information. Any missing fields
        will be overridden as blank.
        :param device: Dictionary describing a device
        :return: Updated device object
        """
        tab = const.TAB_DEVICE
        item = const.ITEM_DEVICES
        url = const.LM_REST_URL_ID.format(self.portal, tab, item,
                                          device[const.OBJ_ID])
        data = device
        json_data = json.dumps(data, ensure_ascii=True)

        json_response = self.rest(const.HTTP_VERB_PUT, url, json_data)
        return self.__extract_objects_from_json(json_response)
