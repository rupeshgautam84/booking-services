pipeline {
    tools {
        maven 'Maven 3.8.7'
    }

    agent any

    environment {
        REPO_URL    = 'https://github.com/rupeshgautam84/booking-services.git'
        DEPLOY_PATH = '/opt/myapp'
        CONFIG_PATH = "${DEPLOY_PATH}/config"
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
            mkdir -p ${env.DEPLOY_PATH}/config
            chown jenkins:jenkins ${env.DEPLOY_PATH} -R

            latest_jar=\$(ls -t target/*.jar | head -n 1)
            cp "\$latest_jar" ${env.DEPLOY_PATH}/app.jar

            if [ "${params.ENV}" != "default" ]; then
                cp src/main/resources/application-${params.ENV}.properties ${env.DEPLOY_PATH}/config/application.properties
            fi

            if [ -f ${env.DEPLOY_PATH}/app.pid ]; then
                kill \$(cat ${env.DEPLOY_PATH}/app.pid) || true
                rm -f ${env.DEPLOY_PATH}/app.pid
            fi

            nohup java -jar ${env.DEPLOY_PATH}/app.jar \
                --spring.profiles.active=${params.ENV} \
                --server.port=${params.PORT} \
                --spring.config.location=file:${env.DEPLOY_PATH}/config/application.properties \
                --logging.file.name=${env.DEPLOY_PATH}/app.log \
                > ${env.DEPLOY_PATH}/nohup.out 2>&1 &

            echo \$! > ${env.DEPLOY_PATH}/app.pid

            sleep 5

            if ! ps -p \$(cat ${env.DEPLOY_PATH}/app.pid) > /dev/null; then
                echo "❌ Deployment failed!"
                tail -n 50 ${env.DEPLOY_PATH}/app.log
                exit 1
            fi

            echo "✅ Deployment verified: PID \$(cat ${env.DEPLOY_PATH}/app.pid)"
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
