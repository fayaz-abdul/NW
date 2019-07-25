terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }

  dependencies {
    paths = ["../vpc", "../domain"]
  }
}

subnet_cidr_blocks = [
  "10.0.1.0/27",
  "10.0.1.32/27"
]

role = "network"
application = "backend"

network_acls = [
  {
    "Egress" = "true",
    "Protocol" = "-1",
    "RuleNumber" = 100,
    "CidrBlock" = "172.22.72.0/23",
    "RuleAction" = "allow"
  },
  {
    "Egress"= "true",
    "Protocol"= "-1",
    "RuleNumber"= 110,
    "CidrBlock"= "172.16.0.0/12",
    "RuleAction"= "allow"
  },
  {
    "Egress"= "true",
    "Protocol"= "-1",
    "RuleNumber"= 120,
    "CidrBlock"= "10.128.0.0/12",
    "RuleAction"= "allow"
  },
  {
    "Egress"= "true",
    "Protocol"= "-1",
    "RuleNumber"= 2000,
    "CidrBlock"= "10.100.0.0/16",
    "RuleAction"= "allow"
  },
  {
    "Egress"= "true",
    "Protocol"= "-1",
    "RuleNumber"= 32766,
    "CidrBlock"= "0.0.0.0/0",
    "RuleAction"= "deny"
  },
  {
    "Egress"= "false",
    "Protocol"= "-1",
    "RuleNumber"= 100,
    "CidrBlock"= "172.22.72.0/23",
    "RuleAction"= "allow"
  },
  {
    "Egress"= "false",
    "Protocol"= "-1",
    "RuleNumber"= 110,
    "CidrBlock"= "172.16.0.0/12",
    "RuleAction"= "allow"
  },
  {
    "Egress"= "false",
    "Protocol"= "-1",
    "RuleNumber"= 120,
    "CidrBlock"= "10.128.0.0/12",
    "RuleAction"= "allow"
  },  
  {
    "Egress"= "false",
    "Protocol"= "-1",
    "RuleNumber"= 2000,
    "CidrBlock"= "10.100.0.0/16",
    "RuleAction"= "allow"
  },
  {
    "Egress"= "false",
    "Protocol"= "-1",
    "RuleNumber"= 32766,
    "CidrBlock"= "0.0.0.0/0",
    "RuleAction"= "deny"
  }
]


network_acls_port = [
  {
    "Egress"= "false",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1200,
    "Protocol"= "udp",      
    "From"= "123",
    "To"= "123"      
  },
  {
    "Egress"= "false",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1100,
    "Protocol"= "udp",      
    "From"= 32768,
    "To"= 65535      
  },
  {
    "Egress"= "false",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1000,
    "Protocol"= "tcp",      
    "From"= 32768,
    "To"= 65535    
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1000,
    "Protocol"= "tcp",
    "From"= 80,
    "To"= 80
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1100,
    "Protocol"= "tcp",
    "From"= 443,
    "To"= 443
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1200,
    "Protocol"= "udp",
    "From"= 123,
    "To"= 123
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1300,
    "Protocol"= "tcp",
    "From"= 22,
    "To"= 22      
  },  
]
