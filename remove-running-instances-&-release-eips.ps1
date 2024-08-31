# Define the region
$region = "eu-west-2"

# 1. List and disassociate all Elastic IPs
Write-Output "Listing and disassociating all Elastic IPs..."
$addresses = aws ec2 describe-addresses `
    --region $region `
    --query 'Addresses[*].[AllocationId,AssociationId]' `
    --output json | ConvertFrom-Json

foreach ($address in $addresses) {
    $allocationId = $address[0]
    $associationId = $address[1]

    if ($associationId -ne $null) {
        Write-Output "Disassociating Elastic IP $allocationId..."
        aws ec2 disassociate-address `
            --region $region `
            --association-id $associationId | Out-Null
    }
}

# 2. Release all Elastic IPs
Write-Output "Releasing all Elastic IPs..."
foreach ($address in $addresses) {
    $allocationId = $address[0]
    
    if ($allocationId -ne $null) {
        Write-Output "Releasing Elastic IP $allocationId..."
        aws ec2 release-address `
            --region $region `
            --allocation-id $allocationId | Out-Null
    }
}

# 3. List and terminate all running instances
Write-Output "Listing all running instances..."
$instanceIds = aws ec2 describe-instances `
    --region $region `
    --query 'Reservations[*].Instances[*].InstanceId' `
    --output text | ForEach-Object { $_.Trim() }

if ($instanceIds -eq "") {
    Write-Output "No running instances found."
} else {
    Write-Output "Terminating instances..."
    aws ec2 terminate-instances `
        --region $region `
        --instance-ids $instanceIds | Out-Null

    # Wait for instances to terminate
    Write-Output "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated `
        --region $region `
        --instance-ids $instanceIds
    Write-Output "Instances terminated."
}
