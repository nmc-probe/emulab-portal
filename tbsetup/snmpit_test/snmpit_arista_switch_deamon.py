#!/usr/bin/python

#
# EMULAB-LGPL
# Copyright (c) 2012 University of Utah and the Flux Group.
# All rights reserved.
#

#
# Deamon server running on Arista switch side for snmpit_arista.
#

import PyClient
import Tac
import EntityManager
import SimpleXMLRPCServer

#
# The Arista Python library uses exceptions to handle errors,
# so it doesn't work if we just depend on return values.
#

def initSession():
    pc = PyClient.PyClient("ar", "Sysdb")
    sysdb = pc.agentRoot()
    return sysdb

def getBridgingConfig(sysdb):
    return sysdb['bridging']['input']['config']['cli']

def createVlan(sysdb, vlan_num, vlan_id):
    bc = getBridgingConfig(sysdb)
    nv = bc.vlanConfig.newMember(vlan_num)
    nv.name = vlan_id

def vlanExist(sysdb, vlan_num):
    bc = getBridgingConfig(sysdb)
    rt = bc.vlanConfig.get(vlan_num)
    if rt:
        return True
    else:
        return False

def removeVlan(sysdb, vlan_num):
    bc = getBridgingConfig(sysdb)
    if vlanExists(sysdb, vlan_num):
        del bc.vlanConfig[vlan_num]
    return True
    
def putPortInVlan(sysdb, vlan_num, port):
    bc = getBridgingConfig(sysdb)
    pbc = bc.switchIntfConfig.newMember(port)
    pbc.switchportMode = 'access'
    pbc.enabled = True
    pbc.accessVlan = int(vlan_num)
    return True

def delPortFromVlan(sysdb, vlan_num, port):
    bc = getBridgingConfig(sysdb)
    pbc = bc.switchIntrConfig[port]
    pbc.accessVlan = 0
    return True

def tagPort(sysdb, tags, native_vlan, port):
    bc = getBridgingConfig(sysdb)
    pbc = bc.switchIntfConfig.newMember(port)
    pbc.switchportMode = 'trunk'
    pbc.enabled = True
    pbc.trunkAllowedVlans = tags
    pbc.trunkNativeVlan = int(native_vlan)
   
def initRPCServer(bind_addr, port, funcs):
    s = SimpleXMLRPCServer.SimplerXMLRPCServer((bind_addr, port))
    for f in funcs:
        s.register_function(f[0], f[1])
    return s

#
# XML-RPC method functions
#

def createVlan(vlan_id, vlan_num):
    pass

def removeVlan(vlan_num):
    pass

def setPortsVlan(vlan_num, ports):
    pass

def removePortsFromVlan(vlan_num, ports):
    pass

def vlanExist(vlan_num):
    pass

def setVlanPortTag(vlan_num, tag, ports):
    pass

def getVlanPorts(vlan_num):
    pass

def getPortVlan(port):
    pass

def getAllVlans():
    pass

#
# Exported methods list
#
funcs = [(createVlan, "createVlan"),
         (removeVlan, "removeVlan"),
         (setPortsVlan, "setPortsVlan"),
         (removePortsFromVlan, "removePortsFromVlan"),
         (vlanExist, "vlanExist"),
         (setVlanPortTag, "setVlanPortTag"),
         (getVlanPorts, "getVlanPorts"),
         (getPortVlan, "getPortVlan"),
         (getAllVlans, "getAllVlans")
         ]

s = initRPCServer('localhost', 8001, funcs)
s.serve_forever()
