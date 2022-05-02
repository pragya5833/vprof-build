#! /bin/bash

systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins