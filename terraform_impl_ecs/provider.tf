provider "aws"{
    region="ap-south-1"
    profile="shavi"
}
terraform{
    backend "s3"{
        bucket="shavicontent"
        region="ap-south-1"
    }
}
