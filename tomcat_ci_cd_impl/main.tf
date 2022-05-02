resource "aws_security_group" "jenkins_firewall" {
  name="jenkinsSG"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 5000
      to_port = 5000
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Jenkins SG"
  }
}
resource "aws_security_group" "nexusSG" {
  name="nexusSG"
  ingress{
      from_port = 8081
      to_port = 8081
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress{
      from_port = 8081
      to_port = 8081
      protocol = "tcp"
      security_groups = [aws_security_group.jenkins_firewall.id]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = -1
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Nexus SG"
  }
}
resource "aws_security_group" "sonarqube_sg" {
 name="sonarqubeSG"
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
     cidr_blocks = ["0.0.0.0/0"]
 } 
 ingress{
     from_port = 80
     to_port = 80
     protocol = "tcp"
     security_groups  = [aws_security_group.jenkins_firewall.id]
 } 
 egress {
     from_port = 0
     to_port = 0
     protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
 }
 tags = {
    Name = "Sonarqube SG"
  }
}

resource "aws_security_group_rule" "jenkinsToSQ" {
  type = "ingress"
  from_port=80
  to_port = 80
  protocol = "tcp"
  source_security_group_id  = aws_security_group.sonarqube_sg.id
  security_group_id = aws_security_group.jenkins_firewall.id
}



module "jenkins"{
    source = "./Jenkins"
    jenkinsSG= aws_security_group.jenkins_firewall.id
}
module "nexus"{
    source = "./Nexus"
    nexusSG=aws_security_group.nexusSG.id
}
module "sonarqube"{
    source = "./Sonarqube"
    sonarqubeSG=aws_security_group.sonarqube_sg.id
}