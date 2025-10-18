pipeline {
    agent any

    tools { 
        maven 'Maven 3.8.7' 
    }

    environment {
        REPO_URL    = 'https://github.com/rupeshgautam84/booking-services.git'
        DEPLOY_DIR  = '/opt/myapp'
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build and deploy')
        string(name: 'ENV', defaultValue: 'default', description: 'Environment to deploy (default, local, dev, prod)')
        string(name: 'PORT', defaultValue: '9090', description: 'Port for Spring Boot app')
        choice(name: 'ACTION', choices: ['start','stop'], description: 'Start or stop the app')
    }

    stages {
        stage('Verify Maven') {
            steps {
                sh 'mvn -v'
            }
        }

        stage('Checkout') {
            steps {
                echo "Checking out branch: ${params.BRANCH}"
                git branch: "${params.BRANCH}", url: "${env.REPO_URL}"
            }
        }

        stage('Build') {
            when { expression { params.ACTION == 'start' } } // Only build if starting
            steps {
                echo "Building Spring Boot JAR..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Deploy') {
            steps {
                echo "Running deploy_remote.sh with action: ${params.ACTION}"
                sh """
                    # Ensure deploy script is executable
                    chmod +x ./deploy/deploy_remote.sh
                    # Execute script with action, environment, and port
                    ./deploy/deploy_remote.sh ${params.ACTION} ${params.ENV} ${params.PORT}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment pipeline finished successfully!"
        }
        failure {
            echo "❌ Deployment pipeline failed. Check logs for details."
        }
    }
}
