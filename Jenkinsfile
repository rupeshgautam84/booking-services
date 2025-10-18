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
        // Only needed for 'start'
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
                echo "Copying build artifacts and deployment scripts..."
                sh """
                    ssh -o StrictHostKeyChecking=no jenkins@localhost '
                        mkdir -p $DEPLOY_PATH/target
                        mkdir -p $DEPLOY_PATH/config
                        mkdir -p $DEPLOY_PATH/src/main/resources
                        chown -R jenkins:jenkins $DEPLOY_PATH
                    '

                    scp -o StrictHostKeyChecking=no target/*.jar jenkins@localhost:$DEPLOY_PATH/target/
                    scp -o StrictHostKeyChecking=no -r src/main/resources/*.properties jenkins@localhost:$DEPLOY_PATH/src/main/resources/ || true
                    scp -o StrictHostKeyChecking=no deploy_start.sh jenkins@localhost:$DEPLOY_PATH/deploy_start.sh
                    scp -o StrictHostKeyChecking=no deploy_control.sh jenkins@localhost:$DEPLOY_PATH/deploy_control.sh
                    scp -o StrictHostKeyChecking=no deploy_remote.sh jenkins@localhost:$DEPLOY_PATH/deploy_remote.sh
                    ssh -o StrictHostKeyChecking=no jenkins@localhost "chmod +x $DEPLOY_PATH/deploy_*.sh"
                """
            }
        }

        stage('Execute Remote Action') {
            steps {
                echo "Running action: ${params.ACTION}"
                script {
                    if (params.ACTION == 'start') {
                        sh """
                            ssh -o StrictHostKeyChecking=no jenkins@localhost \
                                "bash $DEPLOY_PATH/deploy_start.sh ${params.ENV} ${params.PORT}"
                        """
                    } else if (params.ACTION == 'stop' || params.ACTION == 'status') {
                        sh """
                            ssh -o StrictHostKeyChecking=no jenkins@localhost \
                                "bash $DEPLOY_PATH/deploy_control.sh ${params.ACTION}"
                        """
                    } else {
                        error "Unknown ACTION: ${params.ACTION}"
                    }
                }
            }
        }
    }

    post {
        success { echo "✅ ${params.ACTION.toUpperCase()} action completed successfully!" }
        failure { echo "❌ ${params.ACTION.toUpperCase()} action failed. Check Jenkins logs for details." }
    }
}
