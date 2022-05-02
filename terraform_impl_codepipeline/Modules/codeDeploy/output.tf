output "aws_codedeploy_app_name" {
  value=aws_codedeploy_app.contentShare.name
}
output "dgname" {
  value=aws_codedeploy_deployment_group.demo.deployment_group_name
}
output "ecs_task_definition" {
  value=aws_ecs_task_definition.demo.arn
}
output "demo-task-role"{
    value=aws_iam_role.ecs-demo-task-role.arn
}