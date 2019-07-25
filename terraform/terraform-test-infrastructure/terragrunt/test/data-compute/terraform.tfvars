terragrunt = {
  include {
    path = "${find_in_parent_folders("common.tfvars")}"
  }

  dependencies {
    paths = ["../vpc", "../domain"]
  }
}

subnet_cidr_blocks = [
  "10.0.0.64/27",
  "10.0.0.96/27"
]

role = "data"
application = "compute"


network_acls = [  
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
    "RuleNumber"= 1300,
    "Protocol"= "tcp",
    "From"= 22,
    "To"= 22      
  },
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
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1400,
    "Protocol"= "tcp",
    "From"= 15022,
    "To"= 15022      
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1600,
    "Protocol"= "tcp",
    "From"= 9243,
    "To"= 9243      
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1700,
    "Protocol"= "tcp",
    "From"= 21,
    "To"= 21      
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1800,
    "Protocol"= "tcp",
    "From"= 61613,
    "To"= 61613      
  },
  {
    "Egress"= "true",
    "RuleAction"= "allow",
    "CidrBlock"= "0.0.0.0/0",
    "RuleNumber"= 1900,
    "Protocol"= "tcp",
    "From"= 10000,
    "To"= 15000      
  } 
]