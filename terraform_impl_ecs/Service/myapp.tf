# ecs service role
resource "aws_iam_role" "ecs-service-role" {
name = "ecs-service-role"
assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy_attachment" "ecs-service-attach1" {
  name       = "ecs-service-attach1"
  roles      = [aws_iam_role.ecs-service-role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}


data "template_file" "myapp-task-definition-template" {
  template = file("/Users/pragyabharti/tfCourse/terraform_impl/Service/template/app.json.tpl")
  vars = {
    REPOSITORY_URL = replace(var.REPOSITORY_URL, "https://", "")
  }
}
resource "aws_ecs_task_definition" "myapp-task-definition" {
  family                = "myapp"
  container_definitions = data.template_file.myapp-task-definition-template.rendered
}
resource "aws_elb" "myapp-elb" {
  name = "myapp-elb"

  listener {
    instance_port     = 4005
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    target              = "HTTP:4005/"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  subnets         = ["subnet-0ee0ec66", "subnet-627b062e"]
  security_groups = [var.elbSgid]

  tags = {
    Name = "myapp-elb"
  }
}

resource "aws_ecs_service" "myapp-service" {
  name            = "myapp"
  cluster         = var.clusterName
  task_definition = aws_ecs_task_definition.myapp-task-definition.arn
  desired_count   = 1
  iam_role        = aws_iam_role.ecs-service-role.arn
  depends_on      = [aws_iam_policy_attachment.ecs-service-attach1]

  load_balancer {
    elb_name       = aws_elb.myapp-elb.name
    container_name = "myapp"
    container_port = 4005
  }

#   lifecycle {
#     ignore_changes = [task_definition]
#   }
}


