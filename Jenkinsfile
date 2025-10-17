pipeline {
    tools { maven 'Maven 3.8.7' }

    agent any

    environment {
        REPO_URL    = 'https://github.com/rupeshgautam84/booking-services.git'
        DEPLOY_PATH = '/opt/myapp'
        CONFIG_PATH = "${DEPLOY_PATH}/config"
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'master', description: 'Branch to build and deploy')
        string(name: 'ENV', defaultValue: 'default', description: 'Environment/profile to deploy (default, local, dev, prod)')
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
                    # Create deploy/config directories
                    mkdir -p ${env.CONFIG_PATH}
                    chown jenkins:jenkins ${env.DEPLOY_PATH} -R

                    # Find latest JAR
                    latest_jar=\$(ls -t target/*.jar | head -n 1)
                    echo "Using JAR: \$latest_jar"
                    cp "\$latest_jar" ${env.DEPLOY_PATH}/app.jar

                    # Handle config file
                    if [ "${params.ENV}" = "default" ]; then
                        PROPERTIES_FILE="src/main/resources/application.properties"
                        echo "Copying default application.properties"
                    else
                        PROPERTIES_FILE="src/main/resources/application-${params.ENV}.properties"
                        echo "Copying environment-specific properties file: \$PROPERTIES_FILE"
                    fi

                    if [ -f \$PROPERTIES_FILE ]; then
                        cp \$PROPERTIES_FILE ${env.CONFIG_PATH}/application.properties
                        CONFIG_OPTION="--spring.config.location=file:${env.CONFIG_PATH}/application.properties"
                    else
                        echo "⚠️ Properties file \$PROPERTIES_FILE not found, using embedded application.properties"
                        CONFIG_OPTION=""
                    fi

                    # Stop previous app if running
                    if [ -f ${env.DEPLOY_PATH}/app.pid ]; then
                        kill \$(cat ${env.DEPLOY_PATH}/app.pid) || true
                        rm -f ${env.DEPLOY_PATH}/app.pid
                    fi

                    # Start Spring Boot app detached
                    nohup setsid java -jar ${env.DEPLOY_PATH}/app.jar \
                        \$CONFIG_OPTION \
                        --spring.profiles.active=${params.ENV} \
                        --server.port=${params.PORT} \
                        --logging.file.name=${env.DEPLOY_PATH}/app.log \
                        > ${env.DEPLOY_PATH}/nohup.out 2>&1 < /dev/null &

                    # Save PID
                    echo \$! > ${env.DEPLOY_PATH}/app.pid

                    # Wait for app to start
                    sleep 5

                    # Verify app
                    if ! ps -p \$(cat ${env.DEPLOY_PATH}/app.pid) > /dev/null; then
                        echo "❌ Deployment failed: Spring Boot app is not running!"
                        tail -n 50 ${env.DEPLOY_PATH}/app.log
                        exit 1
                    fi

                    echo "✅ Deployment verified: PID \$(cat ${env.DEPLOY_PATH}/app.pid), port ${params.PORT}, profile ${params.ENV}"
                """
            }
        }
    }

    post {
        success { echo "✅ Deployment completed successfully!" }
        failure { echo "❌ Deployment failed. Check Jenkins logs for details." }
    }
}
