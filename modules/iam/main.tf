# Build an IAM role
resource "aws_iam_role" "ec2-role-demo" {
    name = "ec2-role-demo"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"   # 允許 EC2 呼叫 STS 來 assume 這個角色
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"  #給EC2使用
                }
            }
        ]
    })

    tags = {
        project = "demo"
    }
}

# 建立一個 IAM Instance Profile，用來讓 EC2 實際掛載 IAM Role
resource "aws_iam_instance_profile" "ec2_profile-demo" {
    name = "ec2_profile-demo"   
    role = aws_iam_role.ec2-role-demo.name
}

resource "aws_iam_role_policy" "ec2_policy" {
    name  = "ec2_policy"
    role = aws_iam_role.ec2-role-demo.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "ecr:GetAuthorizationToken",        # 取得 ECR 認證
                    "ecr:BatchGetImage",                # 批次取得 image metadata
                    "ecr:GetDownloadUrlForLayer"        # get image layer download url
                ]
                Effect = "Allow"
                Resource = "*"
            }
        ]
    })
}
