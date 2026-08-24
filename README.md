# Java Web Application Deployment on AWS EKS via Jenkins CI/CD Pipeline

An end-to-end continuous integration and continuous deployment (CI/CD) pipeline that automates the build, containerization, and deployment of a Java Maven web application onto a managed Amazon EKS (Kubernetes) cluster.

---

## 🏗️ Architecture Overview

[ Developer / GitHub ]
│
▼ (Webhook / Manual Trigger)
[ Jenkins Server (AWS EC2) ]
│ ──▶ 1. Clone Code
│ ──▶ 2. Maven Build (.war)
│ ──▶ 3. Docker Build & Tag
│
├───▶ Push Image ────▶ [ Docker Hub Registry ]
│                                 │
└───▶ kubectl apply ─────────────┼──────┐
│      │ Pull Image
▼      ▼
[ AWS EKS Cluster ]
│
▼
[ AWS LoadBalancer ]
│
▼
[ End User ]


---

## 🛠️ Tech Stack & Prerequisites

* **Cloud Provider:** AWS (EC2, EKS, IAM, Elastic Load Balancer)
* **CI/CD Tool:** Jenkins
* **Containerization:** Docker & Docker Hub
* **Orchestration:** Kubernetes (`kubectl`, `eksctl`)
* **Build Tool:** Apache Maven
* **Source Code Management:** Git & GitHub
* **OS:** Ubuntu 22.04 LTS

---

## 🚀 Step-by-Step Implementation Guide

### Step 1: Provision EKS Management Host
1. Launch an Ubuntu EC2 Instance (`t3.small` recommended; minimum 2GB RAM).
2. Install `kubectl`, `awscli`, and `eksctl`:
   ```bash
   # Install kubectl
   curl -O [https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl](https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.0/2024-05-12/bin/linux/amd64/kubectl)
   chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin

   # Install AWS CLI v2
   sudo apt update && sudo apt install -y unzip
   curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
   unzip awscliv2.zip && sudo ./aws/install

   # Install eksctl
   curl --silent --location "[https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname](https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname) -s)_amd64.tar.gz" | tar xz -C /tmp
   sudo mv /tmp/eksctl /usr/local/bin
Step 2: Configure IAM Roles
Create an IAM Role named eksroleec2 with the AdministratorAccess policy (or scoped EKS/EC2 permissions).

Attach eksroleec2 to both the EKS Management Host and the Jenkins Server EC2 instances.

Step 3: Create EKS Cluster
Run the following command on the EKS Management Host:

Bash
eksctl create cluster \
  --name ashokit-cluster \
  --region us-east-1 \
  --node-type t3.medium \
  --nodes-min 2 \
  --nodes-max 2 \
  --zones us-east-1a,us-east-1b
Verify cluster nodes:

Bash
kubectl get nodes
Step 4: Setup Jenkins Server
Launch an Ubuntu EC2 Instance (t3.medium). Open ports 22 and 8080 in the Security Group.

Install Java 17, Jenkins, and Docker:

Bash
# Install Java & Jenkins
sudo apt update && sudo apt install -y openjdk-17-jre fontconfig
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key)
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update && sudo apt-get install -y jenkins

# Install Docker & Grant Permissions
curl -fsSL get.docker.com | bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
Install awscli and kubectl on the Jenkins server.

Authenticate Jenkins with the EKS cluster:

Bash
sudo -u jenkins aws eks update-kubeconfig --region us-east-1 --name ashokit-cluster
Step 5: Jenkins Dashboard & Credentials Setup
Access Jenkins at http://<JENKINS_PUBLIC_IP>:8080.

Install required plugins: Docker Pipeline, Kubernetes CLI, and Maven Integration.

Go to Manage Jenkins ➔ Tools ➔ Maven and add a Maven installation named maven.

Go to Manage Jenkins ➔ Credentials, create a Username with Password entry using your Docker Hub credentials, and set the ID to docker-credentials.

⚙️ Jenkinsfile Pipeline Configuration
Add this Jenkinsfile to your repository root or directly inside your Jenkins Pipeline job configuration:

Groovy
pipeline {
    agent any
    
    tools {
        maven "maven"
    }

    environment {
        DOCKER_IMAGE = 'ashher05/maven-web-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', url: '[https://github.com/Ashher05/maven-web-app.git](https://github.com/Ashher05/maven-web-app.git)'
            }
        }
        
        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            } 
        } 
        
        stage('Docker Build & Push') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG -t$DOCKER_IMAGE:latest .'
                        sh 'echo $PASS \vert{} docker login -u$USER --password-stdin'
                        sh 'docker push $DOCKER_IMAGE:$IMAGE_TAG'
                        sh 'docker push $DOCKER_IMAGE:latest'
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh 'kubectl apply -f k8s-deploy.yml'
                sh 'kubectl rollout restart deployment/maven-web-app'
            }
        }
    } 
}
🌐 Verifying Application Access
After a successful pipeline run, obtain the external LoadBalancer domain name from EKS:

Bash
kubectl get svc
Locate the EXTERNAL-IP associated with your deployment service.

Access your live application in your browser:
http://<EXTERNAL-IP>:8080/maven-web-app
