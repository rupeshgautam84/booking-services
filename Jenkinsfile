pipeline {
    tools {
        maven 'Maven 3.8.7'
    }

    agent any

    environment {
        REPO_URL    = 'https://github.com/rupeshgautam84/booking-services.git'
        DEPLOY_PATH = '/opt/myapp'
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build and deploy')
        string(name: 'ENV', defaultValue: 'local', description: 'Environment/profile to deploy (local, dev, prod, default)')
        string(name: 'PORT', defaultValue: '9090', description: 'Port for Spring Boot app')
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
            steps {
                echo "Building Spring Boot JAR with Maven..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Archive Artifact') {
            steps {
                echo "Archiving build artifact..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Deploy') {
    steps {
        sh """
            # Create deploy directory if missing
            mkdir -p ${env.DEPLOY_PATH}
            chown jenkins:jenkins ${env.DEPLOY_PATH}

            # Show workspace info for debugging
            echo "Workspace: \$PWD"
            ls -l src/main/resources/

            # Find the latest JAR
            latest_jar=\$(ls -t target/*.jar | head -n 1)
            echo "Using JAR: \$latest_jar"
            cp "\$latest_jar" ${env.DEPLOY_PATH}/app.jar

            # Handle environment properties
            if [ "${params.ENV}" != "default" ]; then
                prop_file="src/main/resources/application-${params.ENV}.properties"
                if [ ! -f "\$prop_file" ]; then
                    echo "❌ Property file \$prop_file not found!"
                    exit 1
                fi
                cp "\$prop_file" ${env.DEPLOY_PATH}/application.properties
                config_option="--spring.config.location=file:${env.DEPLOY_PATH}/application.properties"
            else
                echo "Using embedded application.properties"
                config_option=""
            fi

            # Stop previous instance
            if [ -f ${env.DEPLOY_PATH}/app.pid ]; then
                kill \$(cat ${env.DEPLOY_PATH}/app.pid) || true
                rm -f ${env.DEPLOY_PATH}/app.pid
            fi

            # Start app in foreground (for reliable logging)
            echo "Starting Spring Boot app..."
            nohup java -jar ${env.DEPLOY_PATH}/app.jar \
                \$config_option \
                --spring.profiles.active=${params.ENV} \
                --server.port=${params.PORT} \
                --logging.file.name=${env.DEPLOY_PATH}/app.log \
                > ${env.DEPLOY_PATH}/nohup.log 2>&1 &

            # Save PID
            echo \$! > ${env.DEPLOY_PATH}/app.pid

            # Wait and check if app is running
            sleep 10
            if ! ps -p \$(cat ${env.DEPLOY_PATH}/app.pid) > /dev/null; then
                echo "❌ Deployment failed: app not running"
                echo "Last 50 lines from app.log:"
                tail -n 50 ${env.DEPLOY_PATH}/app.log
                exit 1
            fi

            echo "✅ Deployment verified: PID \$(cat ${env.DEPLOY_PATH}/app.pid), profile ${params.ENV}, port ${params.PORT}"
            echo "Check logs: ${env.DEPLOY_PATH}/app.log"
        """
    }
}

    }

    post {
        success {
            echo "✅ Deployment completed successfully!"
        }
        failure {
            echo "❌ Deployment failed. Check Jenkins logs for details."
        }
    }
}
