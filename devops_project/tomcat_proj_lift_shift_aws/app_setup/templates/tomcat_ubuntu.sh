#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt install openjdk-8-jdk -y
sudo apt install tomcat8 tomcat8-admin tomcat8-docs tomcat8-common git -y
sudo apt-get install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
sudo apt install awscli -y
