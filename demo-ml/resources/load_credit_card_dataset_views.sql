
-- TODO: Refactor hardcoded offsets for rownumbers
-- 1. create view for training data
CREATE OR REPLACE VIEW credit_card_transactions_training_vw AS
SELECT t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud
	FROM (
	  SELECT index,
	  		time_elapsed,
	      	amt,
	      	lat,
	      	long,
	      	is_fraud,
	        row_number() over () AS rn,
	        (SELECT count(*) FROM credit_card_transactions) AS cnt
	  FROM credit_card_transactions
	  GROUP BY index, time_elapsed, amt, lat, long, is_fraud
	) t
	WHERE rn  <= 200000 --0.75*cnt
	ORDER BY rn;

-- TODO: Refactor hardcoded offsets for rownumbers
-- create view for inference data
CREATE OR REPLACE VIEW credit_card_transactions_inference_vw AS
SELECT t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud
	FROM (
	  SELECT index,
	  		time_elapsed,
	      	amt,
	      	lat,
	      	long,
	      	is_fraud,
	        row_number() over () AS rn,
	        (SELECT count(*) FROM credit_card_transactions) AS cnt
	  FROM credit_card_transactions
	  GROUP BY index, time_elapsed, amt, lat, long, is_fraud
	) t
	WHERE rn  > 200000 AND rn <=400000 -- 0.75*cnt
	ORDER BY rn;