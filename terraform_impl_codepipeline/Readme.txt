1) create code commit
2) create iam code codebuild
   iam role with assume role policy service codebuild
   create iam policy to pull from codecommit+
   push artifacts to s3
   push image to ecr
   ecr auth token to push to ecr
   push logs to cloudwatch
   as it requires ec2 environment to run build: ec2 related permissions
   kms as we store data encrypted in s3
3) codeDeploy