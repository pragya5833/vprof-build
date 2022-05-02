terraform{
    backend "s3" {
      region="ap-south-1"
      bucket="projvpproff"
      key="projvpprof"
    }
}
provider "aws" {
  region="ap-south-1"
}