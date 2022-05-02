# resource "tls_private_key" "this" {
#   algorithm = "RSA"
# }
# resource "aws_key_pair" "content" {
#   key_name   = "content"
#   public_key = tls_private_key.this.public_key_openssh
# }
data "aws_key_pair" "ecs"{
    key_name = "ecs"
}
resource "aws_ecs_cluster" "contentShare" {
    name=var.clusterName 
}
resource "aws_iam_role" "content" {
  name="content"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ecs-service-attach2" {
  name       = "ecs-service-attach2"
  roles      = [aws_iam_role.content.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "content" {
    name="content"
    role=aws_iam_role.content.name
}

resource "aws_iam_role_policy" "ecs-ec2-role-policy" {
name   = "ecs-ec2-content"
role   = aws_iam_role.content.name
policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ecs:CreateCluster",
              "ecs:DeregisterContainerInstance",
              "ecs:DiscoverPollEndpoint",
              "ecs:Poll",
              "ecs:RegisterContainerInstance",
              "ecs:StartTelemetrySession",
              "ecs:Submit*",
              "ecs:StartTask",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}
EOF

}

resource "aws_security_group" "myapp-elb-securitygroup" {
#   vpc_id      = aws_vpc.main.id
  name        = "myapp-elb"
  description = "security group for ecs"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "myapp-elb"
  }
}

resource "aws_security_group" "ecs-securitygroup" {
#   vpc_id      = aws_vpc.main.id
  name        = "ecs"
  description = "security group for ecs"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 4005
    to_port         = 4005
    protocol        = "tcp"
    security_groups = [aws_security_group.myapp-elb-securitygroup.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ecs"
  }
}


resource "aws_launch_configuration" "contentShare" {
  image_id="ami-03ab8e59e04c7fdbb"
  instance_type = var.ECS_INSTANCE_TYPE
  security_groups = [ aws_security_group.ecs-securitygroup.id ]
  iam_instance_profile = aws_iam_instance_profile.content.id
  user_data            = "#!/bin/bash\necho 'ECS_CLUSTER=${var.clusterName}' > /etc/ecs/ecs.config\nstart ecs"
  key_name = data.aws_key_pair.ecs.key_name
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "ecs-example-autoscaling" {
  name                 = "content"
  vpc_zone_identifier  = ["subnet-0ee0ec66", "subnet-627b062e"]
  launch_configuration = aws_launch_configuration.contentShare.name
  min_size             = 1
  max_size             = 1
  tag {
    key                 = "Name"
    value               = "ecs-ec2-container"
    propagate_at_launch = true
  }
}
