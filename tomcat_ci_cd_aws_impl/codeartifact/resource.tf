resource "aws_codeartifact_domain" "tomcat" {
  domain         = "tomcat"
#   encryption_key = aws_kms_key.example.arn
}
resource "aws_codeartifact_repository" "upstream" {
  repository = "upstream"
  domain     = aws_codeartifact_domain.tomcat.domain
}
resource "aws_codeartifact_repository" "tomcat" {
  repository = "tomcat"
  domain     = aws_codeartifact_domain.tomcat.domain
  external_connections {
    external_connection_name = "public:maven-central"
  }
}