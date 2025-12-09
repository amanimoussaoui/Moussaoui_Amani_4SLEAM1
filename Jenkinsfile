pipeline {
    agent any

    environment {
        DOCKER_USER = 'amounatahfouna'
        DOCKER_IMAGE_NAME = 'student-management'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REPO = "${DOCKER_USER}/${DOCKER_IMAGE_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/amanimoussaoui/Moussaoui_Amani_4SLEAM1.git', branch: 'main'
            }
        }

        stage('Setup') {
            steps {
                sh 'chmod +x mvnw'
            }
        }

        stage('Test') {
            steps {
                sh './mvnw clean test -Dspring.profiles.active=test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Vérifier que SonarQube est accessible
                    sh '''
                        echo "Vérification de SonarQube..."
                        curl -f http://localhost:9000/api/system/status || echo "SonarQube non accessible"
                    '''

                    // Attendre que SonarQube soit prêt
                    sleep 30
                }

                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "=== Analyse SonarQube ==="
                        ./mvnw sonar:sonar \
                          -Dsonar.projectKey=student-management \
                          -Dsonar.projectName="Student Management" \
                          -Dsonar.host.url=http://localhost:9000 \
                          -Dsonar.login=${SONAR_AUTH_TOKEN} \
                          -Dsonar.java.binaries=target/classes \
                          -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                    '''
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Package') {
            steps {
                sh './mvnw package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_REPO}:${DOCKER_IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_REPO}:${DOCKER_IMAGE_TAG} ${DOCKER_REPO}:latest"
                }
            }
        }

        stage('Login & Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"
                        sh "docker push ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}"
                        sh "docker push ${DOCKER_REPO}:latest"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ Pipeline succeeded!"
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}