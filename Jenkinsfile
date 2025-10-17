pipeline{
	agent any
	
	parameter{
		string(branch: 'BRANCH', defaultValue: 'main', description: 'Git branch to build')
		choic(name: 'ENVIRONMEN', choices: ['dev','qa','prod'], description: 'Deployment environment')
		
	}
	
	environment {
		REPO_URL = 'https://github.com/rupeshgautam84/booking-services.git'
		DEPLOY_PATH = '/opt/myapp'
	}
	
	stages{
		
		stage('Checkout'){
			steps{
				echo "Checking out ${params.BRANCH}"
				git branch: "${params.BRANCH}",url: "{env.REPO_URL}"
		}
	}
	
	stage('Build'){
		steps{
			echo "Building Spring Boot JAR..."
			sh './gradlew clean build -x test'
		}
	}
	
	stage('Archive Artifact'){
		steps{
			echo "Archiving artifact..."
			archiveArtifacts artifacts: 'build/libs/*.jar',fingerprint: true
		}
	}
	
	stage('Deploy Locally'){
		steps{
			script{
				echo "Deploying locally to ${env.DEPLOY_PATH}"
				
				//Ensure deploy directory exsits
				sh "mkdir -p ${env.DEPLOY_PATH}"
				
				//Copy JAR file to deploy directory
				def jarFile = sh(script: "ls build/libs/*.jar | head -n 1", returnStdout: true).trim()
				sh "cp ${jarFile} ${env.DEPLOY_PATH}/app.jar"
				
				//Stop any running instance and start the new one
				
				sh """
					# Below line finds and kill all java apps that are not related 
					# pkill -f 'java -jar' || true
					
					#Safe command
					#pkill -f "${env.DEPLOY_PATH}/app.jar || true
					
					#Even better
					if [ -f ${env.DEPLOY_PATH}/app.pid ]; then
						kill \$(cat ${env.DEPLOY_PATH}/app.pid) || true
						rm -f $(env.DEPLOY_PATH)/app.pid
					fi
					
					#Start the new app and save its PID
					nohup java -jar ${env.DEPLOY_PATH}/app.jar > ${env.DEPLOY_PATH}/app.log 2 >&1 &
					echo \$! > ${env.DEPLOY_PATH}/app.pid
				"""	
				
				
			}
		}
	}
	
	
	success{
		echo "successfully deployed locally to ${env.DEPLOY_PATH}"
	}
	failure{
		echo "Build or deploy failed. Check Jenkins console output"
	}
	
	
	
	
	
}