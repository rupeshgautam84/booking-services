pipeline {
    tools { maven 'Maven 3.8.7' }

    agent any

    environment {
        REPO_URL = 'https://github.com/rupeshgautam84/booking-services.git'
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build and deploy')
        string(name: 'ENV', defaultValue: 'default', description: 'Environment to deploy (default, local, dev, prod)')
        string(name: 'PORT', defaultValue: '9090', description: 'Port for Spring Boot app')
    }

    stages {
        stage('Verify Maven') {
            steps { sh 'mvn -v' }
        }

        stage('Checkout') {
            steps {
                echo "Checking out branch: ${params.BRANCH}"
                git branch: "${params.BRANCH}", url: "${env.REPO_URL}"
            }
        }

        stage('Build') {
            steps {
                echo "Building JAR..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Prepare Deployment Script') {
            steps {
                echo "Making deploy.sh executable"
                sh 'chmod +x ./deploy.sh'
            }
        }

        stage('Deploy') {
            steps {
                echo "Deploying application using deploy.sh"
                // Pass ENV and PORT to the script
                sh "./deploy.sh ${params.ENV} ${params.PORT} localhost"
            }
        }
    }

    post {
        success { echo "✅ Deployment completed successfully!" }
        failure { echo "❌ Deployment failed. Check Jenkins logs for details." }
    }
}
