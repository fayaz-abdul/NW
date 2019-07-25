#!/usr/bin/env python

import urllib2
import base64
import json
import sys
import argparse
import re

parser = argparse.ArgumentParser(description="Get the Cluster Service Status from Ambari")
parser.add_argument("-u", dest="user", type=str, required=True,
            help="The Ambari Username")
parser.add_argument("-a", dest="password", type=str, required=True,
            help="The Ambari Password")
parser.add_argument("-p",  dest="protocol", type=str, required=True,
            help="The Ambari IP Protocol")
parser.add_argument("-s",  dest="server", type=str, required=True,
            help="The Ambari server Address")
parser.add_argument("-d",  dest="port", type=str, required=True,
            help="The Ambari Port")
parser.add_argument("-c",  dest="cluster", type=str, required=True,
            help="The Ambari Cluster Name")
args = parser.parse_args()
user = args.user
password = args.password
protocol = args.protocol
server = args.server
port = args.port
cluster = args.cluster

url = protocol + "://" + server + ":" + port + "/api/v1/clusters/" + cluster + "/host_components?HostRoles/stale_configs=true&fields=HostRoles/service_name,HostRoles/state,HostRoles/host_name,HostRoles/stale_configs,&minimal_response=true"

posturl = protocol + "://"+ server + ":" + port +"/api/v1/clusters/" + cluster + "/requests"

filterkeys = lambda x, y: dict([ (i,x[i]) for i in x if i in set(y) ])

postreq = {"RequestInfo":{"command":"RESTART","context":"Restart Service","operation_level":{"level":"HOST","cluster_name":cluster}},"Requests/resource_filters":"hostdata"}

def getstatus(url,user,password):
    try:
        global status
        req = urllib2.Request(url)
        base64str = base64.b64encode('%s:%s' % (user, password))
        req.add_header("Authorization", "Basic %s" % base64str)
        req.add_header("X-Requested-By", "%s" % user)
        response = urllib2.urlopen(req)
        status = json.load(response)
        if not status["items"]:
            print ("[-] - No Services need Restarting")
            sys.exit()
        else:
            print ("[*] - Services are being Restarted:")
            return status

    except urllib2.HTTPError as e:
        print ("HTTP Reponse:"),e.code
        print e.read()

def filterstatus(jstatus):
    global restartlist
    restartlist = []
    for jkey, jvalue in jstatus.iteritems():
        for i in range(len(jvalue)):
             try:
                 hostroles = jstatus["items"][i]["HostRoles"]
                 wantedkeys = ["component_name","host_name","service_name"]
                 keys = dict((x,'') for x in wantedkeys)
                 filterout = filterkeys(hostroles, keys)
                 filterout['hosts'] = filterout.pop('host_name')
                 restartlist.append(filterout)
             except IndexError:
                 break

def appendpost(servlist):
    postreq["Requests/resource_filters"] = servlist
    return postreq

def postrestart(url,user,password,pdict):
    try:
        jsondata = json.dumps(pdict)
        req = urllib2.Request(url)
        base64str = base64.b64encode('%s:%s' % (user, password))
        req.add_header("Authorization", "Basic %s" % base64str)
        req.add_header("X-Requested-By", "%s" % user)
        response = urllib2.urlopen(req, jsondata)
        status = json.load(response)
    except urllib2.HTTPError as e:
        print ("HTTP Reponse:"),e.code
        print e.read()

getstatus(url,user,password)
filterstatus(status)
appendpost(restartlist)
postrestart(posturl,user,password,postreq)
