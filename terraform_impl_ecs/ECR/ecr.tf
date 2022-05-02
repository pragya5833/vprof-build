resource "aws_ecr_repository" "contentShare"{
    # count=var.enable?1:0
    name=var.name
}
