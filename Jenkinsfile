pipeline {
    agent any

    environment {
        DOCKER_USER = 'amounatahfouna'
        DOCKER_IMAGE_NAME = 'student-management'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        SONAR_HOST_URL = 'http://localhost:9000'
    }

    stages {
        stage('Checkout') {
            steps {
                // Utilisez 'main' OU 'testt' selon votre branche
                git branch: 'main', url: 'https://github.com/amanimoussaoui/Moussaoui_Amani_4SLEAM1.git'
                sh 'chmod +x mvnw'
            }
        }

        stage('Clean & Compile') {
            steps {
                sh './mvnw clean compile -DskipTests'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    // Vérifier que SonarQube est en cours d'exécution
                    echo "🔍 Vérification de SonarQube..."
                    sh '''
                        # Attendre que SonarQube démarre
                        sleep 30

                        # Tester la connexion
                        curl -s -f ${SONAR_HOST_URL}/api/system/status || echo "SonarQube pas encore prêt, continuation..."
                    '''
                }

                // Analyse SonarQube
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        echo "🔧 Exécution de l'analyse SonarQube..."
                        ./mvnw sonar:sonar \
                          -Dsonar.projectKey=student-management \
                          -Dsonar.projectName="Student Management" \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=${SONAR_AUTH_TOKEN} \
                          -Dsonar.sources=src/main/java \
                          -Dsonar.java.binaries=target/classes \
                          -Dsonar.java.source=17 \
                          -Dsonar.sourceEncoding=UTF-8 \
                          -DskipTests
                    '''
                }
            }
        }

        stage('Quality Gate Check') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage('Package') {
            steps {
                sh './mvnw package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                        docker tag ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:latest
                    """
                    echo "✅ Image Docker créée: ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    // Option 1: Si vous avez configuré les credentials dans Jenkins
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh """
                            echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                            docker push ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:latest
                        """
                    }

                    // Option 2: Si pas de credentials, juste afficher
                    // echo "📦 Image prête pour push: ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            echo "📊 Résumé du build #${env.BUILD_NUMBER}"
            echo "SonarQube: ${SONAR_HOST_URL}"
            echo "Docker Image: ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"

            // Nettoyage
            sh 'docker system prune -f 2>/dev/null || true'
            cleanWs()
        }
        success {
            echo "🎉 Pipeline réussi!"
            emailext (
                subject: "✅ Build réussi: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Le pipeline s'est terminé avec succès.\n\nDétails:\n- SonarQube: ${SONAR_HOST_URL}\n- Image Docker: ${DOCKER_USER}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}",
                to: 'votre-email@example.com'
            )
        }
        failure {
            echo "❌ Pipeline échoué!"
        }
        unstable {
            echo "⚠️  Quality Gate échouée mais pipeline continué"
        }
    }
}