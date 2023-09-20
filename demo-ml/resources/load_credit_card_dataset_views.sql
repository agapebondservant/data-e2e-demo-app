
-- TODO: Refactor hardcoded offsets for rownumbers
-- 1. create view for training data - use random oversampling to compensate for class imbalance
CREATE OR REPLACE VIEW credit_card_transactions_training_vw AS
SELECT t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud,
	      t.cls_weight_label
	FROM (
	  SELECT index,
	  		time_elapsed,
	      	amt,
	      	lat,
	      	long,
	      	is_fraud,
	        row_number() over () AS rn,
	        (SELECT count(*) FROM credit_card_transactions) AS cnt,
	        ( mod( (ROW_NUMBER() OVER (ORDER BY RANDOM()) - 1) / 3, 3 )) as cls_weight_label
	  FROM credit_card_transactions where is_fraud=0
	  union
	  SELECT index,
	  		time_elapsed,
	      	amt,
	      	lat,
	      	long,
	      	is_fraud,
	        row_number() over () AS rn,
	        (SELECT count(*) FROM credit_card_transactions) AS cnt,
	        ( mod( (ROW_NUMBER() OVER (ORDER BY RANDOM()) - 1) / 3, 3 )) as cls_weight_label
	  FROM credit_card_transactions where is_fraud=1
	  GROUP BY index, time_elapsed, amt, lat, long, is_fraud
	) t
	WHERE rn  <= 200000 --0.75*cnt
	ORDER BY rn;

-- TODO: Refactor hardcoded offsets for rownumbers
-- create view for inference data - use random oversampling to compensate for class imbalance
CREATE OR REPLACE VIEW credit_card_transactions_inference_vw AS
SELECT t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud,
	      t.cls_weight_label
	FROM (
	  SELECT index,
	  		time_elapsed,
	      	amt,
	      	lat,
	      	long,
	      	is_fraud,
	        row_number() over () AS rn,
	        (SELECT count(*) FROM credit_card_transactions) AS cnt,
	        ( mod( (ROW_NUMBER() OVER (ORDER BY RANDOM()) - 1) / 3, 3 )) as cls_weight_label
	  FROM credit_card_transactions where is_fraud=0
	  union
	  SELECT index,
	  		time_elapsed,
	      	amt,
	      	lat,
	      	long,
	      	is_fraud,
	        row_number() over () AS rn,
	        (SELECT count(*) FROM credit_card_transactions) AS cnt,
	        ( mod( (ROW_NUMBER() OVER (ORDER BY RANDOM()) - 1) / 3, 3 )) as cls_weight_label
	  FROM credit_card_transactions where is_fraud=1
	  GROUP BY index, time_elapsed, amt, lat, long, is_fraud
	) t
	WHERE rn  > 200000 AND rn <=400000 -- 0.75*cnt
	ORDER BY rn;