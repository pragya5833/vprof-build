terraform{
    backend "s3"{
        bucket="contentshareshavi"
        key="contents"
        region="ap-south-1"
    }
}
provider "aws"{
    region="ap-south-1"

}