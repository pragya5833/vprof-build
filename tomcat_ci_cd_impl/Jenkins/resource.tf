data "aws_ami" "jenkins_ami"{
    name_regex = "^Jenkins-"
    owners = ["self"]
    most_recent = true
    filter {
      name="name"
      values=["Jenkins-*"]
    }
}
data "aws_key_pair" "commonKey" {
  key_name = "ecs"
}
data "template_file" "jenkins_usedata" {
  template = "${file("/Users/pragyabharti/tfCourse/tomcat_ci_cd_impl/Jenkins/templates/jenkins.sh")}"
}
resource "aws_instance" "jenkins_instance" {
  ami = data.aws_ami.jenkins_ami.id
  instance_type = "t2.micro"
  user_data = data.template_file.jenkins_usedata.template
  vpc_security_group_ids = [var.jenkinsSG]
  key_name = data.aws_key_pair.commonKey.key_name
}