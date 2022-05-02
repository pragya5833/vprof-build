module "codeCommit"{
    source= "./Modules/codeCommit"
}
module "codeBuild"{
  source="./Modules/codeBuild"
  AWS_REGION=var.AWS_REGION
}
# code deploy
module "codeDeploy"{
    source="./Modules/codeDeploy"
    repository_url=var.repository_url
    AWS_REGION=var.AWS_REGION
    kms_arn= module.codeBuild.kms_arn
    s3cachebuck=module.codeBuild.s3cachebuck
    s3demobuck=module.codeBuild.s3demobuck
    s3demobucks=module.codeBuild.s3demobucks
}
# kms_arn= var.kms_arn
#   s3cachebuck=var.s3cachebuck
#   s3demobuck=var.s3demobuck
# code pipeline
module "codePipeline"{
    source="./Modules/codePipeline"
    repository_url=var.repository_url
    s3demobuck=module.codeBuild.s3demobuck
    kms_arn= module.codeBuild.kms_arn
    gitRepo=module.codeCommit.gitRepo
    codeBuildName=module.codeBuild.codeBuildName
    aws_codedeploy_app_name=module.codeDeploy.aws_codedeploy_app_name
    dgname=module.codeDeploy.dgname
    account_id=module.codeBuild.account_id
    ecs_task_definition=module.codeDeploy.ecs_task_definition
    demo-task-role=module.codeDeploy.demo-task-role
    s3demobucks=module.codeBuild.s3demobucks
}