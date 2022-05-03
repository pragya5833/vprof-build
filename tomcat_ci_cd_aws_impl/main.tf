module "codecommit"{
    source="./codecommit"
}
module "codeartifact"{
    source="./codeartifact"
}
module "parameterstore"{
    # 7b7e54ea2534d9991b72647bbde64490013846ea
    source = "./ssm"
    sonarcloudURL=var.sonarcloudURL
    sonarToken=var.sonarToken
    sonarprojectkey=var.sonarprojectkey
    CODEARTIFACT_AUTH_TOKEN=var.CODEARTIFACT_AUTH_TOKEN
}
module "codebuild" {
  source = "./codebuild"
}
module "codepipeline" {
  source = "./codepipeline"
  repoName=module.codecommit.repo
  branchName="master"
  buildProject=module.codebuild.buildProject
}