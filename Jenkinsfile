pipeline {
    agent any

    environment {

        DOCKER_USER = 'amounatahfouna'
        DOCKER_PASS = 'Mayna123*'
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
                withSonarQubeEnv('SonarQube') {
                    sh './mvnw sonar:sonar -Dspring.profiles.active=test'
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
                sh './mvnw package -Dspring.profiles.active=test -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🏗️ Building Docker image..."
                    sh "docker build -t ${DOCKER_REPO}:${DOCKER_IMAGE_TAG} ."
                    sh "docker tag ${DOCKER_REPO}:${DOCKER_IMAGE_TAG} ${DOCKER_REPO}:latest"
                    echo "✅ Docker image built: ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}"

                    // Afficher les images créées
                    sh 'docker images | grep student-management'
                }
            }
        }

        stage('Test Docker Image Locally') {
            steps {
                script {
                    echo "🧪 Testing Docker image locally..."

                    // Arrêter tout conteneur existant
                    sh 'docker stop student-test-container || true'
                    sh 'docker rm student-test-container || true'

                    // Lancer le conteneur
                    sh "docker run -d --name student-test-container -p 8089:8089 ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}"

                    // Attendre que l'application démarre
                    sleep(30)

                    // Tester l'application
                    sh 'curl -f http://localhost:8089/actuator/health || exit 1'
                    echo "✅ Local Docker test passed!"

                    // Arrêter le conteneur de test
                    sh 'docker stop student-test-container'
                    sh 'docker rm student-test-container'
                }
            }
        }

        stage('Login to Docker Hub') {
            steps {
                script {
                    echo "🔐 Logging into Docker Hub..."
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                    echo "✅ Logged into Docker Hub as ${DOCKER_USER}"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    echo "🚀 Pushing Docker image to Docker Hub..."

                    // Pousser l'image avec le tag de build
                    sh "docker push ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}"

                    // Pousser l'image avec le tag 'latest'
                    sh "docker push ${DOCKER_REPO}:latest"

                    echo "✅ Image pushed to Docker Hub!"
                    echo "📦 Repository: https://hub.docker.com/r/${DOCKER_USER}/${DOCKER_IMAGE_NAME}"
                }
            }
        }

        stage('Cleanup') {
            steps {
                script {
                    echo "🧹 Cleaning up..."
                    // Supprimer les images locales pour économiser de l'espace
                    sh "docker rmi ${DOCKER_REPO}:${DOCKER_IMAGE_TAG} || true"
                    sh "docker rmi ${DOCKER_REPO}:latest || true"
                }
            }
        }
    }

    post {
        always {
            // Nettoyer l'espace de travail Jenkins
            cleanWs()

            // Nettoyer les conteneurs Docker qui pourraient rester
            sh 'docker ps -aq | xargs -r docker rm -f || true'
            sh 'docker images -f "dangling=true" -q | xargs -r docker rmi -f || true'
        }
        success {
            echo "🎉 Pipeline succeeded!"
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true

            // Afficher le lien vers l'image Docker Hub
            script {
                echo "📊 Build Summary:"
                echo "   - Build Number: ${env.BUILD_NUMBER}"
                echo "   - Docker Image: ${DOCKER_REPO}:${DOCKER_IMAGE_TAG}"
                echo "   - Docker Hub URL: https://hub.docker.com/r/${DOCKER_USER}/${DOCKER_IMAGE_NAME}"
            }
        }
        failure {
            echo "❌ Pipeline failed!"

            // Sauvegarder les logs Docker en cas d'échec
            script {
                sh 'docker logs student-test-container || true'
                sh 'docker ps -a || true'
            }
        }
    }
}