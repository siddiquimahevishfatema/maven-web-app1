# Automated Java Web App CI/CD Pipeline on AWS EKS

This repository contains the end-to-end continuous integration and continuous deployment (CI/CD) pipeline for containerizing and deploying a Java-based web application to Amazon Elastic Kubernetes Service (AWS EKS).

---

## 🏗️ Architecture & Deployment Flow

[ Developer Push ] ➡️ [ GitHub ]
│
▼
[ Jenkins CI/CD ]
│
┌───────────────┴───────────────┐
▼                               ▼
(1) Maven Build                 (2) Docker Build & Push
│                               │
└───────────────┬───────────────┘
▼
[ Docker Hub Registry ]
│
▼
[ AWS EKS Cluster Deployment ]
│
▼
[ User Access via LoadBalancer ]


---

## 🧰 Prerequisites & Tech Stack

* **Cloud Provider:** Amazon Web Services (AWS EC2, EKS, IAM, VPC)
* **Build Tool:** Apache Maven 3.x, OpenJDK 17 / 21
* **Containerization:** Docker & Docker Hub (`mahevish07/maven-web-app`)
* **Orchestration:** Kubernetes (`kubectl`), AWS `eksctl`
* **CI/CD Automation:** Jenkins Server
* **Version Control:** Git & GitHub (`siddiquimahevishfatema/maven-web-app1`)

---

## 📁 Repository Structure

```text
├── src/                        # Java Application Source Code
├── pom.xml                     # Maven Dependency & Build Config
├── Dockerfile                  # Web App Containerization Specification
├── k8s-deploy.yml              # Kubernetes Deployment & LoadBalancer Service Manifests
├── Jenkinsfile                 # Jenkins Declarative CI/CD Pipeline
└── README.md                   # Technical Documentation
🚀 Step-by-Step Implementation Guide
Step 1: Provision EKS Management Host (EC2)
Launch an Ubuntu VM (t2.micro) on AWS and install management tools (kubectl, aws-cli, eksctl):

Bash
# Install kubectl
curl -o kubectl [https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl](https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl)
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin

# Install AWS CLI v2
sudo apt update && sudo apt install unzip -y
curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install eksctl
curl --silent --location "[https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname](https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname) -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
Step 2: IAM Role Assignment
Create an IAM Role named eksroleec2 with AdministratorAccess (for EC2 use case).

Attach eksroleec2 to both the EKS Management Host and the Jenkins Server via EC2 Security Settings.

Step 3: Provision EKS Cluster
Execute eksctl on the management host to create the node group and control plane:

Bash
eksctl create cluster \
  --name ashokit-cluster \
  --region us-east-1 \
  --node-type t2.medium \
  --zones us-east-1a,us-east-1b

# Verify node provisioning
kubectl get nodes
Step 4: Configure Jenkins & Build Engine
Launch an Ubuntu VM (t2.medium), open port 8080 in security group, and execute:

Bash
# Install Java 17
sudo apt update
sudo apt install fontconfig openjdk-17-jre -y

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key)
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
sudo systemctl enable --now jenkins

# Install Docker & Grant Permissions
curl -fsSL get.docker.com | /bin/bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Install AWS CLI & Kubectl on Jenkins Server
sudo apt install unzip -y
curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
curl -o kubectl [https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl](https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl) && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin
Step 5: Configure Jenkins Cluster Credentials
Connect Jenkins to EKS cluster by setting up permissions and generating kubeconfig:

Bash
# Update Kubeconfig for Jenkins
sudo mkdir -p /var/lib/jenkins/.kube
sudo aws eks update-kubeconfig --region us-east-1 --name ashokit-cluster --kubeconfig /var/lib/jenkins/.kube/config

# Grant ownership to Jenkins service user
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube

# Verify cluster connectivity as Jenkins user
sudo su -s /bin/bash jenkins -c "kubectl get nodes"
Step 6: CI/CD Pipeline Implementation
In Jenkins, navigate to Manage Jenkins -> Tools -> Maven Installation and name your Maven installation "maven". Store Docker Hub credentials as docker-credentials in Jenkins Credentials Manager.

Create a Pipeline project pointing to this repository using the standard Jenkinsfile:

Groovy
pipeline {
    agent any

    tools {
        maven "maven"
    }

    environment {
        DOCKER_HUB_USER = 'mahevish07'
        IMAGE_NAME      = 'maven-web-app'
        IMAGE_TAG       = "${BUILD_NUMBER}"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', url: '[https://github.com/siddiquimahevishfatema/maven-web-app1.git](https://github.com/siddiquimahevishfatema/maven-web-app1.git)'
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Docker Build & Tag') {
            steps {
                sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
            }
        }

        stage('Docker Registry Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS \vert{} docker login -u$DOCKER_USER --password-stdin'
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Kubernetes EKS Deploy') {
            steps {
                sh 'kubectl apply -f k8s-deploy.yml'
                sh 'kubectl rollout restart deployment/maven-web-app-deployment'
            }
        }
    }

    post {
        always {
            sh 'docker logout'
        }
    }
}
🌐 Application Verification & Teardown
Verify Live Service
Retrieve the LoadBalancer endpoint created by EKS:

Bash
kubectl get service
Access your application via browser:
http://<EXTERNAL-LB-DNS-NAME>/maven-app/

Clean Up Resources
To prevent unnecessary AWS charges, tear down the cluster once finished:

Bash
eksctl delete cluster --name ashokit-cluster --region us-east-1

---


