# Student Management System

Système de gestion des étudiants avec Spring Boot, JPA, et MySQL/H2.

## Structure du Projet

- **Entities**: Student, Department, Course, Enrollment, Status (enum)
- **Repositories**: Interfaces JPA pour accéder aux données
- **Services**: Logique métier et interfaces
- **Controllers**: Endpoints REST API

## Configuration

### Production (MySQL)
- Fichier: `src/main/resources/application.properties`
- Base de données MySQL configurée

### Tests (H2)
- Fichier: `src/test/resources/application.properties`
- Base de données H2 en mémoire pour les tests

## CI/CD

Pipeline Jenkins configuré dans `Jenkinsfile`:
- Checkout du code
- Exécution des tests avec H2
- Build et packaging

## Exécution

```bash
# Tests
./mvnw test

# Build
./mvnw clean package

# Run
./mvnw spring-boot:run
```

