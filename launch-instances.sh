#!/bin/bash

# Variables
AMI_ID="ami-07d20571c32ba6cdc"  # Replace with your actual Ubuntu AMI ID
KEY_NAME="new"  # Replace with your actual key pair name without .pem
SECURITY_GROUP_ID="sg-0e9f5c032486f9687"  # Your security group ID
INSTANCE_TYPE="t2.micro"  # Adjust as needed
REGION="eu-west-2"

# Subnets
SUBNETS=("subnet-044207fbd6f7b3b8a" "subnet-08cb114e6c672db1c" "subnet-067f9fe1335631653")

# Base64 encode the User Data script
USER_DATA=$(base64 -w 0 user-data.sh)

# Launch instances
for i in {0..2}
do
	  aws ec2 run-instances \
		      --region $REGION \
		          --image-id $AMI_ID \
			      --count 1 \
			          --instance-type $INSTANCE_TYPE \
				      --key-name $KEY_NAME \
				          --security-group-ids $SECURITY_GROUP_ID \
					      --subnet-id ${SUBNETS[$i]} \
					          --user-data "$USER_DATA" \
						      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=docker-node$((i+1))}]" \
						          --output table
						  done

