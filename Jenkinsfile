pipeline {
    agent {
        node {
            label 'maven'
        }
    }
environment {
    PATH = "/opt/apache-maven-3.8.9/bin:$PATH"
    (SONAR_TOKEN = credentials('SONAR_TOKEN'))
    AWS_REGION = 'us-east-1'
    S3_BUCKET = 'my-war-bucket'
    ECR_REPO = '642391958117.dkr.ecr.us-east-1.amazonaws.com/taxi-booking-app'
    IMAGE_TAG = "v1.${BUILD_NUMBER}"
    
}
   stages {
        stage("build"){
            steps {
                 echo "----------- build started ----------"
                sh 'mvn package'
                 echo "----------- build complted ----------"
            }
        }
        stage("test"){
            steps{
                echo "----------- unit test started ----------"
                sh 'mvn surefire-report:report'
                 echo "----------- unit test Complted ----------"
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Run SonarQube analysis
                    sh """
                    mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                    -Dsonar.projectKey=taxi-app-taxi-app_taxi \
                    -Dsonar.organization=taxi-app-taxi-app \
                    -Dsonar.host.url=https://sonarcloud.io \
                    -Dsonar.token=${SONAR_TOKEN}
                    """
                }
            }
        }
        stage('Upload WAR to S3') {
            steps {
                sh '''
                aws s3 cp taxi-booking/target/*.war s3://$S3_BUCKET/
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t my-app:${IMAGE_TAG} .
                '''
            }
        }
        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin $ECR_REPO
                '''
            }
        }

        stage('Tag Image') {
            steps {
                sh '''
                docker tag my-app:${IMAGE_TAG} $ECR_REPO:${IMAGE_TAG}
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                docker push $ECR_REPO:${IMAGE_TAG}
                '''
            }
        }
        stage(" Deploy ") {
            steps {
            script {
                sh 'chmod +x deploy.sh'
                sh './deploy.sh'
                }
            }
        }
    }
}
