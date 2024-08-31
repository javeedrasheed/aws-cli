# Variables
$AMI_ID = "ami-07d20571c32ba6cdc"  # Replace with your actual Ubuntu AMI ID
$KEY_NAME = "new"  # Replace with your actual key pair name without .pem
$SECURITY_GROUP_ID = "sg-0e9f5c032486f9687"  # Your security group ID
$INSTANCE_TYPE = "t2.micro"  # Adjust as needed
$REGION = "eu-west-2"

# Subnets
$SUBNETS = @(
    "subnet-044207fbd6f7b3b8a",
    "subnet-08cb114e6c672db1c",
    "subnet-067f9fe1335631653"
)

# Base64 encode the User Data script
$USER_DATA = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("C:\Users\Shahid Rasheed\Desktop\New folder\aws-cli\user-data.sh"))

# Launch instances and store instance IDs
$instanceDetails = @()
for ($i = 0; $i -lt $SUBNETS.Length; $i++) {
    $subnetId = $SUBNETS[$i]
    $instanceName = "docker-node$($i + 1)"
    
    $result = aws ec2 run-instances `
        --region $REGION `
        --image-id $AMI_ID `
        --count 1 `
        --instance-type $INSTANCE_TYPE `
        --key-name $KEY_NAME `
        --security-group-ids $SECURITY_GROUP_ID `
        --subnet-id $subnetId `
        --user-data $USER_DATA `
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instanceName}]" `
        --output json --no-cli-pager

    $instanceId = ($result | ConvertFrom-Json).Instances[0].InstanceId
    $instanceDetails += [PSCustomObject]@{ InstanceId = $instanceId; InstanceName = $instanceName }
}

# Allocate Elastic IPs, associate with instances, and capture the results
foreach ($detail in $instanceDetails) {
    $instanceId = $detail.InstanceId
    $instanceName = $detail.InstanceName
    
    # Allocate an Elastic IP
    $allocationIdResult = aws ec2 allocate-address --region $REGION --output json --no-cli-pager
    $allocationId = ($allocationIdResult | ConvertFrom-Json).AllocationId
    $publicIp = ($allocationIdResult | ConvertFrom-Json).PublicIp

    # Associate the Elastic IP with the instance
    aws ec2 associate-address `
        --region $REGION `
        --instance-id $instanceId `
        --allocation-id $allocationId `
        --output table --no-cli-pager

    # Update the details with the associated Elastic IP
    $detail | Add-Member -MemberType NoteProperty -Name ElasticIp -Value $publicIp
}

# Output the results
$instanceDetails | Format-Table -Property InstanceName, InstanceId, ElasticIp
