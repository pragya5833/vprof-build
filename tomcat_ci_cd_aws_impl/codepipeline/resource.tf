resource "random_string" "s3nameappend" {
  length  = 8
  special = false
  upper   = false
}
resource "aws_s3_bucket" "tomcatArtifacts" {
  bucket="tomcat-${random_string.s3nameappend.result}"
}

resource "aws_iam_role" "pipelineRole" {
  name="pipelineRole"
  assume_role_policy = jsonencode({
      Version="2012-10-17"
      Statement=[
          {
              Effect="Allow",
              Action=["sts:AssumeRole"],
              Principal={"Service": "codepipeline.amazonaws.com"}
          }
      ]
  })
}

resource "aws_iam_role_policy" "pipelineRole" {
  name="pipelineRole"
  role = aws_iam_role.pipelineRole.name
  policy = jsonencode({
      Version="2012-10-17"
      Statement=[
          {
              Effect="Allow",
              Action=[
                  "codecommit:*",
                  "codebuild:*",
                  "codeartifact:*",
                  "sns:*"
              ],
              Resource="*"
          },
          {
              Effect="Allow",
              Action=[
                  "s3:*",
              ],
              Resource=[
      "${aws_s3_bucket.tomcatArtifacts.arn}",
      "${aws_s3_bucket.tomcatArtifacts.arn}/*",
    ]
          }
      ]
  })
}
resource "aws_sns_topic" "tomcatPipeline" {
  name="tomcatPipeline"
}
resource "aws_sns_topic_subscription" "emailOnPipelineStatusChange" {
  topic_arn = aws_sns_topic.tomcatPipeline.arn
  protocol  = "email"
  endpoint  = "pragyabharti1312@gmail.com"
}

resource "aws_codepipeline" "tomcatapp" {
  name="tomcatapp"
  role_arn = aws_iam_role.pipelineRole.arn
  artifact_store {
    type = "S3"
    location = aws_s3_bucket.tomcatArtifacts.bucket 
  }
  stage {
   name="source"
   action {
     name = "source"
     category="Source"
     owner = "AWS"
     provider = "CodeCommit"
     version= "1"
     output_artifacts = ["demo-tomcat-source"]
     configuration= {
         RepositoryName=var.repoName
         BranchName=var.branchName
     }
   }
  }
  stage{
      name="build"
      action {
        name = "build"
        category="Build"
        owner = "AWS"
        provider = "CodeBuild"
        version= "1"
        input_artifacts = ["demo-tomcat-source"]
        output_artifacts = ["demo-tomcat-build"]
        configuration= {
            ProjectName=var.buildProject
        }
      }
  }
  stage{
      name="deploy"
      action {
        name="deploy"
        category="Deploy"
        version= "1"
        owner="AWS"
        provider="S3"
        input_artifacts = ["demo-tomcat-build"]
        # output_artifacts = [aws_s3_bucket.tomcatArtifacts.bucket]
        configuration= {
            BucketName= aws_s3_bucket.tomcatArtifacts.bucket
            Extract = "true"
        }
      }
  }
}
resource "aws_cloudwatch_event_rule" "pipeline_event_rule" {
  name = "tomcatApp"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codepipeline"
  ],
  "detail-type": [
    "CodePipeline Stage Execution State Change"
  ],
  "detail": {
    "state": [
      "SUCCEEDED",
      "FAILED"
    ],
    "pipeline": ["${aws_codepipeline.tomcatapp.name}"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "sns_event" {
  rule      = "${aws_cloudwatch_event_rule.pipeline_event_rule.name}"
  target_id = "SendToSNS"
  arn       = "${aws_sns_topic.tomcatPipeline.arn}"
}