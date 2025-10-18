pipeline {
    agent any
    tools { maven 'Maven 3.8.7' }

    environment {
        REPO_URL = 'https://github.com/rupeshgautam84/booking-services.git'
        DEPLOY_PATH = '/opt/myapp'
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build and deploy')
        choice(name: 'ACTION', choices: ['start', 'stop', 'status'], description: 'Action to perform: start, stop, or status')
        string(name: 'ENV', defaultValue: 'default', description: 'Environment to deploy (default, dev, prod)')
        string(name: 'PORT', defaultValue: '9090', description: 'Port for Spring Boot app')
    }

    stages {
        // Only run Maven verification if starting
        stage('Verify Maven') {
            when { expression { params.ACTION == 'start' } }
            steps { sh 'mvn -v' }
        }

        // Only checkout code if starting
        stage('Checkout') {
            when { expression { params.ACTION == 'start' } }
            steps {
                echo "Checking out branch: ${params.BRANCH}"
                git branch: "${params.BRANCH}", url: "${env.REPO_URL}"
            }
        }

        // Only build JAR if starting
        stage('Build') {
            when { expression { params.ACTION == 'start' } }
            steps {
                echo "Building JAR..."
                sh 'mvn clean package -DskipTests'
            }
        }

        // Only copy files if starting
        stage('Prepare Deploy') {
            when { expression { params.ACTION == 'start' } }
            steps {
                echo "Copying build artifacts and deployment script..."
                sh """
                    ssh -o StrictHostKeyChecking=no jenkins@localhost '
                        mkdir -p $DEPLOY_PATH/target
                        mkdir -p $DEPLOY_PATH/config
                        mkdir -p $DEPLOY_PATH/src/main/resources
                        chown -R jenkins:jenkins $DEPLOY_PATH
                    '

                    scp -o StrictHostKeyChecking=no target/*.jar jenkins@localhost:$DEPLOY_PATH/target/
                    scp -o StrictHostKeyChecking=no -r src/main/resources/*.properties jenkins@localhost:$DEPLOY_PATH/src/main/resources/ || true
                    scp -o StrictHostKeyChecking=no deploy/deploy_remote.sh jenkins@localhost:$DEPLOY_PATH/deploy_remote.sh
                    ssh -o StrictHostKeyChecking=no jenkins@localhost "chmod +x $DEPLOY_PATH/deploy_remote.sh"
                """
            }
        }

        // Always execute the action (start, stop, or status)
        stage('Execute Remote Action') {
            steps {
                echo "Running action: ${params.ACTION}"
                sh """
                    ssh -o StrictHostKeyChecking=no jenkins@localhost \
                        "bash $DEPLOY_PATH/deploy_remote.sh ${params.ACTION} ${params.ENV} ${params.PORT}"
                """
            }
        }
    }

    post {
        success { echo "✅ ${params.ACTION.toUpperCase()} action completed successfully!" }
        failure { echo "❌ ${params.ACTION.toUpperCase()} action failed. Check Jenkins logs for details." }
    }
}
