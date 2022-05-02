A) For ECS
1) Create ecr repo and output url
2) Create Dockerfile
3) build dockerfile : docker build --platform=linux/amd64 -t 848417356303.dkr.ecr.ap-south-1.amazonaws.com/mycontent:5 .
4) push dockerfile to ecr: docker push 848417356303.dkr.ecr.ap-south-1.amazonaws.com/mycontent:5 
5) create ecs(only cluster name)
6) create iam role for ec2 (iamrole with assume role policy(ec2))
7) create iam instance profile
8) create iam role policy for ec2 to connect to ecs,ecr,cloudwatch
9) create security group to get connections from ssh and elb sg
10) create elb sg
11) create launch config with iam_instance_profile,ami,instance_type,sg,user_data to write:
    echo "ECS_CLUSTER_NAME=${clusterName}">/etc/ecs/ecs.config
12) create autoscaling group with launch config, max,min,desired
13) create elb with created sg for elb
14) create task definition reading tpl file:
    essential,portMappings,volumeMappings,link with other cont, image url, log driver set to cloudwatch,
    memory and CPU limits
15) create iam_role for service(ecs), create policy, attach policy to role
16) create service:
    cluster name, iam role,task definition, desired count,lb config
