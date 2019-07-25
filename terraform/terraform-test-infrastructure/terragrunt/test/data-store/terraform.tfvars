terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }

  dependencies {
    paths = ["../vpc", "../network-dmz"]
  }
}

subnet_cidr_blocks = [
  "10.0.0.128/27",
  "10.0.0.160/27"
]

role = "store"
application = "data"
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
    "RuleNumber"= 1400,
    "Protocol"= "udp",
    "From"= 3544,
    "To"= 3544
  },
]

  }
}

role            = "data"
application     = "store"
