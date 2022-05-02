resource "aws_security_group" "backendSG"{
    name="backend-services"
    ingress{
        from_port=0
        to_port = 0
        protocol = "tcp"
        self = true
    }
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.dbInit.id]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
data "aws_key_pair" "ecs"{
    key_name = "ecs"
}
resource "aws_db_parameter_group" "default" {
  name   = "rds-vprof"
  family = "mysql5.7"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}
resource "aws_db_subnet_group" "rdsInst" {
  name       = "rds-vprof"
  subnet_ids = ["subnet-0ee0ec66","subnet-627b062e"]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "default" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  db_name                 = "accounts"
  username             = "admin"
  password             = "admin123"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name  = aws_db_subnet_group.rdsInst.name
  vpc_security_group_ids    = ["${aws_security_group.backendSG.id}"]
  deletion_protection = true
  skip_final_snapshot  = true
  #final_snapshot_identifier= "db-backup"
}
# resource "aws_elasticache_parameter_group" "vprof" {
#   name   = "cache-params"
#   family = "memcached1.5"

#   parameter {
#     name  = "activerehashing"
#     value = "yes"
#   }
# }
resource "aws_elasticache_subnet_group" "vprof" {
  name       = "tf-test-cache-subnet"
  subnet_ids = ["subnet-0ee0ec66","subnet-627b062e"]
}
resource "aws_elasticache_cluster" "vprof" {
  cluster_id           = "vprof"
  engine               = "memcached"
  engine_version = "1.5.10"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 2
  parameter_group_name = "default.memcached1.5"
  port                 = 11211
}
resource "aws_mq_configuration" "example" {
  description    = "Example Configuration"
  name           = "example"
  engine_type    = "ActiveMQ"
  engine_version = "5.15.0"

  data = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
  <plugins>
    <forcePersistencyModeBrokerPlugin persistenceFlag="true"/>
    <statisticsBrokerPlugin/>
    <timeStampingBrokerPlugin ttlCeiling="86400000" zeroExpirationOverride="86400000"/>
  </plugins>
</broker>
DATA
}
resource "aws_mq_broker" "example" {
  broker_name = "example"

  configuration {
    id       = aws_mq_configuration.example.id
    revision = aws_mq_configuration.example.latest_revision
  }

  engine_type        = "ActiveMQ"
  engine_version     = "5.15.0"
  host_instance_type = "mq.t2.micro"
  security_groups    = [aws_security_group.backendSG.id]

  user {
    username = "rabbit"
    password = "Blue7890Bunny"
  }
}
resource "aws_security_group" "dbInit"{
    name="db-init"
    description = "db-init"
    ingress{
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress{
        from_port = 80
        to_port = 80
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
# resource "aws_instance" "vprof" {
#   ami = "ami-0cfedf42e63bba657"
#   instance_type = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.dbInit.id]
#   key_name = data.aws_key_pair.ecs.key_name
# }

resource "aws_elastic_beanstalk_application" "vprof" {
  name        = "vprof-app"
  description = "beanstalk for vprof front end"
}

resource "aws_elastic_beanstalk_environment" "vprof" {
  name                = "vprof-env"
  application         = aws_elastic_beanstalk_application.vprof.name
  solution_stack_name = "64bit Amazon Linux 2015.03 v2.0.3 running Go 1.4"
}