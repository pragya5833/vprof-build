variable "name"{
    type=string
    default="mycontent"
}
variable "enable_module"{
    type=bool
    default=true
}
variable "AMIS" {
    type=map
    default={
    ap-south-1="ami-03ab8e59e04c7fdbb"
    us-east-1 = "ami-1924770e"
    us-west-2 = "ami-56ed4936"
    eu-west-1 = "ami-c8337dbb"
    }
}
variable "AWSREGION" {
  type=string
  default="ap-south-1"
}
variable "ECS_INSTANCE_TYPE"{
    type=string
    default="t2.micro"
}
variable "clusterName"{
    default="contentShare"
}