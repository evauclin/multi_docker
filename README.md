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

## 📊 Test de l'API

L'API expose un endpoint `/predict` qui prend un nom et des heures d'étude :

**Exemple de requête :**
```json
{
  "name": "John Doe",
  "hours_studied": 7.5
}
```

**Réponse :**
```json
{
  "predicted_score": 79
}
```

## 🗂️ Structure du projet

```
├── docker-compose.yml
├── api/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── db/
│   └── init.sql
└── pgadmin/
    ├── servers.json
    └── .pgpass
```

## 📝 Commandes utiles

| Commande | Description |
|----------|-------------|
| `docker-compose up -d` | Démarrer en arrière-plan |
| `docker-compose logs` | Voir les logs |
| `docker-compose logs api` | Voir les logs de l'API |
| `docker-compose restart` | Redémarrer les services |
| `docker-compose down -v` | Arrêter et supprimer les volumes |

## ✅ Vérification

Après le démarrage, vérifiez que :
- ✅ L'API répond sur http://localhost:8000
- ✅ pgAdmin est accessible sur http://localhost:5050
- ✅ Le serveur PostgreSQL est automatiquement configuré dans pgAdmin
- ✅ La table `predictions` contient des données de test