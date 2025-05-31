#!/bin/bash

# Configuration - VOTRE PROJET GCP
PROJECT_ID="chrome-cascade-461214-g9"  # Votre Project ID GCP
CLUSTER_NAME="predictions-cluster"      # Nom du cluster
ZONE="europe-west1-b"                  # Zone GCP

echo "🚀 Déploiement sur Google Cloud..."

# 1. Construire et pousser l'image
echo "📦 Build et push de l'image..."
docker build -t gcr.io/$PROJECT_ID/predictions-api:latest ./api
docker push gcr.io/$PROJECT_ID/predictions-api:latest

# 2. Se connecter au cluster GKE
echo "🔗 Connexion au cluster GKE..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# 3. Déployer dans l'ordre
echo "📋 Déploiement des ressources..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/postgres.yaml

# Attendre PostgreSQL
echo "⏳ Attente de PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n predictions-app

# Déployer l'API
kubectl apply -f k8s/api.yaml
kubectl wait --for=condition=available --timeout=180s deployment/api -n predictions-app

# Optionnel: pgAdmin
kubectl apply -f k8s/pgadmin.yaml

echo "✅ Déploiement terminé!"
echo
echo "🌐 Récupération des adresses IP externes..."
kubectl get services -n predictions-app

echo
echo "⏳ Les LoadBalancers peuvent prendre quelques minutes à être prêts..."
echo "📋 Commandes utiles:"
echo "  kubectl get all -n predictions-app"
echo "  kubectl logs -f deployment/api -n predictions-app"