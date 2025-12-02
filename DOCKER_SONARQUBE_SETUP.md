# 🐳 Configuration Docker et SonarQube

## 📋 Fichiers Créés

### 1. **Dockerfile** ✅
- Image basée sur `eclipse-temurin:17-jdk-alpine`
- Copie le JAR depuis `target/`
- Expose le port 8089
- Lance l'application Spring Boot

### 2. **Jenkinsfile** ✅ (Mis à jour)
- ✅ Étape SonarQube Analysis
- ✅ Quality Gate
- ✅ Build Docker Image
- ✅ Push Docker Image (optionnel)

### 3. **.dockerignore** ✅
- Exclut les fichiers inutiles de l'image Docker

### 4. **pom.xml** ✅ (Mis à jour)
- Plugin SonarQube Maven ajouté

## 🔧 Configuration Jenkins

### 1. Installer les Plugins Jenkins

Dans Jenkins → Manage Jenkins → Plugins, installer :
- **Docker Pipeline**
- **SonarQube Scanner**

### 2. Configurer SonarQube dans Jenkins

1. **Manage Jenkins** → **Configure System**
2. Section **SonarQube servers**
3. Ajouter un serveur SonarQube :
   - **Name**: `SonarQube` (doit correspondre au nom dans le Jenkinsfile)
   - **Server URL**: `http://localhost:9000` (ou votre URL SonarQube)
   - **Server authentication token**: Créer un token dans SonarQube

### 3. Créer un Token SonarQube

1. Se connecter à SonarQube
2. **My Account** → **Security** → **Generate Token**
3. Copier le token et l'ajouter dans Jenkins

### 4. Configurer Docker dans Jenkins

Assurez-vous que Docker est installé sur le serveur Jenkins :
```bash
# Vérifier Docker
docker --version

# Tester
docker ps
```

## 🚀 Utilisation

### Build Docker Image Localement

```bash
# Build l'application
./mvnw clean package -DskipTests

# Build l'image Docker
docker build -t student-management:latest .

# Lancer le conteneur
docker run -p 8089:8089 student-management:latest
```

### Avec Docker Compose (Optionnel)

Créer un fichier `docker-compose.yml` :

```yaml
version: '3.8'
services:
  student-management:
    build: .
    image: student-management:latest
    ports:
      - "8089:8089"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/studentdb
      - SPRING_DATASOURCE_USERNAME=root
      - SPRING_DATASOURCE_PASSWORD=password
    depends_on:
      - mysql
  
  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=password
      - MYSQL_DATABASE=studentdb
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

## 📊 Pipeline Jenkins - Étapes

1. **Checkout** : Clone le code depuis GitHub
2. **Setup** : Donne les permissions au Maven wrapper
3. **Test** : Exécute les tests avec H2
4. **SonarQube Analysis** : Analyse le code
5. **Quality Gate** : Vérifie que le code passe les critères de qualité
6. **Package** : Crée le JAR
7. **Build Docker Image** : Construit l'image Docker
8. **Push Docker Image** : Push vers un registry (optionnel)

## 🔍 Vérification

### Vérifier l'image Docker

```bash
docker images | grep student-management
```

### Vérifier les logs du conteneur

```bash
docker logs <container-id>
```

### Accéder à l'application

Une fois le conteneur lancé :
- Application: `http://localhost:8089/student`
- Swagger UI: `http://localhost:8089/student/swagger-ui.html`

## ⚙️ Variables d'Environnement Docker

Pour configurer l'application dans Docker, vous pouvez utiliser des variables d'environnement :

```bash
docker run -p 8089:8089 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://host.docker.internal:3306/studentdb \
  -e SPRING_DATASOURCE_USERNAME=root \
  -e SPRING_DATASOURCE_PASSWORD=password \
  student-management:latest
```

## 📝 Notes Importantes

1. **Port 8089** : Assurez-vous que le port 8089 est disponible
2. **MySQL** : Si vous utilisez MySQL, il doit être accessible depuis le conteneur
3. **SonarQube** : Le serveur SonarQube doit être démarré avant de lancer le pipeline
4. **Docker Registry** : Pour push l'image, décommentez la section dans le Jenkinsfile et configurez les credentials

## 🐛 Dépannage

### Erreur: "Cannot connect to Docker daemon"
```bash
# Vérifier que Docker est démarré
sudo systemctl status docker
sudo systemctl start docker
```

### Erreur: "SonarQube server not found"
- Vérifier que le nom dans Jenkinsfile correspond à la configuration Jenkins
- Vérifier que SonarQube est accessible depuis Jenkins

### Erreur: "Port 8089 already in use"
```bash
# Trouver le processus utilisant le port
lsof -i :8089
# Tuer le processus ou changer le port
```

---

**Le projet est maintenant prêt pour Docker et SonarQube! 🎉**

