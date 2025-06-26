resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_pair
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
  Name = "nginx-ec2-instance"
}
}

resource "aws_iam_role" "cicd_role" {
  name = "UnifiedCICDRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Principal: {
          Service: [
            "codepipeline.amazonaws.com",
            "codebuild.amazonaws.com",
            "codedeploy.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        },
        Action: "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cicd_inline_policy" {
  name = "UnifiedCICDPolicy"
  role = aws_iam_role.cicd_role.name

  policy = jsonencode({
    Version: "2012-10-17",
    Statement: [

      # General AWS Actions
      {
        Effect: "Allow",
        Action: [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource: "*"
      },

      # CodeBuild
      {
        Effect: "Allow",
        Action: [
          "codebuild:BatchGet*",
          "codebuild:StartBuild",
          "codebuild:StopBuild",
          "codebuild:BatchPutCodeCoverages"
        ],
        Resource: "*"
      },

      # CodeDeploy
      {
        Effect: "Allow",
        Action: [
          "codedeploy:CreateDeployment",
          "codedeploy:Get*",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:List*"
        ],
        Resource: "*"
      },

      # CodePipeline
      {
        Effect: "Allow",
        Action: [
          "codepipeline:*"
        ],
        Resource: "*"
      },

      # S3 (for artifacts)
      {
        Effect: "Allow",
        Action: [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource: "*"
      },

      # EC2 (for CodeDeploy targeting instances)
      {
        Effect: "Allow",
        Action: [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:CreateTags"
        ],
        Resource: "*"
      },

      # IAM PassRole (needed for CodeBuild/CodePipeline to assume other roles)
      {
        Effect: "Allow",
        Action: "iam:PassRole",
        Resource: "*"
      }
    ]
  })
}
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "UnifiedCICDEC2Profile"
  role = aws_iam_role.cicd_role.name
}


