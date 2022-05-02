data "aws_key_pair" "commonKey" {
  key_name = "ecs"
}
data "template_file" "nexus_userdata" {
  template = "${file("/Users/pragyabharti/tfCourse/tomcat_ci_cd_impl/Sonarqube/templates/sonarqube_userdata.sh")}"
}
resource "aws_instance" "sonarqube_instance" {
  ami = "ami-0cfedf42e63bba657"
  instance_type = "t2.medium"
  user_data = data.template_file.nexus_userdata.template
  vpc_security_group_ids = [var.sonarqubeSG]
  key_name = data.aws_key_pair.commonKey.key_name
}