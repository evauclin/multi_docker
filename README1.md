# 🚀 Predictions API - Kubernetes sur Google Cloud

Application FastAPI avec PostgreSQL et pgAdmin, déployée sur Google Kubernetes Engine (GKE) avec stockage persistant et auto-scaling.

## 📋 Vue d'ensemble

Cette application fournit une API de prédiction de scores basée sur les heures d'étude. Elle utilise FastAPI pour l'API, PostgreSQL pour la persistance des données, et pgAdmin pour l'administration de la base de données.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   LoadBalancer  │───▶│   API Service   │───▶│ PostgreSQL Svc  │
│  (External IP)  │    │   (2 replicas)  │    │   (Persistent)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │               ┌───────▼──────┐        ┌──────▼──────┐
         │               │ Auto Scaling │        │ PVC (10Gi)  │
         │               │ (HPA Ready)  │        │ (Persistent)│
         │               └──────────────┘        └─────────────┘
         ▼
┌─────────────────┐
│    pgAdmin      │
│ (Port Forward)  │
└─────────────────┘
```

## 🌐 Accès aux services

### API FastAPI
- **URL principale** : http://35.205.178.72
- **Documentation Swagger** : http://35.205.178.72/docs
- **Health Check** : http://35.205.178.72/health

### pgAdmin (Administration PostgreSQL)
- **URL locale** : http://localhost:5051 (via port-forward)
- **Email** : `admin@admin.com`
- **Mot de passe** : `admin`

## 🚀 Déploiement

### Prérequis
- Google Cloud SDK configuré
- kubectl installé et configuré
- Docker installé
- Cluster GKE actif

### Commandes de déploiement

```bash
# 1. Cloner et naviguer vers le projet
cd votre-projet

# 2. Construire et déployer
chmod +x deploy-gke.sh
./deploy-gke.sh

# 3. Vérifier le déploiement
kubectl get all -n predictions-app
```

### Déploiement manuel (étape par étape)

```bash
# Configuration
export PROJECT_ID="chrome-cascade-461214-g9"
export CLUSTER_NAME="predictions-cluster"
export ZONE="europe-west1-b"

# Build et push de l'image
docker build -t gcr.io/$PROJECT_ID/predictions-api:latest ./api
docker push gcr.io/$PROJECT_ID/predictions-api:latest

# Connexion au cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# Déploiement ordonné
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/postgres-fixed.yaml
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n predictions-app

kubectl apply -f k8s/api.yaml
kubectl wait --for=condition=available --timeout=180s deployment/api -n predictions-app

kubectl apply -f k8s/pgadmin-fixed.yaml
kubectl wait --for=condition=available --timeout=180s deployment/pgadmin -n predictions-app
```

## 🧪 Tests et utilisation

### Test de l'API via curl

```bash
# Health check
curl http://35.205.178.72/health

# Prédiction simple
curl -X POST http://35.205.178.72/predict \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","hours_studied":8.5}'

# Prédictions multiples
curl -X POST http://35.205.178.72/predict -H "Content-Type: application/json" -d '{"name":"Bob","hours_studied":6.5}'
curl -X POST http://35.205.178.72/predict -H "Content-Type: application/json" -d '{"name":"Charlie","hours_studied":12}'
```

### Accès à pgAdmin

```bash
# Port forward pgAdmin
kubectl port-forward service/pgadmin-service 5051:80 -n predictions-app

# Ouvrir http://localhost:5051
# Configurer la connexion PostgreSQL :
# Host: postgres-service, Port: 5432, DB: predictions, User: user, Password: password
```

## 📊 Structure des données

### Table `predictions`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | Identifiant unique |
| `name` | TEXT | Nom de l'étudiant |
| `hours` | FLOAT | Heures d'étude |
| `score` | FLOAT | Score prédit (0-100) |
| `created_at` | TIMESTAMP | Date de création |

### Exemple de données

```sql
SELECT * FROM predictions ORDER BY created_at DESC LIMIT 5;

 id |   name   | hours | score |       created_at        
----|----------|-------|-------|-------------------------
  6 | Pierre   |   9.5 |   100 | 2025-05-31 01:05:32.775
  5 | Marie    |   7.5 |    78 | 2025-05-31 01:05:28.634
  4 | TestFinal|     8 |    84 | 2025-05-31 01:04:04.775
  3 | Charlie  |    10 |    95 | 2025-05-30 23:42:14.634
  2 | Bob      |     6 |  72.5 | 2025-05-30 23:42:14.634
```

## 🔧 Configuration

### Variables d'environnement

| Variable | Valeur | Description |
|----------|--------|-------------|
| `DB_HOST` | `postgres-service` | Host PostgreSQL |
| `DB_PORT` | `5432` | Port PostgreSQL |
| `DB_NAME` | `predictions` | Nom de la base |
| `DB_USER` | `user` | Utilisateur DB |
| `DB_PASSWORD` | `password` | Mot de passe DB |

### Ressources Kubernetes

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| PostgreSQL | 250m | 500m | 256Mi | 512Mi |
| API | 100m | 500m | 128Mi | 256Mi |
| pgAdmin | 100m | 300m | 256Mi | 512Mi |

## 🔍 Monitoring et débogage

### Commandes utiles

```bash
# État général
kubectl get all -n predictions-app

# Logs en temps réel
kubectl logs -f deployment/api -n predictions-app
kubectl logs -f deployment/postgres -n predictions-app

# Redémarrer un service
kubectl rollout restart deployment/api -n predictions-app

# Scaling manuel
kubectl scale deployment api --replicas=3 -n predictions-app

# Accès direct au pod PostgreSQL
kubectl exec -it deployment/postgres -n predictions-app -- psql -U user -d predictions
```

### Surveillance des performances

```bash
# Utilisation des ressources
kubectl top pods -n predictions-app

# État de l'autoscaling (si configuré)
kubectl get hpa -n predictions-app

# Événements récents
kubectl get events -n predictions-app --sort-by='.lastTimestamp'
```

## 🗂️ Structure du projet

```
predictions-k8s/
├── k8s/
│   ├── namespace.yaml           # Namespace isolé
│   ├── secrets.yaml            # Mots de passe chiffrés
│   ├── configmap.yaml          # Script d'initialisation DB
│   ├── pvc.yaml                # Stockage persistant
│   ├── postgres-fixed.yaml     # PostgreSQL avec PGDATA
│   ├── api.yaml                # API FastAPI + Service
│   └── pgadmin-fixed.yaml      # pgAdmin + Service
├── api/
│   ├── app.py                  # Application FastAPI
│   ├── Dockerfile              # Image Docker
│   └── requirements.txt        # Dépendances Python
└── deploy-gke.sh               # Script de déploiement automatique
```

## 🔐 Sécurité

### Bonnes pratiques implémentées

- ✅ **Secrets Kubernetes** : Mots de passe chiffrés
- ✅ **Utilisateur non-root** : Containers sécurisés
- ✅ **Health checks** : Monitoring de santé
- ✅ **Resource limits** : Limitation des ressources
- ✅ **Network isolation** : Services ClusterIP

### Identifiants par défaut

⚠️ **Pour la production, changez ces valeurs !**

```bash
# PostgreSQL
Username: user
Password: password
Database: predictions

# pgAdmin
Email: admin@admin.com
Password: admin
```

## 🚨 Dépannage

### Problèmes courants

#### PostgreSQL ne démarre pas
```bash
# Vérifier les logs
kubectl logs deployment/postgres -n predictions-app

# Problème de volume "lost+found"
# → Solution : PGDATA=/var/lib/postgresql/data/pgdata
```

#### API retourne 503
```bash
# L'API ne peut pas se connecter à PostgreSQL
kubectl logs deployment/api -n predictions-app

# Vérifier que PostgreSQL est prêt
kubectl get pods -n predictions-app
```

#### pgAdmin inaccessible
```bash
# Utiliser port-forward au lieu du LoadBalancer
kubectl port-forward service/pgadmin-service 5051:80 -n predictions-app
```

## 🛠️ Maintenance

### Mise à jour de l'application

```bash
# 1. Construire nouvelle image
docker build -t gcr.io/chrome-cascade-461214-g9/predictions-api:v2 ./api
docker push gcr.io/chrome-cascade-461214-g9/predictions-api:v2

# 2. Mettre à jour le déploiement
kubectl set image deployment/api api=gcr.io/chrome-cascade-461214-g9/predictions-api:v2 -n predictions-app

# 3. Vérifier le rolling update
kubectl rollout status deployment/api -n predictions-app
```

### Sauvegarde des données

```bash
# Backup PostgreSQL
kubectl exec deployment/postgres -n predictions-app -- \
  pg_dump -U user predictions > backup-$(date +%Y%m%d).sql

# Restaurer depuis un backup
kubectl exec -i deployment/postgres -n predictions-app -- \
  psql -U user predictions < backup-20250531.sql
```

## 📈 Évolutions possibles

### Améliorations techniques
- [ ] HTTPS avec certificats automatiques
- [ ] Monitoring avec Prometheus/Grafana
- [ ] CI/CD avec GitHub Actions
- [ ] Tests automatisés
- [ ] Network Policies pour l'isolation réseau
- [ ] Backup automatique de PostgreSQL

### Fonctionnalités métier
- [ ] Authentification utilisateur
- [ ] API de statistiques avancées
- [ ] Modèle de machine learning plus sophistiqué
- [ ] Interface web React/Vue.js
- [ ] API de gestion des utilisateurs

## 🏆 Résultat

✅ **Migration réussie** : Docker Compose → Kubernetes  
✅ **Production ready** : Déployé sur Google Cloud  
✅ **Scalable** : Auto-scaling configuré  
✅ **Résilient** : Redémarrage automatique  
✅ **Accessible** : LoadBalancer externe  
✅ **Administrable** : pgAdmin fonctionnel  

**Votre application est maintenant prête pour la production sur Google Cloud !** 🚀

## 📞 Support

Pour tout problème ou question :
1. Vérifiez les logs : `kubectl logs -f deployment/api -n predictions-app`
2. Consultez la documentation Kubernetes
3. Utilisez les commandes de debug fournies dans ce README

---

*Dernière mise à jour : 31 Mai 2025*