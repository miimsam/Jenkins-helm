##### Overview

- The following steps should be Manually handled:
  - The Kubectl configuration for the created EKS cluster should be defined in Jenkins instance:
  (Ref: Kubernetes plugin https://github.com/jenkinsci/kubernetes-plugin).
  - Below secrets needs to be defined as well:
        `jenkins-docker-password` : Docker repository password
        `jenkins-helm-password` : Helm repository password


##### How it works?

- This repository contains:
  - A [Dockerfile](SimpleApp/Dockerfile) to build a simple Tomcat [application](https://tomcat.apache.org/tomcat-8.0-doc/appdev/sample/) by serving a war [file](SimpleApp/sample.war).
  - A helm [chart](App-chart/Chart.yaml) to package our application and make it ready to deploy on EKS cluster.
  - A [Jenkinsfile](./Jenkinsfile) which is our CI/CD and declares a few steps to build, test and deploy our application.
  - A Shell [script](build.sh) to handle the build and push functions with stated parameters from Jenkinsfile.