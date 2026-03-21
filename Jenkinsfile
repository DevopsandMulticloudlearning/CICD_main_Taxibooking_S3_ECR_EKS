def registry = 'https://taxiappj7.jfrog.io/artifactory'
def imageName = 'taxiappj7.jfrog.io/taxiapp-docker-local/taxiapp'
def version   = '1.0.1'
pipeline {
    agent {
        node {
            label 'maven'
        }
    }
environment {
    PATH = "/opt/apache-maven-3.8.9/bin:$PATH"
    (SONAR_TOKEN = credentials('SONAR_TOKEN'))
    
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
        stage("Jar Publish") {
        steps {
            script {
                    echo '<----------- The Jar Publish Started --------------->'
                     def server = Artifactory.newServer url:registry,  credentialsId:"jfrog-cred"
                     def properties = "buildid=${env.BUILD_ID},commitid=${GIT_COMMIT}";
                     def uploadSpec = """{
                          "files": [
                            {
                              "pattern": "/home/ubuntu/jenkins/workspace/taxi-booking/taxi-booking/target/(*)",
                              "target": "taxiapp-libs-release-local/{1}",
                              "flat": "false",
                              "props" : "${properties}",
                              "exclusions": [ "*.sha1", "*.md5"]
                            }
                         ]
                     }"""
                     def buildInfo = server.upload(uploadSpec)
                     buildInfo.env.collect()
                     server.publishBuildInfo(buildInfo)
                     echo '<------------ Jar Publish Ended --------------->'  
             }
        }   
    }
    stage(" Docker Build ") {
      steps {
        script {
           echo '<--------------- Docker Build Started --------------->'
           app = docker.build("${imageName}:${version}")
           echo '<--------------- Docker Build Ends --------------->'
        }
      }
    }
     stage (" Docker Publish "){
        steps {
            script {
               echo '<--------------- Docker Publish Started --------------->'  
                docker.withRegistry(registry, 'jfrog-cred'){
                    app.push()
                }    
               echo '<--------------- Docker Publish Ended --------------->'  
            }
        }
    }
}
}
