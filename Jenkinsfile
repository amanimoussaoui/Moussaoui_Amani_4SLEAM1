pipeline {
    agent any

    environment {
        DOCKER_USER = 'amounatahfouna'
        DOCKER_IMAGE_NAME = 'student-management'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REPO = "${DOCKER_USER}/${DOCKER_IMAGE_NAME}"
        SPRING_PROFILES_ACTIVE = 'test'  # ⬅️ AJOUTER VARIABLE
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
                // Vérifier la configuration
                sh '''
                    echo "=== Vérification configuration test ==="
                    ls -la src/test/resources/ || echo "Dossier test resources non trouvé"
                    cat src/test/resources/application-test.properties 2>/dev/null || echo "Création du fichier de config..."

                    # Créer si absent
                    mkdir -p src/test/resources
                    cat > src/test/resources/application-test.properties << EOF
                    spring.datasource.url=jdbc:h2:mem:testdb
                    spring.datasource.driver-class-name=org.h2.Driver
                    spring.datasource.username=sa
                    spring.datasource.password=
                    spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
                    spring.jpa.hibernate.ddl-auto=create-drop
                    EOF
                '''
            }
        }

        stage('Test') {
            steps {
                sh "./mvnw clean test -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}"
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
                    sh '''
                        echo "Vérification de SonarQube..."
                        curl -s -f http://localhost:9000/api/system/status || echo "SonarQube non accessible, attente..."
                        sleep 30
                    '''
                }
                withSonarQubeEnv('SonarQube') {
                    sh "./mvnw sonar:sonar -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}"
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
                sh "./mvnw package -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} -DskipTests"
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