output "kms_arn"{
    value= aws_kms_key.demo-artifacts.arn
}
output "s3cachebuck" {
  value=aws_s3_bucket.codebuild-cache.arn
}
output "s3demobucks" {
  value=aws_s3_bucket.demo-artifacts.arn
}
output "s3demobuck" {
  value=aws_s3_bucket.demo-artifacts.bucket
}
output "codeBuildName" {
  value=aws_codebuild_project.contentShare.name
}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}
