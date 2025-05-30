# Prédiction API avec PostgreSQL et pgAdmin

Application FastAPI simple avec base de données PostgreSQL et interface d'administration pgAdmin.

## 🚀 Démarrage rapide

### Lancer l'application
```bash
docker-compose up -d
```

### Reconstruire les images (si modifications)
```bash
docker-compose build --no-cache
docker-compose up -d
```

### Arrêter et nettoyer complètement
```bash
docker-compose down -v
```

## 🔗 Liens d'accès

| Service | URL | Description |
|---------|-----|-------------|
| **API FastAPI** | [http://localhost:8000](http://localhost:8000) | API principale |
| **Documentation API** | [http://localhost:8000/docs](http://localhost:8000/docs) | Interface Swagger |
| **pgAdmin** | [http://localhost:5050](http://localhost:5050) | Administration PostgreSQL |

## 🔐 Identifiants

### pgAdmin
- **Email** : `admin@admin.com`
- **Mot de passe** : `admin`

### Base de données PostgreSQL
- **Host** : `db` (dans Docker) / `localhost:5432` (depuis l'extérieur)
- **Database** : `predictions`
- **Username** : `user`
- **Password** : `password`