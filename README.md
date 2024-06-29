# terraform-ansible-sandbox
Building on the Terraform basics outlined [terraform-sandbox](https://github.com/wmcdonald404/terraform-sandbox). This repo moves from simple Terraform provisoning of EC2 instances, to include the [Terraform provider for Ansible](https://registry.terraform.io/providers/ansible/ansible/latest/docs) to perform post-provisioning steps using Ansible playbooks.


```
.terraform-ansible-sandbox
└── single_az # single-AZ, single public subnet, single ec2 instance, single EBS volume
```

## Prerequisites
1. For testing purposes, we can use an AWS Access Key:
    ```
    wmcdonald@fedora:~$ export AWS_ACCESS_KEY_ID=<ACCESS KEY ID>
    wmcdonald@fedora:~$ export AWS_SECRET_ACCESS_KEY=<SECRET ACCESS KEY>
    ```

## Usage
1. Clone the repository
    ```
    wmcdonald@fedora:~$ git clone git@github.com:wmcdonald404/terraform-ansible-sandbox.git ~/repos/personal/terraform-ansible-sandbox/
    ```

2. Initialise the Terraform configuration **for the single-AZ, single instance example**:
    ```
    wmcdonald@fedora:~$ cd ~/repos/personal/terraform-ansible-sandbox/single_az
    wmcdonald@fedora:single_az$ tf init

    Initializing the backend...

    Initializing provider plugins...
    - Finding hashicorp/aws versions matching ">= 5.51.1"...
    - Installing hashicorp/aws v5.51.1...
    <snip>

    Terraform has been successfully initialized!
    ```

3. Update the [`key_name`](https://github.com/wmcdonald404/terraform-sandbox/blob/6a813e5436e209c873a6b5a62d672c2a74a534a6/single_az/main.tf#L82) on line 82 to use a named keypair on your local system.

4. Validate the Terraform configuration
    ```
    wmcdonald@fedora:single_az$ tf validate
    Success! The configuration is valid.
    ```

5. Review the Terraform plan

    ```
    wmcdonald@fedora:single_az$ terraform plan 
    <snip output>    
    Plan: 11 to add, 0 to change, 0 to destroy.
    ```

6. Apply the Terraform configuration

    List the existing VPCs before the Terraform apply (ensure none exist *before*):
    ```
    wmcdonald@fedora:single_az$ aws ec2 describe-vpcs --region eu-west-1 | jq '.Vpcs[] | {VpcId, Name: (if .Tags then (.Tags[] | select(.Key == "Name") | .Value) else "" end)}'
    ```

    Apply the Terraform:
    ```
    wmcdonald@fedora:single_az$ tf apply -auto-approve
    aws_vpc.main: Creating...
    aws_vpc.main: Creation complete after 1s [id=vpc-06987cf1369e8caec]
    aws_internet_gateway.gw: Creating...
    aws_subnet.public_subnets[2]: Creating...
    aws_subnet.private_subnets[0]: Creating...
    aws_subnet.private_subnets[1]: Creating...
    aws_subnet.public_subnets[0]: Creating...
    aws_subnet.private_subnets[2]: Creating...
    aws_subnet.public_subnets[1]: Creating...
    aws_security_group.ssh_sg: Creating...
    aws_internet_gateway.gw: Creation complete after 0s [id=igw-03c3cf8f2037de39c]
    aws_subnet.public_subnets[2]: Creation complete after 0s [id=subnet-091f350442df3fb4a]
    aws_subnet.public_subnets[0]: Creation complete after 0s [id=subnet-0b6d15a289dc6582a]
    aws_route.bastion_gateway_route: Creating...
    aws_subnet.public_subnets[1]: Creation complete after 0s [id=subnet-0fb6f95dea0161876]
    aws_subnet.private_subnets[1]: Creation complete after 0s [id=subnet-058ca9612ac66e0c1]
    aws_subnet.private_subnets[0]: Creation complete after 0s [id=subnet-0f255719998d69abe]
    aws_subnet.private_subnets[2]: Creation complete after 0s [id=subnet-02ad95cffac939e9a]
    aws_route.bastion_gateway_route: Creation complete after 1s [id=r-rtb-02d352e8a5f1f0b141080289494]
    aws_security_group.ssh_sg: Creation complete after 1s [id=sg-08e66031c50e98aca]
    aws_instance.public_bastions[0]: Creating...
    aws_instance.public_bastions[0]: Still creating... [10s elapsed]
    aws_instance.public_bastions[0]: Still creating... [20s elapsed]
    aws_instance.public_bastions[0]: Still creating... [30s elapsed]
    aws_instance.public_bastions[0]: Still creating... [40s elapsed]
    aws_instance.public_bastions[0]: Creation complete after 43s [id=i-0d31541b66c04da7b]

    Apply complete! Resources: 11 added, 0 changed, 0 destroyed.
    ```

    Compare the list of VPCs after Terraform apply:
    ```
    wmcdonald@fedora:single_az$ aws ec2 describe-vpcs --region eu-west-1 | jq '.Vpcs[] | {VpcId, Name: (if .Tags then (.Tags[] | select(.Key == "Name") | .Value) else "" end)}'
    {
    "VpcId": "vpc-06987cf1369e8caec",
    "Name": "terraform-sandbox-multi"
    }
    ```

7. Review the EC2 instances, their attached EBS volumes, and tags:
    ```
    wmcdonald@fedora:single_az$ aws ec2 describe-instances | jq -c '.Reservations[].Instances[] | [.InstanceId, .Placement, .BlockDeviceMappings, .Tags ]'
    [
    "i-0d31541b66c04da7b",
    {
        "AvailabilityZone": "eu-west-1a",
        "GroupName": "",
        "Tenancy": "default"
    },
    [
        {
        "DeviceName": "/dev/xvda",
        "Ebs": {
            "AttachTime": "2024-06-29T08:12:30+00:00",
            "DeleteOnTermination": true,
            "Status": "attached",
            "VolumeId": "vol-09485e7eeafd01644"
        }
        }
    ],
    [
        {
        "Key": "InstanceRole",
        "Value": "bastion"
        },
        {
        "Key": "InstanceName",
        "Value": "bastion-0"
        },
        {
        "Key": "Name",
        "Value": "bastion-0"
        }
    ]
    ```

## Adding the Ansible provider

## Testing access

1. List active, running instances (output truncated)

    ```
    wmcdonald@fedora:~$ aws ec2 describe-instance-status 
    {
        "InstanceStatuses": [
            {
                "AvailabilityZone": "eu-west-1a",
                "InstanceId": "i-07db34c7808ea3ffa",
                "InstanceState": {
                    "Code": 16,
                    "Name": "running"
                }
            }
        ]
    }
    ```

2. List the public IP for the running instance
    ```
    wmcdonald@fedora:~$ aws ec2 describe-instances --instance-ids i-07db34c7808ea3ffa | jq -rc '.Reservations[].Instances[] | (.InstanceId, .PublicIpAddress)' | paste -d, - - 
    i-07db34c7808ea3ffa,3.253.254.112
    ```

3. Connect to the instance

**Note:** For Debian the default user will be 'admin', for Ubuntu 'ubuntu'.

    ```
    wmcdonald@fedora:~$ ssh -ladmin 3.253.254.112
    Linux ip-10-0-1-175 6.1.0-13-cloud-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.55-1 (2023-09-29) x86_64

    The programs included with the Debian GNU/Linux system are free software;
    the exact distribution terms for each program are described in the
    individual files in /usr/share/doc/*/copyright.

    Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
    permitted by applicable law.
    Last login: Tue May 28 14:37:23 2024 from 10.10.10.4
    ```

## Clean up
1. Once done with the test infrastructure, remove the VPC and all its resources to ensure costs are contained:
    ```
    wmcdonald@fedora:single_az$ terraform apply -destroy -auto-approve
    aws_ebs_volume.data_volumes[0]: Refreshing state... [id=vol-0388826a426157260]
    aws_vpc.main: Refreshing state... [id=vpc-0e195fd0ce5ab0432]
    aws_ebs_volume.data_volumes[1]: Refreshing state... [id=vol-071c733a3bfc36e7e]
    aws_internet_gateway.gw: Refreshing state... [id=igw-07972f3610e174dbd]
    aws_subnet.private_subnets[1]: Refreshing state... [id=subnet-0bc01ecd4a6a008d8]
    aws_subnet.public_subnets[0]: Refreshing state... [id=subnet-07009315c084917b0]
    aws_subnet.public_subnets[1]: Refreshing state... [id=subnet-038a4c2814c4e278a]
    aws_subnet.private_subnets[2]: Refreshing state... [id=subnet-0815ab789af673ee3]
    aws_subnet.private_subnets[0]: Refreshing state... [id=subnet-0dba1cd8381e13083]
    aws_subnet.public_subnets[2]: Refreshing state... [id=subnet-0ede4c0f954d9cf99]
    aws_route_table.second_rt: Refreshing state... [id=rtb-0d18a10fbae6d5ce6]
    aws_instance.instances[1]: Refreshing state... [id=i-0bba44e3da2690c49]
    aws_instance.instances[0]: Refreshing state... [id=i-08f0fe7cc5ba2102c]
    aws_volume_attachment.ebs_attachments[1]: Refreshing state... [id=vai-1083305993]
    aws_volume_attachment.ebs_attachments[0]: Refreshing state... [id=vai-1308354494]
    <output snipped>
    Plan: 0 to add, 0 to change, 15 to destroy.
    aws_volume_attachment.ebs_attachments[0]: Destroying... [id=vai-1308354494]
    aws_volume_attachment.ebs_attachments[1]: Destroying... [id=vai-1083305993]
    aws_subnet.public_subnets[2]: Destroying... [id=subnet-0ede4c0f954d9cf99]
    aws_subnet.public_subnets[0]: Destroying... [id=subnet-07009315c084917b0]
    aws_subnet.public_subnets[1]: Destroying... [id=subnet-038a4c2814c4e278a]
    aws_route_table.second_rt: Destroying... [id=rtb-0d18a10fbae6d5ce6]
    aws_subnet.public_subnets[2]: Destruction complete after 1s
    aws_subnet.public_subnets[0]: Destruction complete after 1s
    aws_route_table.second_rt: Destruction complete after 1s
    aws_internet_gateway.gw: Destroying... [id=igw-07972f3610e174dbd]
    aws_subnet.public_subnets[1]: Destruction complete after 1s
    aws_internet_gateway.gw: Destruction complete after 0s
    aws_volume_attachment.ebs_attachments[0]: Still destroying... [id=vai-1308354494, 10s elapsed]
    aws_volume_attachment.ebs_attachments[1]: Still destroying... [id=vai-1083305993, 10s elapsed]
    aws_volume_attachment.ebs_attachments[0]: Destruction complete after 11s
    aws_volume_attachment.ebs_attachments[1]: Destruction complete after 11s
    aws_ebs_volume.data_volumes[1]: Destroying... [id=vol-071c733a3bfc36e7e]
    aws_ebs_volume.data_volumes[0]: Destroying... [id=vol-0388826a426157260]
    aws_instance.instances[1]: Destroying... [id=i-0bba44e3da2690c49]
    aws_instance.instances[0]: Destroying... [id=i-08f0fe7cc5ba2102c]
    aws_ebs_volume.data_volumes[1]: Still destroying... [id=vol-071c733a3bfc36e7e, 10s elapsed]
    aws_ebs_volume.data_volumes[0]: Still destroying... [id=vol-0388826a426157260, 10s elapsed]
    aws_instance.instances[1]: Still destroying... [id=i-0bba44e3da2690c49, 10s elapsed]
    aws_instance.instances[0]: Still destroying... [id=i-08f0fe7cc5ba2102c, 10s elapsed]
    aws_ebs_volume.data_volumes[0]: Destruction complete after 10s
    aws_ebs_volume.data_volumes[1]: Destruction complete after 10s
    aws_instance.instances[1]: Still destroying... [id=i-0bba44e3da2690c49, 20s elapsed]
    aws_instance.instances[0]: Still destroying... [id=i-08f0fe7cc5ba2102c, 20s elapsed]
    aws_instance.instances[1]: Still destroying... [id=i-0bba44e3da2690c49, 30s elapsed]
    aws_instance.instances[0]: Still destroying... [id=i-08f0fe7cc5ba2102c, 30s elapsed]
    aws_instance.instances[0]: Destruction complete after 30s
    aws_instance.instances[1]: Still destroying... [id=i-0bba44e3da2690c49, 40s elapsed]
    aws_instance.instances[1]: Destruction complete after 40s
    aws_subnet.private_subnets[0]: Destroying... [id=subnet-0dba1cd8381e13083]
    aws_subnet.private_subnets[1]: Destroying... [id=subnet-0bc01ecd4a6a008d8]
    aws_subnet.private_subnets[2]: Destroying... [id=subnet-0815ab789af673ee3]
    aws_subnet.private_subnets[0]: Destruction complete after 1s
    aws_subnet.private_subnets[2]: Destruction complete after 1s
    aws_subnet.private_subnets[1]: Destruction complete after 1s
    aws_vpc.main: Destroying... [id=vpc-0e195fd0ce5ab0432]
    aws_vpc.main: Destruction complete after 0s

    Apply complete! Resources: 0 added, 0 changed, 15 destroyed.
    ```

2. Verify the VPC and instances are torn down:
    ```
    wmcdonald@fedora:single_az$ aws ec2 describe-instances | jq -c '.Reservations[].Instances[] | [.InstanceId, .State ]' 
    ["i-08f0fe7cc5ba2102c",{"Code":48,"Name":"terminated"}]
    ["i-0bba44e3da2690c49",{"Code":48,"Name":"terminated"}]
    wmcdonald@fedora:single_az$ aws ec2 describe-vpcs 
    {
        "Vpcs": []
    }
    ```

***Note***: The instances will still be shown but in a terminated state until they expire fully (~1 hour).

## References
- [How to Build AWS VPC using Terraform – Step by Step](https://spacelift.io/blog/terraform-aws-vpc)
- [Managing AWS Security Groups Through Terraform](https://spacelift.io/blog/terraform-security-group)
- [.Multiple EC2 Instances using Terraform](https://gist.github.com/saissemet/7dead669cba388240cf67745cd535d40)