resource "aws_security_group" "load_balancer_sg"{
    name="Load balancer SG"
    description = "ALB to forward traffic to app with godaddy dn with cert termination"
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress{
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "app_security_group"{
    name="security group to be applied to tomcat application"
    description = "allow from lb only"
    ingress{
        from_port = 8080
        to_port=8080
        protocol = "tcp"
        security_groups = [ aws_security_group.load_balancer_sg.id ]
    }
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

}
resource "aws_security_group" "app_mq_db"{
    name="security group to be applied to backend server"
    description = "allow traffic to backend server mq,cache,db and from each other(sgid of itself)"
    ingress{
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [ aws_security_group.app_security_group.id ]
    }
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress{
        from_port = 11211
        to_port= 11211
        protocol = "tcp"
        security_groups = [ aws_security_group.app_security_group.id ]
    }

    ingress{
        from_port = 5672
        to_port= 5672
        protocol = "tcp"
        security_groups = [ aws_security_group.app_security_group.id ]
    }
    ingress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        ## allow traffic from itself self reference is not allowed
        self = true
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
data aws_key_pair "vprof"{
    key_name = "ecs"
}
data "template_file" "mysql_userdata" {
  template="${file("/Users/pragyabharti/tfCourse/devops_project/tfdevops_project/app_setup/templates/mysql.sh")}"
}
data "template_file" "memcached_userdata" {
  template="${file("/Users/pragyabharti/tfCourse/devops_project/tfdevops_project/app_setup/templates/memcache.sh")}"
}
data "template_file" "rabbitmq_userdata" {
  template="${file("/Users/pragyabharti/tfCourse/devops_project/tfdevops_project/app_setup/templates/rabbitmq.sh")}"
}
data "template_file" "tomcat_userdata" {
  template="${file("/Users/pragyabharti/tfCourse/devops_project/tfdevops_project/app_setup/templates/tomcat_ubuntu.sh")}"
}
resource "aws_instance" "mysqlinstance" {
  ami ="ami-0a3277ffce9146b74"
  instance_type = "t2.micro"
  user_data = data.template_file.mysql_userdata.template
  vpc_security_group_ids = [aws_security_group.app_mq_db.id]
  key_name=data.aws_key_pair.vprof.key_name
  tags = {
    Name = "mysql"
  }
}
resource "aws_instance" "memcachedinstance" {

  ami ="ami-0a3277ffce9146b74"
  instance_type = "t2.micro"
  user_data = data.template_file.memcached_userdata.template
  vpc_security_group_ids = [aws_security_group.app_mq_db.id]
  key_name=data.aws_key_pair.vprof.key_name
  tags = {
    Name = "memcached"
  }
}
resource "aws_instance" "rabbitmqinstance" {
  ami ="ami-0a3277ffce9146b74"
  instance_type = "t2.micro"
  user_data = data.template_file.rabbitmq_userdata.template
  vpc_security_group_ids = [aws_security_group.app_mq_db.id]
  key_name=data.aws_key_pair.vprof.key_name
  tags = {
    Name = "rabbitmq"
  }
}

resource "aws_route53_zone" "vprof" {
  name = "vprof.in"
  vpc {
    vpc_id     = "vpc-9e47a0f5"
    vpc_region = "ap-south-1"
  }
}
# resource "aws_route53_zone_association" "vprof" {
#   zone_id = aws_route53_zone.vprof.zone_id
#   vpc_id  = "vpc-9e47a0f5"
# }
resource "aws_route53_record" "db01" {
  zone_id = aws_route53_zone.vprof.zone_id
  name    = "db01"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.mysqlinstance.private_ip]
}
resource "aws_route53_record" "mc01" {
  zone_id = aws_route53_zone.vprof.zone_id
  name    = "mc01"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.memcachedinstance.private_ip]
}
resource "aws_route53_record" "rmq01" {
  zone_id = aws_route53_zone.vprof.zone_id
  name    = "rmq01"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.rabbitmqinstance.private_ip]
}
resource "aws_s3_bucket" "artifactVpof" {
  bucket = "artifactvprof"

#   acl    = "private"   # or can be "public-read"

}

resource "aws_s3_object" "name" {
  bucket=aws_s3_bucket.artifactVpof.id
  key="ROOT.war"
#   acl="private"
  source = "/Users/pragyabharti/tfCourse/devops_project/tfdevops_project/ROOT.war"
}


resource "aws_iam_role" "ec2_to_s3" {
  name = "s3_role"
  path = "/"

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
resource "aws_iam_policy" "s3access" {
  name="s3accessartifact"
  policy=jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::artifactvprof/*"]
    }
  ]
})
}
resource "aws_iam_role_policy_attachment" "ec2tos3artifact" {
  role       = aws_iam_role.ec2_to_s3.name
  policy_arn = aws_iam_policy.s3access.arn
}
resource "aws_iam_instance_profile" "vprofs3_profile" {
  name = "vprofs3_profile"
  role = aws_iam_role.ec2_to_s3.name
}
# resource "aws_instance" "tomcatinstance" {
#    ami ="ami-08ee6644906ff4d6c"
#    #ami="ami-0ee778ea24da65a7a"
#   instance_type = "t2.micro"
#   user_data = data.template_file.tomcat_userdata.template
#   vpc_security_group_ids = [aws_security_group.app_security_group.id]
#   key_name=data.aws_key_pair.vprof.key_name
#   iam_instance_profile = aws_iam_instance_profile.vprofs3_profile.name
#   tags = {
#     Name = "tomcatinstance"
#   }
# }

resource "aws_alb" "tomcat-alb" {
  name = "tomcat-alb"
  internal = false
  subnets=["subnet-0ee0ec66","subnet-627b062e"]
  security_groups = [aws_security_group.load_balancer_sg.id]
}
resource "aws_lb_target_group" "vprofTG" {
  name     = "vprofLB"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "vpc-9e47a0f5"
  health_check {
    path = "/login"
    port = 8080
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"  # has to be HTTP 200 or fails
  }
}

# resource "aws_lb_target_group_attachment" "vprofTGAttach" {
#   target_group_arn = aws_lb_target_group.vprofTG.arn
#   target_id        = aws_instance.tomcatinstance.id
#   port             = 8080
# }

resource "aws_alb_listener" "tomcat-listener_http" {
  default_action {
    target_group_arn = aws_lb_target_group.vprofTG.arn
    type = "forward"
  }
  load_balancer_arn = aws_alb.tomcat-alb.arn
  port = 80
  protocol = "HTTP"

}
resource "aws_alb_listener" "tomcat-listener_https" {
  default_action {
    target_group_arn = aws_lb_target_group.vprofTG.arn
    type = "forward"
  }
  load_balancer_arn = aws_alb.tomcat-alb.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = "arn:aws:acm:ap-south-1:848417356303:certificate/46f4ae98-8687-4d94-a27b-05248ea53020"
}

resource "aws_launch_configuration" "vprof" {
  image_id="ami-04a6d7dad70a92717"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.app_security_group.id]
  iam_instance_profile = aws_iam_instance_profile.vprofs3_profile.name
  #user_data            = "#!/bin/bash\necho 'ECS_CLUSTER=${var.clusterName}' > /etc/ecs/ecs.config\nstart ecs"
  key_name = data.aws_key_pair.vprof.key_name
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "vprof" {
  name                 = "content"
  vpc_zone_identifier  = ["subnet-0ee0ec66", "subnet-627b062e"]
  launch_configuration = aws_launch_configuration.vprof.name
  min_size             = 1
  max_size             = 2
  health_check_type    = "ELB"

  target_group_arns = [aws_lb_target_group.vprofTG.arn]

  tag {
    key                 = "Name"
    value               = "tomcat"
    propagate_at_launch = true
  }
}
resource "aws_autoscaling_policy" "vprof_policy_up" {
  name = "vprof_up"
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 40.0
  }
  #cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.vprof.name}"
}

resource "aws_sns_topic" "vprof_updates" {
  name = "vprof-updates-topic"
}
resource "aws_autoscaling_notification" "vprof_notifications" {
  group_names = [
    aws_autoscaling_group.vprof.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.vprof_updates.arn
}



