resource "aws_instance" "this" {
    ami = var.ami
    instance_type = var.instance_type

    subnet_id = var.subnet_id
    vpc_security_group_ids = var.security_group_ids
    iam_instance_profile = var.iam_instance_profile
    user_data = templatefile(var.user_data_template, {
        access_key = var.access_key
        private_key = var.private_key
        region = var.region
        s3buckit_name  = var.s3buckit_name
        worker_number = var.worker_number
    })

    root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
    }

    associate_public_ip_address = var.associate_public_ip_address
    private_ip = var.private_ip
    key_name                    = var.key_name
    disable_api_termination     = var.disable_api_termination

    tags = merge(
    {
      Name = var.name
    },
    var.extra_tags
    )

    
    lifecycle {
        ignore_changes = [
            user_data, 
            associate_public_ip_address
        ]
        prevent_destroy = true
    }
}