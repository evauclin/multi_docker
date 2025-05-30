\c predictions;

DROP TABLE IF EXISTS predictions;

CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    hours FLOAT NOT NULL CHECK (hours >= 0),
    score FLOAT NOT NULL CHECK (score >= 0 AND score <= 100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO predictions (name, hours, score) VALUES 
    ('Alice', 8.5, 85.0),
    ('Bob', 6.0, 72.5),
    ('Charlie', 10.0, 95.0);


SELECT * FROM predictions;

CREATE INDEX idx_predictions_name ON predictions(name);
CREATE INDEX idx_predictions_created_at ON predictions(created_at);

\d predictions;