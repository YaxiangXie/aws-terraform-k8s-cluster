variable ami {
    description = "AMI ID for the EC2 instance"
    type        = string
    default = ""
}

variable instance_type {
    description = "Instance type for the EC2 instance"
    type        = string
    default     = "t3.medium"
}

variable subnet_id {
    description = "Subnet ID where the EC2 instance will be launched"
    type        = string
    default     = ""
}

variable security_group_ids {
    type = list(string)
}

variable iam_instance_profile {
    description = "IAM instance profile for the EC2 instance"
    type        = string
}

variable user_data_template {
    description = "Path to the user data template file"
    type        = string
    default     = "./script/install_K8s_master.sh.tpl"
}

variable access_key {
    description = "AWS access key for the EC2 instance"
    type        = string
    default     = ""
}

variable private_key {
    description = "Private key for the EC2 instance"
    type        = string
    default     = ""
}

variable region {
    type = string
    default = "ap-northeast-1"
}

variable s3buckit_name {
    description = "S3 bucket name for the EC2 instance"
    type        = string
    default     = "yaxiang1"
}

variable volume_size {
    description = "Size of the root block device in GB"
    type        = number
    default     = 30
}

variable volume_type {
    description = "Type of the root block device"
    type        = string
    default     = "gp2"
}


variable private_ip {
    description = "Private IP address for the EC2 instance"
    type        = string
}

variable key_name {
    description = "Key name for the EC2 instance"
    type        = string
    default     = "MyKey"
}

variable disable_api_termination {
    description = "Whether to disable API termination for the instance"
    type        = bool  
    default     = false
}

variable name {
    description = "Name tag for the EC2 instance"
    type        = string
    default     = "k8s-master"
}

variable extra_tags {
    description = "Additional tags for the EC2 instance"
    type        = map(string)
    default     = {}
}
