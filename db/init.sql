\c predictions;

DROP TABLE IF EXISTS predictions;

CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    hours FLOAT NOT NULL CHECK (hours >= 0 AND hours <= 24),
    score FLOAT NOT NULL CHECK (score >= 0 AND score <= 100),
    confidence FLOAT DEFAULT 0.8 CHECK (confidence >= 0 AND confidence <= 1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Données de test plus réalistes
INSERT INTO predictions (name, hours, score, confidence) VALUES 
    ('Alice Johnson', 8.5, 85.2, 0.92),
    ('Bob Martin', 6.0, 72.5, 0.85),
    ('Charlie Brown', 10.0, 95.0, 0.95),
    ('Diana Prince', 4.5, 58.3, 0.78),
    ('Eve Adams', 12.0, 98.7, 0.97),
    ('Frank Miller', 2.0, 45.1, 0.65);

-- Index pour optimiser les performances
CREATE INDEX idx_predictions_name ON predictions(name);
CREATE INDEX idx_predictions_created_at ON predictions(created_at DESC);
CREATE INDEX idx_predictions_score ON predictions(score DESC);
CREATE INDEX idx_predictions_hours ON predictions(hours);

-- Vue pour les statistiques rapides
CREATE VIEW prediction_stats AS
SELECT 
    COUNT(*) as total_predictions,
    AVG(score) as avg_score,
    AVG(hours) as avg_hours,
    AVG(confidence) as avg_confidence,
    MAX(created_at) as last_prediction
FROM predictions;

-- Afficher la structure et les données
\d predictions;
SELECT * FROM predictions ORDER BY created_at DESC;
SELECT * FROM prediction_stats;