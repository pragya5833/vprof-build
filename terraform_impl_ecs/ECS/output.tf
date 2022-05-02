output "clusterName" {
  value=aws_ecs_cluster.contentShare.name
}
output "elbSgid" {
  value=aws_security_group.myapp-elb-securitygroup.id
}