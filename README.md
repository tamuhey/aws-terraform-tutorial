# AWS with terraform tutorial

`main.tf` defines the following resouces:

- vpc
- public subnet
- private subnet
- internet gateway
- nat gateway
- route table
- security groups
- elastic ip
- ec2 in public subnet
- ec2 in private subnet

The ec2 in the public subnet connects Internet through the internet gateway.  
The ec2 in the private subnet connects Internet through the nat gateway in inside-out direction only.
