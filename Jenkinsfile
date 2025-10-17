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

        # Copy the latest JAR (from Maven target folder)
        cp target/*.jar ${env.DEPLOY_PATH}/app.jar

        # Stop the previous app instance if it exists
        if [ -f ${env.DEPLOY_PATH}/app.pid ]; then
            kill \$(cat ${env.DEPLOY_PATH}/app.pid) || true
            rm -f ${env.DEPLOY_PATH}/app.pid
        fi

        # Start the new app in background using setsid and Spring Boot file logging
        setsid java -jar ${env.DEPLOY_PATH}/app.jar \
            --spring.profiles.active=default \
            --server.port=9090 \
            --logging.file.name=${env.DEPLOY_PATH}/app.log \
            > ${env.DEPLOY_PATH}/nohup.log 2>&1 < /dev/null &

        # Save the PID
        echo \$! > ${env.DEPLOY_PATH}/app.pid

        # Wait a few seconds for the app to start
        sleep 5

        # Verify the app is running by checking the PID
        if ! ps -p \$(cat ${env.DEPLOY_PATH}/app.pid) > /dev/null; then
            echo "❌ Deployment failed: Spring Boot app is not running!"
            tail -n 50 ${env.DEPLOY_PATH}/app.log
            exit 1
        fi

        echo "✅ Deployment verified: app is running with PID \$(cat ${env.DEPLOY_PATH}/app.pid)"
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
