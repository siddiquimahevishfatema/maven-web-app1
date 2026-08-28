pipeline {
    agent any
    
    tools {
        maven "maven"
    }
    stages {
        stage('Clone Repo') {
            steps {
              git branch: 'main', changelog: false, credentialsId: 'Git-Credentials', poll: false, url: 'https://github.com/siddiquimahevishfatema/maven-web-app'
            }
        }
        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            } 
        } 
        stage('Docker Image') {
            steps {
                sh 'docker build -t mahevish07/maven-web-app .'
            }
        }
        stage('k8s deployment') {
            steps {
                sh 'kubectl apply -f k8s-deploy.yml'
            }
        }
    } 
}
