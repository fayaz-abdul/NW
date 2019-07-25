#!/bin/bash -xe

# Init
yum install -y aws-cli

aws configure set s3.signature_version s3v4
aws configure set region ${region}
yum update -y


# Setup
yum install -y puppet3 curl jq nfs-untils

cat > /etc/issue << EOL
  This system is for the use of authorised users only in accordance
  with MAG security policies and procedures. Individuals using this
  device without authorisation or in excess of their authority are subject
  to sanctionary procedures by MAG authorities and/or law enforcement
  officials. MAG will not be responsible for any misuse or personal
  use of any kind, in its information systems, and reserves the right
  for monitoring systems usage to control abusive situations or security
  policy violations.
EOL

sudo chown root:root /etc/issue && chmod 644 /etc/issue

echo "env=${environment}" > /etc/facter/facts.d/env.txt
echo "customer=${customer}" > /etc/facter/facts.d/customer.txt
echo "project=${project}" > /etc/facter/facts.d/project.txt
echo "category=${category}" > /etc/facter/facts.d/category.txt
echo "component=${component}" > /etc/facter/facts.d/component.txt
echo "mount_target_a=${LogstashMountTargetA}" > /etc/facter/facts.d/mount_target_a.txt
echo "mount_target_b=${LogstashMountTargetB}" > /etc/facter/facts.d/mount_target_b.txt
echo "ec2_region=${region}" > /etc/facter/facts.d/ec2_region.txt

cat > /etc/ecs/ecs.config << EOL
  ECS_CLUSTER=${LogstashEcsCluster}

  AWS_DEFAULT_REGION=${region}

  ECS_LOGFILE=/var/log/ecs/ecs-agent.log

  ECS_ENABLE_TASK_IAM_ROLE=true

  ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true

  ECS_UPDATES_ENABLED=true

  ECS_UPDATE_DOWNLOAD_DIR=/data/updates

  ECS_AVAILABLE_LOGGING_DRIVERS=["awslogs", "none"]
EOL

sudo chmod 600 /etc/ecs/ecs.config

echo "ecs_cluster=${LogstashEcsCluster}" > /etc/facter/facts.d/ecs_cluster.txt


cat > /etc/puppet/site.pp << EOL
    include ::stdlib

    service { 'sshd': }

    Sshd_config {
      ensure => present,
      notify => Service['sshd']
    }

    sshd_config { 'Banner':
      value  => '/etc/issue'
    }

    class { '::cloudwatchlogs': region => "${region}" }

    cloudwatchlogs::log { 'cloud-init.log':
      path            => '/var/log/cloud-init.log',
      log_group_name  => '/aws/ec2/logstash',
      streamname      => '{instance_id}/cfn/cloud-init.log'
    }

    cloudwatchlogs::log { 'cloud-init-output.log':
      path           => '/var/log/cloud-init-output.log',
      log_group_name => '/aws/ec2/logstash',
      streamname     => '{instance_id}/cfn/cloud-init-output.log'
    }

    cloudwatchlogs::log { 'cfn-init.log':
      path           => '/var/log/cfn-init.log',
      log_group_name => '/aws/ec2/logstash',
      streamname     => '{instance_id}/cfn/cfn-init.log'
    }

    cloudwatchlogs::log { 'cfn-hup.log':
      path           => '/var/log/cfn-hup.log',
      log_group_name => '/aws/ec2/logstash',
      streamname     => '{instance_id}/cfn/cfn-hup.log'
    }

    cloudwatchlogs::log { 'cfn-wire.log':
      path           => '/var/log/cfn-wire.log',
      log_group_name => '/aws/ec2/logstash',
      streamname     => '{instance_id}/cfn/cfn-wire.log'
    }

    cloudwatchlogs::log { 'ecs-init.log':
      path           => '/var/log/ecs/ecs-init.log',
      log_group_name => '/aws/ec2/logstash',
      streamname     => '{instance_id}/ecs/ecs-init.log'
    }

    cloudwatchlogs::log { 'ecs-agent.log':
      path           => '/var/log/ecs/ecs-agent.log',
      log_group_name => '/aws/ec2/logstash',
      streamname     => '{instance_id}/ecs/ecs-agent.log'
    }
EOL

sudo chmod 600 /etc/puppet/site.pp

cat > /usr/local/bin/mount.sh << EOL
#!/bin/bash

AWS_DEFAULT_REGION=$(facter -p ec2_region)
AZ=$(facter -p ec2_placement_availability_zone)
MOUNT_TARGET=$(facter -p mount_target_a)
[[ "$${AZ}" =~ b$ ]] && MOUNT_TARGET=$(facter -p mount_target_b)
MOUNT_IP=$(aws efs describe-mount-targets --mount-target-id $${MOUNT_TARGET} | jq -r .MountTargets[].IpAddress)
mkdir -p /data/updates
mount -t nfs4 -o nfsvers=4.1 $${MOUNT_IP}:/ /data
EOL

sudo chmod 700 /usr/local/bin/mount.sh

puppet module install puppetlabs-concat --version 2.2.1
puppet module install puppetlabs-stdlib --version 4.24.0
puppet module install herculesteam-augeasproviders_ssh --version 2.5.3
puppet module install kemra102-cloudwatchlogs --version 2.3.1
puppet module install yo61-logrotate --version 1.4.0

# Provision
./usr/local/bin/mount.sh
puppet apply /etc/puppet/site.pp
