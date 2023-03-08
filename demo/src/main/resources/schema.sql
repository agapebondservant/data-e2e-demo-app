CREATE TABLE IF NOT EXISTS Transaction (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date_time VARCHAR(50) NOT NULL,
  transaction_type VARCHAR(50) NOT NULL,
  card_number VARCHAR(50) NOT NULL,
  amount VARCHAR(10) NOT NULL,
  location VARCHAR(20) NOT NULL,
  lat FLOAT,
  lon FLOAT,
  is_fraud boolean
);