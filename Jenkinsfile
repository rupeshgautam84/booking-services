pipeline {
    agent any
    tools { maven 'Maven 3.8.7' }

    environment {
        REPO_URL = 'https://github.com/rupeshgautam84/booking-services.git'
        DEPLOY_PATH = '/opt/myapp'
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build and deploy')
        string(name: 'ENV', defaultValue: 'default', description: 'Environment to deploy (default, dev, prod)')
        string(name: 'PORT', defaultValue: '9090', description: 'Port for Spring Boot app')
        choice(name: 'ACTION', choices: ['start', 'stop'], description: 'Action to perform (start or stop the app)')
    }

    stages {
        stage('Verify Maven') {
            when { expression { params.ACTION == 'start' } }
            steps { sh 'mvn -v' }
        }

        stage('Checkout') {
            when { expression { params.ACTION == 'start' } }
            steps {
                echo "Checking out branch: ${params.BRANCH}"
                git branch: "${params.BRANCH}", url: "${env.REPO_URL}"
            }
        }

        stage('Build') {
            when { expression { params.ACTION == 'start' } }
            steps {
                echo "Building JAR..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Prepare Deploy') {
            when { expression { params.ACTION == 'start' } }
            steps {
                echo "Copying files to deployment directory and setting permissions..."
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

        stage('Deploy / Stop via SSH') {
            steps {
                script {
                    if (params.ACTION == 'start') {
                        echo "🚀 Starting application via SSH..."
                        sh """
                            ssh -o StrictHostKeyChecking=no jenkins@localhost \
                                "bash $DEPLOY_PATH/deploy_remote.sh start ${params.ENV} ${params.PORT}"
                        """
                    } else {
                        echo "🛑 Stopping application via SSH..."
                        sh """
                            ssh -o StrictHostKeyChecking=no jenkins@localhost \
                                "bash $DEPLOY_PATH/deploy_remote.sh stop"
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                if (params.ACTION == 'start') {
                    echo "✅ Application started successfully!"
                } else {
                    echo "✅ Application stopped successfully!"
                }
            }
        }
        failure {
            script {
                if (params.ACTION == 'start') {
                    echo "❌ Application start failed. Check Jenkins logs for details."
                } else {
                    echo "❌ Application stop failed. Check Jenkins logs for details."
                }
            }
        }
    }
}
