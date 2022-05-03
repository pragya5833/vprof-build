resource "aws_iam_role" "codeBuildRole" {
  name="codeBuildRole"
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect   = "Allow"
        Principal ={"Service": "codebuild.amazonaws.com"}
      }]
  })
  

}
resource "aws_iam_role_policy" "codeBuildRolePolicy" {
  name="codeBuildRolePolicy"
  role = aws_iam_role.codeBuildRole.name
  policy = jsonencode({
      Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "codecommit:Get*",
               "ssm:GetParameterHistory",
                "codecommit:BatchGet*",
                "codecommit:GitPull",
                "ssm:GetParameters",
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "ssm:GetParameter",
                "logs:CreateLogStream",
                "ec2:*",
                "ssm:GetParametersByPath",
                "codecommit:Describe*",
                "codecommit:BatchDescribe*",
                "codeartifact:AssociateExternalConnection",
                "codeartifact:CopyPackageVersions",
                "codeartifact:DeletePackageVersions",
                "codeartifact:DeleteRepository",
                "codeartifact:DeleteRepositoryPermissionsPolicy",
                "codeartifact:DescribePackageVersion",
                "codeartifact:DescribeRepository",
                "codeartifact:DisassociateExternalConnection",
                "codeartifact:DisposePackageVersions",
                "codeartifact:GetPackageVersionReadme",
                "codeartifact:GetRepositoryEndpoint",
                "codeartifact:ListPackageVersionAssets",
                "codeartifact:ListPackageVersionDependencies",
                "codeartifact:ListPackageVersions",
                "codeartifact:ListPackages",
                "codeartifact:PublishPackageVersion",
                "codeartifact:PutPackageMetadata",
                "codeartifact:PutRepositoryPermissionsPolicy",
                "codeartifact:ReadFromRepository",
                "codeartifact:UpdatePackageVersionsStatus",
                "codeartifact:UpdateRepository",
                "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }]
  })

}
# resource "aws_iam_policy_attachment" "tomcatCodeBuild" {
#   role= aws_iam_role.codeBuildRole.name
#   policy_arn = aws_iam_role_policy.codeBuildRolePolicy.arn
# }
resource "aws_cloudwatch_log_group" "tomcatCodeBuild" {
  name = "tomcatCodeBuild"
}
resource "aws_codebuild_project" "tomcat" {
  name="tomcat-build"
  service_role = aws_iam_role.codeBuildRole.arn
  source_version="master"
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
#   source {
#     type = "CODECOMMIT"
#     location="https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/tomcat"
#     buildspec = "buildspec.yml"
#   }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  logs_config {
    cloudwatch_logs{
        status="ENABLED"
        group_name=aws_cloudwatch_log_group.tomcatCodeBuild.name
        stream_name="tomcatCodeBuild"
    }
  }
}