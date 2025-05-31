from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import random
import psycopg2
import os

app = FastAPI()

class InputData(BaseModel):
    name: str
    hours_studied: float

def log_prediction(name, hours, score):
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres-service"),
        database=os.getenv("DB_NAME", "predictions"),
        user=os.getenv("DB_USER", "user"),
        password=os.getenv("DB_PASSWORD", "password")
    )
    cur = conn.cursor()
    cur.execute("INSERT INTO predictions (name, hours, score) VALUES (%s, %s, %s)", (name, hours, score))
    conn.commit()
    cur.close()
    conn.close()

@app.get("/")
def read_root():
    return {"message": "Predictions API", "status": "running"}

@app.get("/health")
def health_check():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST", "postgres-service"),
            database=os.getenv("DB_NAME", "predictions"),
            user=os.getenv("DB_USER", "user"),
            password=os.getenv("DB_PASSWORD", "password")
        )
        conn.close()
        return {"status": "healthy", "database": "connected"}
    except:
        raise HTTPException(status_code=503, detail="Database connection failed")

@app.post("/predict")
def predict(data: InputData):
    score = min(100, data.hours_studied * 10 + random.randint(-5, 5))
    try:
        log_prediction(data.name, data.hours_studied, score)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"predicted_score": score}