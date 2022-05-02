# module "ecr"{
#     source= "./ECR"
#     name=var.name
#     # enable=false
# }
module "ecs"{
    source="./ECS"
    AMIS=var.AMIS
    AWSREGION=var.AWSREGION
    ECS_INSTANCE_TYPE=var.ECS_INSTANCE_TYPE
    clusterName=var.clusterName
}
module "service"{
    source="./Service"
    REPOSITORY_URL="848417356303.dkr.ecr.ap-south-1.amazonaws.com/mycontent:5"
    elbSgid=module.ecs.elbSgid
    clusterName=module.ecs.clusterName
}