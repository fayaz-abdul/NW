#!/usr/bin/env python

import json
import sys
import argparse
import requests
import os

def addUser(args):
    url = "https://"+args.host+":"+args.port+"/api/v1/users"
    resp= json.loads(requests.get(url, auth=(args.admin, args.adminpwd), verify=False).text)
    existing_users = [user['Users']['user_name'] for user in resp['items']]
    headers = {'X-Requested-By': 'ambari'}
    if args.user not in existing_users:
        payload = json.dumps({"Users":{"user_name":args.user, "password": args.userpwd, "active": True, "admin": False}})
        requests.post(url, auth=(args.admin, args.adminpwd), verify=False, headers=headers, json=payload)
        url = "https://"+args.host+":"+args.port+"/api/v1"
        url = os.path.join(url, "clusters", args.cluster, "privileges")
        payload = json.dumps({"PrivilegeInfo":{"cluster_name":args.cluster,"permission_name":"CLUSTER.READ","principal_name":args.user,"principal_type":"USER"}})
        requests.post(url, auth=(args.admin, args.adminpwd), verify=False, headers=headers, json=payload)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Get the Cluster Service Status from Ambari")
    parser.add_argument("-a", dest="admin", type=str, required=True,
                help="Ambari admin")
    parser.add_argument("-b", dest="adminpwd", type=str, required=True,
                help="Ambari admin password")
    parser.add_argument("-s",  dest="host", type=str, required=True,
                help="Ambari server address")
    parser.add_argument("-t",  dest="port", type=str, required=True,
                help="Ambari port")
    parser.add_argument("-c",  dest="cluster", type=str, required=True,
                help="Ambari cluster")
    parser.add_argument("-u",  dest="user", type=str, required=True,
                help="Ambari user")
    parser.add_argument("-p",  dest="userpwd", type=str, required=True,
                help="Ambari user password")

    args = parser.parse_args()
    addUser(args)
    sys.exit(0)
