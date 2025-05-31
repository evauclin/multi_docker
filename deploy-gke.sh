#!/bin/bash
set -e

# Configuration
PROJECT_ID="${PROJECT_ID:-chrome-cascade-461214-g9}"
CLUSTER_NAME="${CLUSTER_NAME:-predictions-cluster}"
ZONE="${ZONE:-europe-west1-b}"
IMAGE_TAG="${IMAGE_TAG:-$(date +%Y%m%d-%H%M%S)}"

echo "🚀 Déploiement optimisé sur Google Cloud..."
echo "📋 Configuration:"
echo "  Project: $PROJECT_ID"
echo "  Cluster: $CLUSTER_NAME" 
echo "  Zone: $ZONE"
echo "  Image Tag: $IMAGE_TAG"

# Vérifications préalables
echo "🔍 Vérification des prérequis..."
command -v gcloud >/dev/null 2>&1 || { echo "❌ Google Cloud SDK requis"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl requis"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker requis"; exit 1; }

# Build et push
echo "📦 Build et push de l'image optimisée..."
docker build --platform linux/amd64 -t gcr.io/$PROJECT_ID/predictions-api:$IMAGE_TAG ./api
docker tag gcr.io/$PROJECT_ID/predictions-api:$IMAGE_TAG gcr.io/$PROJECT_ID/predictions-api:latest

echo "⬆️ Push vers Google Container Registry..."
docker push gcr.io/$PROJECT_ID/predictions-api:$IMAGE_TAG
docker push gcr.io/$PROJECT_ID/predictions-api:latest

# Connexion cluster
echo "🔗 Connexion au cluster GKE..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# Déploiement ordonné
echo "📋 Déploiement des ressources..."

echo "  ➤ Namespace..."
kubectl apply -f k8s/namespace.yaml

echo "  ➤ Secrets et ConfigMaps..."
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/configmap.yaml

echo "  ➤ Stockage persistant..."
kubectl apply -f k8s/pvc.yaml

echo "  ➤ Base de données PostgreSQL..."
kubectl apply -f k8s/postgres-fixed.yaml
echo "    ⏳ Attente de PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n predictions-app

echo "  ➤ API avec autoscaling..."
# Mettre à jour l'image tag dans le déploiement
sed "s|gcr.io/$PROJECT_ID/predictions-api:latest|gcr.io/$PROJECT_ID/predictions-api:$IMAGE_TAG|g" k8s/api.yaml | kubectl apply -f -
echo "    ⏳ Attente de l'API..."
kubectl wait --for=condition=available --timeout=180s deployment/api -n predictions-app

echo "  ➤ pgAdmin..."
kubectl apply -f k8s/pgadmin-fixed.yaml

echo "✅ Déploiement terminé avec succès!"

# Récupération des informations
echo ""
echo "🌐 Récupération des informations de connexion..."
echo "⏳ Recherche de l'IP externe..."

# Attendre l'IP externe
for i in {1..20}; do
    EXTERNAL_IP=$(kubectl get service api-service -n predictions-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ ! -z "$EXTERNAL_IP" ]; then
        echo "✅ IP externe assignée: $EXTERNAL_IP"
        break
    fi
    echo "    ⏳ Attente de l'IP externe... ($i/20)"
    sleep 15
done

echo ""
echo "📊 Informations de connexion:"
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "🌐 API principale: http://$EXTERNAL_IP"
    echo "📚 Documentation Swagger: http://$EXTERNAL_IP/docs"
    echo "💚 Health check: http://$EXTERNAL_IP/health"
    echo "📈 Métriques: http://$EXTERNAL_IP/metrics"
    echo "📊 Statistiques: http://$EXTERNAL_IP/predictions/stats"
else
    echo "⚠️ IP externe non encore assignée. Utilisez:"
    echo "kubectl get services -n predictions-app"
fi

echo ""
echo "🔧 pgAdmin (nécessite port-forward):"
echo "kubectl port-forward service/pgadmin-service 5051:80 -n predictions-app"
echo "Puis accéder à: http://localhost:5051"
echo "Identifiants: admin@admin.com / admin"

echo ""
echo "📋 Commandes utiles pour monitoring:"
echo "kubectl get all -n predictions-app                    # État général"
echo "kubectl top pods -n predictions-app                   # Utilisation ressources"
echo "kubectl logs -f deployment/api -n predictions-app     # Logs en temps réel"
echo "kubectl get hpa -n predictions-app                    # Autoscaling"
echo "kubectl describe pod <pod-name> -n predictions-app    # Détails d'un pod"

echo ""
echo "🧪 Test rapide de l'API:"
if [ ! -z "$EXTERNAL_IP" ]; then
    echo "curl http://$EXTERNAL_IP/health"
    echo "curl -X POST http://$EXTERNAL_IP/predict -H 'Content-Type: application/json' -d '{\"name\":\"Test User\",\"hours_studied\":7.5}'"
fi

echo ""
echo "🎉 Votre API optimisée est maintenant déployée sur Google Cloud!"