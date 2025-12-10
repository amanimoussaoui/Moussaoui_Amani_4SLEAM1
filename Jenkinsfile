pipeline {
    agent any
    
    environment {
        // Variables d'environnement
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'amounatahfouna/student-management' // Remplacez par votre nom DockerHub
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(8)}"
        SONAR_HOST_URL = 'http://localhost:9000/' // Votre URL SonarQube
        SONAR_TOKEN = credentials('squ_38e48e8123b8ea0f9d934dbb05bfa277df42a84d') // Secret text dans Jenkins
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials' // Credentials Docker dans Jenkins
        GIT_BRANCH = 'main'
    }
    
    tools {
        // Outils nécessaires
        maven 'Maven-3.9.6'
        jdk 'JDK-17'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        retry(2)
    }
    
    stages {
        // STAGE 1: Checkout du code
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${GIT_BRANCH}"]],
                    extensions: [
                        [$class: 'CloneOption', depth: 1, timeout: 10],
                        [$class: 'CleanBeforeCheckout'],
                        [$class: 'LocalBranch', localBranch: '**']
                    ],
                    userRemoteConfigs: [[
                        url: 'https://github.com/amanimoussaoui/Moussaoui_Amani_4SLEAM1.git'
                    ]]
                ])
                
                script {
                    // Donner les permissions si mvnw existe
                    if (fileExists('mvnw')) {
                        sh 'chmod +x mvnw'
                    }
                    
                    // Afficher les informations de version
                    sh 'java -version'
                    sh 'mvn -version'
                }
            }
        }
        
        // STAGE 2: Préparation de l'environnement
        stage('Prepare Environment') {
            steps {
                script {
                    // Créer le fichier application-test.properties
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
        }
        
        // STAGE 3: Build et compilation
        stage('Build & Compile') {
            steps {
                script {
                    echo "🔨 Building application..."
                    sh '''
                        mvn clean compile -DskipTests \
                          -Denforcer.skip=true \
                          -Dcheckstyle.skip=true \
                          -Dpmd.skip=true \
                          -Dspotbugs.skip=true
                    '''
                    
                    // Vérifier la compilation
                    sh 'ls -la target/classes/'
                }
            }
        }
        
        // STAGE 4: Tests Unitaires avec JaCoCo
        stage('Unit Tests') {
            steps {
                script {
                    echo "🧪 Running unit tests with coverage..."
                    sh '''
                        mvn test \
                          -Dspring.profiles.active=test \
                          -DskipITs \
                          -DfailIfNoTests=false \
                          -Dtest=*Test,*Tests
                    '''
                    
                    // Générer le rapport JaCoCo
                    sh 'mvn jacoco:report'
                    
                    // Archiver les résultats des tests
                    junit 'target/surefire-reports/**/*.xml'
                    
                    // Archiver le rapport JaCoCo
                    publishHTML([
                        reportDir: 'target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'JaCoCo Coverage Report',
                        keepAll: true
                    ])
                }
            }
            
            post {
                always {
                    // Archiver les logs des tests
                    archiveArtifacts artifacts: 'target/surefire-reports/*.txt, target/surefire-reports/*.log', allowEmptyArchive: true
                }
            }
        }
        
        // STAGE 5: Tests d'Intégration (optionnel)
        stage('Integration Tests') {
            when {
                expression { params.RUN_INTEGRATION_TESTS == true }
            }
            steps {
                script {
                    echo "🔗 Running integration tests..."
                    sh '''
                        mvn verify \
                          -Dspring.profiles.active=test \
                          -Dit.test=*IT,*IntegrationTest \
                          -DskipUTs=false \
                          -DfailIfNoTests=false
                    '''
                    
                    // Archiver les résultats des tests d'intégration
                    junit 'target/failsafe-reports/**/*.xml'
                }
            }
        }
        
        // STAGE 6: Analyse SonarQube
        stage('SonarQube Analysis') {
            steps {
                script {
                    echo "📊 Running SonarQube analysis..."
                    
                    // Attendre que SonarQube soit prêt
                    sh 'sleep 30'
                    
                    // Exécuter l'analyse SonarQube
                    withSonarQubeEnv('SonarQube') {
                        sh """
                            mvn sonar:sonar \
                              -Dsonar.projectKey=student-management \
                              -Dsonar.projectName='Student Management System' \
                              -Dsonar.projectVersion=1.0.${BUILD_NUMBER} \
                              -Dsonar.sourceEncoding=UTF-8 \
                              -Dsonar.host.url=${SONAR_HOST_URL} \
                              -Dsonar.login=${SONAR_TOKEN} \
                              -Dsonar.java.coveragePlugin=jacoco \
                              -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                              -Dsonar.tests=src/test/java \
                              -Dsonar.test.inclusions=**/*Test.java,**/*Tests.java \
                              -Dsonar.qualitygate.wait=true
                        """
                    }
                }
            }
        }
        
        // STAGE 7: Quality Gate
        stage('Quality Gate') {
            steps {
                script {
                    echo "⚖️ Waiting for SonarQube Quality Gate..."
                    
                    timeout(time: 10, unit: 'MINUTES') {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "❌ Quality Gate failed: ${qg.status}"
                        }
                        echo "✅ Quality Gate passed: ${qg.status}"
                    }
                }
            }
        }
        
        // STAGE 8: Package JAR
        stage('Package Application') {
            steps {
                script {
                    echo "📦 Packaging application..."
                    
                    sh '''
                        mvn package \
                          -DskipTests \
                          -DskipITs \
                          -Dspring.profiles.active=prod \
                          -Denforcer.skip=true
                    '''
                    
                    // Vérifier que le JAR a été créé
                    sh 'ls -lh target/*.jar'
                    
                    // Archiver l'artefact
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        // STAGE 9: Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    
                    // Créer un Dockerfile s'il n'existe pas
                    if (!fileExists('Dockerfile')) {
                        sh '''
                            cat > Dockerfile << EOF
                            FROM eclipse-temurin:17-jdk-jammy AS builder
                            WORKDIR /app
                            COPY .mvn/ .mvn
                            COPY mvnw pom.xml ./
                            RUN chmod +x mvnw
                            RUN ./mvnw dependency:go-offline -B
                            COPY src ./src
                            RUN ./mvnw package -DskipTests
                            
                            FROM eclipse-temurin:17-jre-jammy
                            WORKDIR /app
                            COPY --from=builder /app/target/*.jar app.jar
                            EXPOSE 8080
                            ENTRYPOINT ["java", "-jar", "/app/app.jar"]
                            EOF
                        '''
                    }
                    
                    // Build de l'image Docker
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS_ID) {
                        def customImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}", "--pull --no-cache .")
                        
                        // Tagger aussi comme latest si c'est la branche main
                        if (env.GIT_BRANCH == 'main') {
                            customImage.push('latest')
                        }
                        customImage.push()
                    }
                }
            }
        }
        
        // STAGE 10: Push to DockerHub
        stage('Push to DockerHub') {
            steps {
                script {
                    echo "🚀 Pushing Docker image to DockerHub..."
                    
                    withCredentials([usernamePassword(
                        credentialsId: DOCKER_CREDENTIALS_ID,
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )]) {
                        sh """
                            docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD} ${DOCKER_REGISTRY}
                            docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                            
                            if [ "${GIT_BRANCH}" = "main" ]; then
                                docker push ${DOCKER_IMAGE}:latest
                            fi
                        """
                    }
                    
                    // Afficher les informations de l'image
                    sh "docker images | grep ${DOCKER_IMAGE}"
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Nettoyage Docker
                sh 'docker system prune -f || true'
                
                // Archiver les logs de build
                archiveArtifacts artifacts: '**/*.log, **/target/*.log', allowEmptyArchive: true
                
                // Enregistrer les informations de build
                currentBuild.description = "Build #${BUILD_NUMBER} - ${GIT_COMMIT.take(8)}"
            }
        }
        
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                echo "📊 SonarQube Report: ${SONAR_HOST_URL}/dashboard?id=student-management"
                echo "🐳 Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed!"
            }
        }
        
        cleanup {
            // Nettoyage final
            sh '''
                echo "🧹 Cleaning up workspace..."
                mvn clean || true
                rm -rf target/ node_modules/ || true
            '''
        }
    }
}
