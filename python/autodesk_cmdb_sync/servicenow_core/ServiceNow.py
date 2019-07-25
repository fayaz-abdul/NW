import requests

from servicenow_core import const


class ServiceNow(object):
    #####################################################
    #                  REST CLIENT                      #
    #####################################################

    def __init__(self, instance, identity, key):
        """
        Constructor for the ServiceNow REST API client
        :param instance: ServiceNow instance name
        :param identity: username
        :param key: password
        """
        self._instance = instance
        self._identity = identity
        self._key = key

    def rest(self, method, url, data=''):
        """
        Method for requesting from REST API
        :param method: request method (e.g. POST, GET, PUT, DELETE)
        :param url: url for request
        :param data: payload for request
        :return: json response from request
        """
        headers = {'Accept': 'application/json'}
        response = None
        if method == const.HTTP_VERB_POST:
            response = requests.post(url, data=data,
                                     auth=(self._identity, self._key),
                                     headers=headers)
        elif method == const.HTTP_VERB_GET:
            response = requests.get(url, data=data,
                                    auth=(self._identity, self._key),
                                    headers=headers)
        elif method == const.HTTP_VERB_PUT:
            response = requests.put(url, data=data,
                                    auth=(self._identity, self._key),
                                    headers=headers)
        elif method == const.HTTP_VERB_DELETE:
            response = requests.delete(url, data=data,
                                       auth=(self._identity, self._key),
                                       headers=headers)
        return response.json()

    def get_cis(self, ci_type, limit=10000, offset=0, display_value=True):
        """
        Gets ServiceNow CI's
        :param ci_type: CI class type
        :param limit: max amount of CI's to return
        :param offset: offset to shift request if results is greater than limit
        :param display_value: whether to return display values
        :return:
        """
        url = const.SN_REST_URL.format(self._instance, ci_type) + '?' + \
              const.SN_REST_LIMIT.format(limit) + '&' + \
              const.SN_REST_OFFSET.format(offset) + '&' + \
              const.SN_REST_DISPLAY_VALUE.format(display_value) + '&' + \
              const.SN_REST_QUERY
        response = self.rest(const.HTTP_VERB_GET, url)
        return response

    def get_cis_date(self, ci_type, min_date, min_time, limit=10000, offset=0,
                     display_value=True):
        """
        Gets ServiceNow CI's that have been modified after min date and time
        :param ci_type: CI class type
        :param min_date: minimum date
        :param min_time: minimum time
        :param limit: max amount of CI's to return
        :param offset: offset to shift request if results is greater than limit
        :param display_value: whether to return display values
        :return:
        """
        url = const.SN_REST_URL.format(self._instance, ci_type) + '?' + \
              const.SN_REST_LIMIT.format(limit) + '&' + \
              const.SN_REST_OFFSET.format(offset) + '&' + \
              const.SN_REST_DISPLAY_VALUE.format(display_value) + '&' + \
              const.SN_REST_QUERY_DATE.format(min_date, min_time)
        response = self.rest(const.HTTP_VERB_GET, url)
        return response
