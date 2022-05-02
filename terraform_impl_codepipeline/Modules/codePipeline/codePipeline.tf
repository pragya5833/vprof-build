resource "aws_iam_role" "demo-task-codepipeline" {
  name = "demo-task-codepipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}
resource "aws_iam_role" "demo-codepipeline" {
  name = "demo-codepipeline"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

}
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "demo-codepipeline-role-policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      var.s3demobucks,
      "${var.s3demobucks}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:role/demo-codepipeline",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt",
    ]
    resources = [
      var.kms_arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codecommit:UploadArchive",
      "codecommit:Get*",
      "codecommit:BatchGet*",
      "codecommit:Describe*",
      "codecommit:BatchDescribe*",
      "codecommit:GitPull",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codedeploy:*",
      "ecs:*"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [ "*"
      # var.ecs_task_definition,
      # var.demo-task-role
    ]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "demo-codepipeline" {
  name   = "codepipeline-policy"
  #role   = aws_iam_role.demo-codepipeline.id
  policy = data.aws_iam_policy_document.demo-codepipeline-role-policy.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.demo-codepipeline.name
  policy_arn = aws_iam_policy.demo-codepipeline.arn
}
#
# codepipeline - demo
#
resource "aws_codepipeline" "demo" {
  name     = "demo-docker-pipeline"
  role_arn = aws_iam_role.demo-codepipeline.arn

  artifact_store {
    location = var.s3demobuck
    type     = "S3"
    encryption_key {
      id   = var.kms_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["demo-docker-source"]

      configuration = {
        RepositoryName = var.gitRepo
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["demo-docker-source"]
      output_artifacts = ["demo-docker-build"]
      version          = "1"

      configuration = {
        ProjectName = var.codeBuildName
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["demo-docker-build"]
      version         = "1"

      configuration = {
        ApplicationName                = var.aws_codedeploy_app_name
        DeploymentGroupName            = var.dgname
        TaskDefinitionTemplateArtifact = "demo-docker-build"
        AppSpecTemplateArtifact        = "demo-docker-build"
      }
    }
  }
}
