data "aws_ami" "nexus_ami" {
  name_regex = "^Nexus-"
    owners = ["self"]
    most_recent = true
    filter {
      name="name"
      values=["Nexus-*"]
    }
}
data "aws_key_pair" "commonKey" {
  key_name = "ecs"
}
data "template_file" "nexus_userdata" {
  template = "${file("/Users/pragyabharti/tfCourse/tomcat_ci_cd_impl/Nexus/templates/nexus.sh")}"
}
resource "aws_instance" "nexus_instance" {
  ami = "ami-0c6615d1e95c98aca"
  instance_type = "t2.small"
  user_data = data.template_file.nexus_userdata.template
  vpc_security_group_ids = [var.nexusSG]
  key_name = data.aws_key_pair.commonKey.key_name
}