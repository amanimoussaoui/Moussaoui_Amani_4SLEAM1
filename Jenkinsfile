pipeline {
    agent any
    
    environment {
        // Variables d'environnement
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE = 'amounatahfouna/student-management1'
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(8)}"
        SONAR_HOST_URL = 'http://sonarqube:9000' // ou votre URL SonarQube
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
                        url: 'https://github.com/amanimoussaoui/Moussaoui_Amani_4SLEAM1.git',
                        credentialsId: 'github-credentials' // Si privé
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
                    // Créer le fichier application-test.properties si nécessaire
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
        
        // STAGE 5: Tests d'Intégration
        stage('Integration Tests') {
            when {
                expression { !env.SKIP_INTEGRATION_TESTS }
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
                    
                    // Préparer le rapport JaCoCo pour Sonar
                    sh '''
                        mvn jacoco:report-aggregate
                        mvn jacoco:report -Daggregate=true
                    '''
                    
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
                              -Dsonar.qualitygate.wait=true \
                              -Dsonar.scm.disabled=true
                        """
                    }
                    
                    // Vérifier que le rapport JaCoCo a été généré
                    sh 'ls -la target/site/jacoco/ || true'
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
                            cat > Dockerfile << 'EOF'
                            # Multi-stage build pour une image plus petite
                            FROM eclipse-temurin:17-jdk-jammy AS builder
                            WORKDIR /app
                            COPY .mvn/ .mvn
                            COPY mvnw pom.xml ./
                            RUN chmod +x mvnw
                            RUN ./mvnw dependency:go-offline -B
                            COPY src ./src
                            RUN ./mvnw package -DskipTests
                            
                            # Runtime image
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
                    
                    // Nettoyer les images locales
                    sh 'docker system prune -f || true'
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
            
            post {
                success {
                    script {
                        // Envoyer une notification avec le tag
                        echo "✅ Docker image pushed: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        
                        // Créer une release note
                        writeFile file: 'release-notes.md', text: """
                        # Release ${BUILD_NUMBER}
                        
                        ## Student Management System
                        
                        **Build:** ${BUILD_NUMBER}
                        **Commit:** ${GIT_COMMIT.take(8)}
                        **Branch:** ${GIT_BRANCH}
                        **Docker Image:** ${DOCKER_IMAGE}:${DOCKER_TAG}
                        **SonarQube:** ${SONAR_HOST_URL}/dashboard?id=student-management
                        
                        ### Changes:
                        - Build automatique via Jenkins
                        - Tests avec couverture JaCoCo
                        - Analyse qualité SonarQube
                        - Image Docker publiée
                        
                        ### Usage:
                        \`\`\`bash
                        docker pull ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker run -p 8080:8080 ${DOCKER_IMAGE}:${DOCKER_TAG}
                        \`\`\`
                        """
                    }
                }
            }
        }
        
        // STAGE 11: Deploy to Kubernetes (Optionnel)
        stage('Deploy to Kubernetes') {
            when {
                expression { env.DEPLOY_TO_K8S == 'true' }
            }
            steps {
                script {
                    echo "☸️ Deploying to Kubernetes..."
                    
                    // Créer les fichiers Kubernetes s'ils n'existent pas
                    if (!fileExists('k8s-deployment.yaml')) {
                        sh '''
                            cat > k8s-deployment.yaml << 'EOF'
                            apiVersion: apps/v1
                            kind: Deployment
                            metadata:
                              name: student-management
                              labels:
                                app: student-management
                            spec:
                              replicas: 2
                              selector:
                                matchLabels:
                                  app: student-management
                              template:
                                metadata:
                                  labels:
                                    app: student-management
                                spec:
                                  containers:
                                  - name: student-management
                                    image: YOUR_DOCKER_IMAGE:TAG
                                    ports:
                                    - containerPort: 8080
                                    env:
                                    - name: SPRING_PROFILES_ACTIVE
                                      value: "prod"
                                    resources:
                                      requests:
                                        memory: "256Mi"
                                        cpu: "100m"
                                      limits:
                                        memory: "512Mi"
                                        cpu: "500m"
                                    livenessProbe:
                                      httpGet:
                                        path: /actuator/health
                                        port: 8080
                                      initialDelaySeconds: 60
                                      periodSeconds: 10
                                    readinessProbe:
                                      httpGet:
                                        path: /actuator/health/readiness
                                        port: 8080
                                      initialDelaySeconds: 30
                                      periodSeconds: 5
                            ---
                            apiVersion: v1
                            kind: Service
                            metadata:
                              name: student-management-service
                            spec:
                              selector:
                                app: student-management
                              ports:
                              - port: 8080
                                targetPort: 8080
                              type: LoadBalancer
                            EOF
                            
                            # Remplacer le placeholder
                            sed -i "s|YOUR_DOCKER_IMAGE:TAG|${DOCKER_IMAGE}:${DOCKER_TAG}|g" k8s-deployment.yaml
                        '''
                    }
                    
                    // Déployer sur Kubernetes (si kubectl est configuré)
                    sh '''
                        kubectl apply -f k8s-deployment.yaml || echo "Kubernetes deployment skipped"
                        kubectl rollout status deployment/student-management --timeout=300s || true
                    '''
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
                
                // Notification de succès
                emailext(
                    subject: "✅ Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <h2>Build Success!</h2>
                    <p><strong>Project:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                    <p><strong>Status:</strong> SUCCESS</p>
                    <p><strong>Commit:</strong> ${env.GIT_COMMIT.take(8)}</p>
                    <p><strong>Branch:</strong> ${env.GIT_BRANCH}</p>
                    <p><strong>Docker Image:</strong> ${DOCKER_IMAGE}:${DOCKER_TAG}</p>
                    <p><strong>SonarQube:</strong> <a href="${SONAR_HOST_URL}/dashboard?id=student-management">View Report</a></p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    """,
                    to: 'dev-team@example.com',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
        
        failure {
            script {
                echo "❌ Pipeline failed!"
                
                // Notification d'échec
                emailext(
                    subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                    body: """
                    <h2>Build Failed!</h2>
                    <p><strong>Project:</strong> ${env.JOB_NAME}</p>
                    <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                    <p><strong>Status:</strong> FAILED</p>
                    <p><strong>Commit:</strong> ${env.GIT_COMMIT.take(8)}</p>
                    <p><strong>Branch:</strong> ${env.GIT_BRANCH}</p>
                    <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                    <p><strong>Console Output:</strong> <a href="${env.BUILD_URL}console">View Logs</a></p>
                    """,
                    to: 'dev-team@example.com',
                    recipientProviders: [[$class: 'DevelopersRecipientProvider']]
                )
            }
        }
        
        unstable {
            echo "⚠️ Pipeline is unstable (tests failed but not critical)"
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
