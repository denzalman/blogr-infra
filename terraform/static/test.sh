#!/bin/bash
set -x
# hostname sendbox

# mkdir /data
# mount /dev/xvdh /data


EC2_INSTANCE_ID=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id || die \"wget instance-id has failed: $?\")
EC2_AVAIL_ZONE=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone || die \"wget availability-zone has failed: $?\")
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"

#############
# EBS VOLUME
#
# note: /dev/sdh => /dev/xvdh
# see: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html
#############

# wait for EBS volume to attach
DATA_STATE="unknown"
until [ $DATA_STATE == "attached" ]; do
	DATA_STATE=$(aws ec2 describe-volumes \
	    --region $${EC2_REGION} \
	    --filters \
	        Name=attachment.instance-id,Values=$${EC2_INSTANCE_ID} \
	        Name=attachment.device,Values=/dev/xvdh \
	    --query Volumes[].Attachments[].State \
	    --output text)
	echo 'waiting for volume...'
	sleep 5
done

#echo 'EBS volume attached!'

#echo '/dev/xvdh /data ext4 defaults,nofail,noatime,nodiratime,barrier=0,data=writeback 0 2' >> /etc/fstab
#mount -a

# mkdir /data
# mount /dev/xvdh /data
# chown ubuntu:ubuntu /data
# chmod 777 /data