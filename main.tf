terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region  = "ap-northeast-1"
  profile = "default"
}


### Data
data "aws_iam_instance_profile" "ec2-role-demo" {
  name = "ec2_profile-demo"
}

### ami
data "aws_ami" "ubuntu" {
    most_recent = true
    owners      = ["099720109477"] # Canonical 官方 AWS 帳號 ID

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values  = ["hvm"]
    }

    filter {
        name = "root-device-type"
        values = ["ebs"]
    }
    
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}

### VPC
resource "aws_vpc" "demo-vpc"{
    cidr_block = "192.0.0.0/16"
}

### Subnet
resource "aws_subnet" "demo-subnet-1" {
    vpc_id = aws_vpc.demo-vpc.id
    cidr_block = "192.0.1.0/24"
    availability_zone = var.aws_availability_zone
    map_public_ip_on_launch = true 
}

### Internet Gatway
resource "aws_internet_gateway" "demo-igw" {
  vpc_id = aws_vpc.demo-vpc.id
}

### EIP
resource "aws_eip" "k8s_master_eip" {
  domain = "vpc"
  tags = {
    Name = "k8s-master-eip"
  }
}

# resource "aws_eip_association" "k8s_master_eip_assoc" {
#   instance_id   = module.ec2_k8s_master.instance_id
#   allocation_id = aws_eip.k8s_master_eip.id
# }


### Route Table
resource "aws_route_table" "demo-route-table" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo-igw.id
  }
  tags = {
    Name = "demo-route-table"
  }
}

### Route Table Connection Subnet
resource "aws_route_table_association" "demo-route-table-association" {
  subnet_id      = aws_subnet.demo-subnet-1.id
  route_table_id = aws_route_table.demo-route-table.id
}

### SG
module "demo-ssh-sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/ssh"
  version = "~> 5.0"

  name        = "demo-ssh-sg"
  description = "Security group for demo ssh access"
  vpc_id      = aws_vpc.demo-vpc.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
}




module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "demo_sg"
  description = "Security group for SSH + NodePort"
  vpc_id      = aws_vpc.demo-vpc.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp"]
  egress_rules        = ["all-all"]


  ingress_with_cidr_blocks = [
    {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      description = "Allow Kubernetes API Server"
      cidr_block = "0.0.0.0/0"
    },
    {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      description = "K8s NodePort Services"
      cidr_block = "0.0.0.0/0"
    }

  ]
}

# module "iam" {
#   source = "./modules/iam"
# }

# # EC2 
# resource "aws_instance" "master-ec2" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t3.medium"

#   subnet_id              = aws_subnet.demo-subnet-1.id
#   vpc_security_group_ids = [module.demo-ssh-sg.security_group_id, module.ec2_sg.security_group_id]

#   iam_instance_profile = data.aws_iam_instance_profile.ec2-role-demo.name
#   tags = {
#     Name = "master-ec2"
#   }

#   # 啟動腳本（user data），使用 templatefile 匯入變數
#   user_data = templatefile("./script/install_K8s_master.sh.tpl",
#   {
#     access_key       = var.access_key
#     private_key      = var.private_key
#     region           = var.region
#     s3buckit_name    = var.s3buckit_name
#   })

#   root_block_device {
#     volume_size = 30         # <-- 修改這裡，例如改成 30 GB
#     volume_type = "gp3"
#   }


#   # 自動配對 public ip ，但在更改user data 時，會導致 instance 重啟(IP會改變)
#   # 後續會改用建立 elastic ip 的方式，掛載到此 instance
#   associate_public_ip_address = true

#   key_name                = "MyKey"
#   disable_api_termination = false
# }

# EC2 Master
# module "ec2_k8s_master" {
#   source = "./modules/ec2_k8s_master"
#   name                   = "k8s-master"
#   ami                    = data.aws_ami.ubuntu.id
#   subnet_id              = aws_subnet.demo-subnet-1.id
#   private_ip             = "192.0.1.10"
#   # default instance type
#   iam_instance_profile   = data.aws_iam_instance_profile.ec2-role-demo.name
#   security_group_ids     = [module.demo-ssh-sg.security_group_id, module.ec2_sg.security_group_id]
#   access_key             = var.access_key
#   private_key            = var.private_key
# }


# EC2 Node
module "ec2_k8s_node" {
  source = "./modules/ec2_k8s_node"
  name                   = "k8s-node2"
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = aws_subnet.demo-subnet-1.id
  private_ip             = "192.0.1.11"
  worker_number          = 2
  instance_type          = "t3.medium"
  volume_size            = 30 

  # default instance type
  iam_instance_profile   = data.aws_iam_instance_profile.ec2-role-demo.name
  security_group_ids     = [module.demo-ssh-sg.security_group_id, module.ec2_sg.security_group_id]
  access_key             = var.access_key
  private_key            = var.private_key

}

module "ec2_k8s_node2" {
  source = "./modules/ec2_k8s_node"
  name                   = "k8s-node3"
  ami                    = data.aws_ami.ubuntu.id
  subnet_id              = aws_subnet.demo-subnet-1.id
  private_ip             = "192.0.1.12"
  worker_number          = 3
  instance_type          = "t3.medium"
  volume_size            = 30 

  # default instance type
  iam_instance_profile   = data.aws_iam_instance_profile.ec2-role-demo.name
  security_group_ids     = [module.demo-ssh-sg.security_group_id, module.ec2_sg.security_group_id]
  access_key             = var.access_key
  private_key            = var.private_key

}














