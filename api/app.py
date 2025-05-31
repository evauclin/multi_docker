from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
import asyncio
import asyncpg
import os
import logging
from contextlib import asynccontextmanager
import time
import random

# Configuration logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Pool de connexions global
db_pool = None

class InputData(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    hours_studied: float = Field(..., ge=0, le=24)

class PredictionResponse(BaseModel):
    predicted_score: float
    confidence: float
    processing_time_ms: float

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup - Créer le pool de connexions
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(
            host=os.getenv("DB_HOST", "postgres-service"),
            database=os.getenv("DB_NAME", "predictions"),
            user=os.getenv("DB_USER", "user"),
            password=os.getenv("DB_PASSWORD", "password"),
            port=int(os.getenv("DB_PORT", "5432")),
            min_size=2,
            max_size=10,
            max_inactive_connection_lifetime=300
        )
        logger.info("✅ Database connection pool created successfully")
    except Exception as e:
        logger.error(f"❌ Failed to create database pool: {e}")
        raise
    
    yield
    
    # Shutdown - Fermer le pool
    if db_pool:
        await db_pool.close()
        logger.info("🔒 Database pool closed")

app = FastAPI(
    title="Predictions API Optimized",
    description="API de prédiction de scores avec pool de connexions et monitoring",
    version="2.0.0",
    lifespan=lifespan
)

async def get_db_pool():
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database pool not available")
    return db_pool

@app.get("/")
async def read_root():
    return {
        "message": "Predictions API v2.0 - Optimized", 
        "status": "running",
        "features": ["async", "connection_pooling", "monitoring", "autoscaling"]
    }

@app.get("/health")
async def health_check(pool = Depends(get_db_pool)):
    """Health check avec vérification de la DB"""
    try:
        start_time = time.time()
        async with pool.acquire() as conn:
            await conn.fetchval("SELECT 1")
        db_latency = (time.time() - start_time) * 1000
        
        return {
            "status": "healthy", 
            "database": "connected",
            "db_latency_ms": round(db_latency, 2),
            "pool_size": pool.get_size(),
            "pool_idle": pool.get_idle_size(),
            "timestamp": time.time()
        }
    except Exception as e:
        logger.error(f"❌ Health check failed: {e}")
        raise HTTPException(status_code=503, detail="Database connection failed")

@app.get("/metrics")
async def get_metrics(pool = Depends(get_db_pool)):
    """Métriques pour monitoring (Prometheus compatible)"""
    try:
        async with pool.acquire() as conn:
            total_predictions = await conn.fetchval("SELECT COUNT(*) FROM predictions")
            avg_score = await conn.fetchval("SELECT AVG(score) FROM predictions")
            recent_count = await conn.fetchval(
                "SELECT COUNT(*) FROM predictions WHERE created_at > NOW() - INTERVAL '1 hour'"
            )
            
        return {
            "predictions_total": int(total_predictions or 0),
            "predictions_avg_score": round(float(avg_score or 0), 2),
            "predictions_last_hour": int(recent_count or 0),
            "database_pool_size": pool.get_size(),
            "database_pool_idle": pool.get_idle_size(),
            "app_version": "2.0.0"
        }
    except Exception as e:
        logger.error(f"❌ Metrics failed: {e}")
        raise HTTPException(status_code=500, detail="Metrics unavailable")

@app.post("/predict", response_model=PredictionResponse)
async def predict(data: InputData, pool = Depends(get_db_pool)):
    """Prédiction avec modèle amélioré et monitoring"""
    start_time = time.time()
    
    try:
        # Modèle de prédiction amélioré (plus réaliste)
        base_score = min(100, max(0, data.hours_studied * 8.5 + 15 + random.uniform(-5, 5)))
        confidence = min(0.98, max(0.5, 0.6 + (data.hours_studied / 25)))
        predicted_score = round(base_score, 1)
        
        # Enregistrer en base de données de manière asynchrone
        async with pool.acquire() as conn:
            prediction_id = await conn.fetchval(
                """INSERT INTO predictions (name, hours, score, confidence) 
                   VALUES ($1, $2, $3, $4) RETURNING id""",
                data.name, data.hours_studied, predicted_score, confidence
            )
        
        processing_time = (time.time() - start_time) * 1000
        
        logger.info(
            f"📊 Prediction #{prediction_id} - {data.name}: {predicted_score:.1f}% "
            f"(confidence: {co