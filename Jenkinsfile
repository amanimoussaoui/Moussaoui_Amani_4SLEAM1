pipeline {
    agent any

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
        }

        stage('Package') {
            steps {
                sh './mvnw package -Dspring.profiles.active=test -DskipTests'
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
        }
        success {
            echo "✅ Build succeeded!"
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        failure {
            echo "❌ Build failed!"
        }
    }
}
