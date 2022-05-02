resource "aws_codedeploy_app" "contentShare" {
  compute_platform = "ECS"
  name             = "contentShare"
}
resource "aws_ecs_cluster" "demo" {
  name = "demo"
}

resource "aws_iam_role" "ecs-task-execution-role" {
  name = "ecs-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ecs-task-execution-role" {
  name = "ecs-task-execution-role"
  role = aws_iam_role.ecs-task-execution-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ssm:GetParameters",
        "ssm:GetParameter"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_iam_role" "ecs-demo-task-role" {
  name = "ecs-demo-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


}


resource "aws_iam_role" "demo-codedeploy" {
  name = "demo-codedeploy"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

}
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "demo-codedeploy-role-policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:*",
    #   "ecs:DescribeServices",
      "ecs:CreateTaskSet",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
      "lambda:InvokeFunction",
      "cloudwatch:DescribeAlarms",
      "sns:Publish",
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
    ]
    resources = ["*"
    #   "${var.s3demobucks}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [
      var.kms_arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "demo-codedeploy" {
  name   = "codedeploy-policy"
  #role   = aws_iam_role.demo-codedeploy.name
  #policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  #policy = data.aws_iam_policy_document.demo-codedeploy-role-policy.json
  policy      = data.aws_iam_policy_document.demo-codedeploy-role-policy.json
}
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.demo-codedeploy.name
  policy_arn = aws_iam_policy.demo-codedeploy.arn
}

resource "aws_lb" "demo" {
  name                             = "demo"
  subnets                          = ["subnet-0ee0ec66", "subnet-627b062e"]
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "demo-blue" {
  name                 = "demo-http-blue"
  port                 = "4005"
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = "vpc-9e47a0f5"
  deregistration_delay = "30"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "TCP"
    interval            = 30
  }
}
resource "aws_lb_target_group" "demo-green" {
  name                 = "demo-http-green"
  port                 = "4005"
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = "vpc-9e47a0f5"
  deregistration_delay = "30"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "TCP"
    interval            = 30
  }
}

resource "aws_lb_listener" "demo" {
  load_balancer_arn = aws_lb.demo.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.demo-blue.id
    type             = "forward"
  }
  lifecycle {
    ignore_changes = [
      default_action,
    ]
  }
}

resource "aws_ecs_task_definition" "demo" {
  family             = "demo"
  execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
#   task_role_arn      = aws_iam_role.ecs-demo-task-role.arn
  cpu                = 256
  memory             = 512
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "FARGATE"
  ]

  container_definitions = <<DEFINITION
[
  {
    "essential": true,
    "image": "${var.repository_url}",
    "name": "demo",
    "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
               "awslogs-group" : "awslogs-test",
               "awslogs-region": "${var.AWS_REGION}",
               "awslogs-stream-prefix": "ecs"
            }
     },
     "secrets": [],
     "environment": [],
     "healthCheck": {
       "command": [ "CMD-SHELL", "curl -f http://localhost:4005/ || exit 1" ],
       "interval": 30,
       "retries": 3,
       "timeout": 5
     }, 
     "portMappings": [
        {
           "containerPort": 4005,
           "hostPort": 4005,
           "protocol": "tcp"
        }
     ]
  }
]
DEFINITION

}
resource "aws_security_group" "ecs-demo" {
  name        = "ECS demo"
  vpc_id      = "vpc-9e47a0f5"
  description = "ECS demo"

  ingress {
    from_port   = 4005
    to_port     = 4005
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}
resource "aws_ecs_service" "demo" {
  name            = "demo"
  cluster         = aws_ecs_cluster.demo.id
  desired_count   = 1
  task_definition = aws_ecs_task_definition.demo.arn
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener.demo]

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = ["subnet-0ee0ec66", "subnet-627b062e"]
    security_groups  = [aws_security_group.ecs-demo.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.demo-blue.id
    container_name   = "mycontent "
    container_port   = "4005"
  }
#   lifecycle {
#     ignore_changes = [
#       task_definition,
#       load_balancer
#     ]
#   }
}
resource "aws_codedeploy_deployment_group" "demo" {
  app_name               = aws_codedeploy_app.contentShare.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "demo"
  service_role_arn       = aws_iam_role.demo-codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.demo.name
    service_name = aws_ecs_service.demo.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.demo.arn]
      }

      target_group {
        name = aws_lb_target_group.demo-blue.name
      }

      target_group {
        name = aws_lb_target_group.demo-green.name
      }
    }
  }
}




