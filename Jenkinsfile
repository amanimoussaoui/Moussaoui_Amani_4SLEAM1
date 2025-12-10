pipeline {
    agent any
    
    environment {
        // Variables d'environnement
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'amounatahfouna/student-management' // Remplacez par votre DockerHub
        DOCKER_TAG = "${BUILD_NUMBER}"
        SONAR_HOST_URL = 'http://localhost:9000/' // Votre SonarQube
        GIT_BRANCH = 'testt'
    }
    
    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        // STAGE 1: Checkout du code
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/amanimoussaoui/Moussaoui_Amani_4SLEAM1.git'
                sh 'chmod +x mvnw'
            }
        }
        
        // STAGE 2: Préparation de l'environnement
        stage('Prepare Environment') {
            steps {
                sh '''
                    mkdir -p src/test/resources
                    cat > src/test/resources/application-test.properties << 'EOF'
                    # Configuration H2 pour les tests
                    spring.datasource.url=jdbc:h2:mem:testdb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
                    spring.datasource.driver-class-name=org.h2.Driver
                    spring.datasource.username=sa
                    spring.datasource.password=
                    
                    # JPA Configuration
                    spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
                    spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect
                    spring.jpa.hibernate.ddl-auto=create-drop
                    spring.jpa.show-sql=false
                    
                    # Server
                    server.port=-1
                    
                    # OpenAPI
                    springdoc.api-docs.enabled=false
                    springdoc.swagger-ui.enabled=false
                    
                    # Logging
                    logging.level.root=WARN
                    EOF
                '''
            }
        }
        
        // STAGE 3: Build et compilation
        stage('Build') {
            steps {
                sh '''
                    # Installer Maven si nécessaire
                    if ! command -v mvn &> /dev/null; then
                        echo "Maven not found, using ./mvnw"
                        ./mvnw clean compile -DskipTests
                    else
                        mvn clean compile -DskipTests
                    fi
                '''
            }
        }
        
        // STAGE 4: Tests Unitaires
        stage('Test') {
            steps {
                sh '''
                    if ! command -v mvn &> /dev/null; then
                        ./mvnw test -Dspring.profiles.active=test
                    else
                        mvn test -Dspring.profiles.active=test
                    fi
                '''
                junit 'target/surefire-reports/**/*.xml'
            }
        }
        
        // STAGE 5: Coverage JaCoCo
        stage('Coverage Report') {
            steps {
                sh '''
                    if ! command -v mvn &> /dev/null; then
                        ./mvnw jacoco:report
                    else
                        mvn jacoco:report
                    fi
                '''
                publishHTML([
                    reportDir: 'target/site/jacoco',
                    reportFiles: 'index.html',
                    reportName: 'JaCoCo Coverage Report'
                ])
            }
        }
        
        // STAGE 6: Analyse SonarQube
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Attendre que SonarQube soit prêt
                    sh 'sleep 10'
                    
                    // Utiliser le token SonarQube depuis les credentials
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                            if ! command -v mvn &> /dev/null; then
                                ./mvnw sonar:sonar \
                                  -Dsonar.projectKey=student-management \
                                  -Dsonar.projectName='Student Management System' \
                                  -Dsonar.host.url=${SONAR_HOST_URL} \
                                  -Dsonar.login=${SONAR_TOKEN} \
                                  -Dsonar.java.coveragePlugin=jacoco \
                                  -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                            else
                                mvn sonar:sonar \
                                  -Dsonar.projectKey=student-management \
                                  -Dsonar.projectName='Student Management System' \
                                  -Dsonar.host.url=${SONAR_HOST_URL} \
                                  -Dsonar.login=${SONAR_TOKEN} \
                                  -Dsonar.java.coveragePlugin=jacoco \
                                  -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                            fi
                        """
                    }
                }
            }
        }
        
        // STAGE 7: Quality Gate
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        // STAGE 8: Package
        stage('Package') {
            steps {
                sh '''
                    if ! command -v mvn &> /dev/null; then
                        ./mvnw package -DskipTests
                    else
                        mvn package -DskipTests
                    fi
                '''
                archiveArtifacts 'target/*.jar'
            }
        }
        
        // STAGE 9: Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    // Créer un Dockerfile simple
                    sh '''
                        cat > Dockerfile << 'EOF'
                        FROM eclipse-temurin:17-jre-jammy
                        WORKDIR /app
                        COPY target/*.jar app.jar
                        EXPOSE 8080
                        ENTRYPOINT ["java", "-jar", "/app/app.jar"]
                        EOF
                    '''
                    
                    // Build l'image Docker
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                }
            }
        }
        
        // STAGE 10: Push to DockerHub
        stage('Push to DockerHub') {
            steps {
                script {
                    // Utiliser les credentials DockerHub
                    withCredentials([usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            docker login -u $DOCKER_USER -p $DOCKER_PASS
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Nettoyage
            sh 'docker system prune -f || true'
            cleanWs()
        }
        success {
            echo "✅ Pipeline completed successfully!"
            echo "🐳 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            echo "📊 SonarQube: ${SONAR_HOST_URL}/dashboard?id=student-management"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
