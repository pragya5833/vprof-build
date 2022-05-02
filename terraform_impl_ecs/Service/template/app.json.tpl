[
  {
    "essential": true,
    "memory": 256,
    "name": "myapp",
    "cpu": 256,
    "image": "848417356303.dkr.ecr.ap-south-1.amazonaws.com/mycontent:5",
    "workingDirectory": "/home/node/app",
    "command": ["npm", "start"],
    "portMappings": [
        {
            "containerPort": 4005,
            "hostPort": 4005
        }
    ],
    "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "awslogs-test",
                    "awslogs-region": "ap-south-1",
                    "awslogs-stream-prefix": "myapp"
                }
            }
  }
]