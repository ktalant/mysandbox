vpc_cidr                = "10.0.0.0/16"
public_cidrs            = ["10.0.1.0/24", "10.0.11.0/24"]
private_cidrs           = ["10.0.2.0/24", "10.0.12.0/24"]

# Set proper VPN cidr block of your company for security 
bastion_vpn_cidr        = ["0.0.0.0/0"]
instance_type           = "t2.medium"
key_path                = "/root/.ssh/id_rsa.pub"
ami_id                  = "ami-062f7200baf2fa504"
