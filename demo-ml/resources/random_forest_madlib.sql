DROP FUNCTION run_random_forest_training();

CREATE OR REPLACE FUNCTION public.run_random_forest_training()
RETURNS table (
    id bigint,
    time_passed bigint,
    amount real,
    latitude real,
    longitude real,
    is_fraud_flag real,
    training_run_timestamp bigint
)
as $BODY$
BEGIN
	-- 1. drop and recreate prior RandomForest training tables
	DROP TABLE IF EXISTS rf_credit_card_transactions_training,
	    rf_credit_card_transactions_model,
		rf_credit_card_transactions_model_group,
		rf_credit_card_transactions_model_summary,
		rf_credit_card_transactions_inference,
		rf_credit_card_transactions_inference_results,
		rf_credit_card_transactions_importances;

	CREATE TABLE rf_credit_card_transactions_training(
		id serial,
		time_elapsed bigint,
		amt real,
		lat real,
		long real,
		is_fraud smallint);

	-- Inference data
	create table rf_credit_card_transactions_inference(
		id serial,
		time_elapsed bigint,
		amt real,
		lat real,
		long real,
		is_fraud smallint);


	-- 2. ingest data into training table
	insert into rf_credit_card_transactions_training (id, time_elapsed, amt, lat, long, is_fraud)
	select t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud
	from credit_card_transactions_training_vw t;

	-- 3. ingest data into inference table
	insert into rf_credit_card_transactions_inference (id, time_elapsed, amt, lat, long, is_fraud)
	select t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud
	from credit_card_transactions_inference_vw t;

	-- 4. generate RandomForest model
	perform madlib.forest_train('rf_credit_card_transactions_training',         -- source table
	                           'rf_credit_card_transactions_model',    -- output model table
	                           'id',              -- id column
	                           'is_fraud',           -- response
	                           'time_elapsed, amt, lat, long',   -- features
	                           NULL,              -- exclude columns
	                           NULL,              -- grouping columns
	                           20::integer,       -- number of trees
	                           2::integer,        -- number of random features
	                           TRUE::boolean,     -- variable importance
	                           1::integer,        -- num_permutations
	                           8::integer,        -- max depth
	                           3::integer,        -- min split
	                           1::integer,        -- min bucket
	                           10::integer        -- number of splits per continuous variable
	                           );


	-- view importances
	perform madlib.get_var_importance('rf_credit_card_transactions_model','rf_credit_card_transactions_importances');
	--SELECT * FROM rf_credit_card_transactions_importances ORDER BY oob_var_importance DESC;

	-- 6. predict outputs
	perform madlib.forest_predict('rf_credit_card_transactions_model',        -- tree model
	                             'rf_credit_card_transactions_inference',             -- new data table
	                             'rf_credit_card_transactions_inference_results',  -- output table
	                             'response');           -- show response

	RETURN QUERY
    WITH metadata AS (
        select round(extract(epoch from current_date) + extract(epoch from current_time)) AS training_time
    )
	SELECT g.id::bigint as id,
	g.time_elapsed::bigint as time_passed,
	g.amt::real as amount,
	g.lat::real as latitude,
	g.long::real as longitude,
	p.estimated_is_fraud::real as is_fraud_flag,
	m.training_time::bigint as training_run_timestamp
	FROM rf_credit_card_transactions_inference_results p,
	rf_credit_card_transactions_inference g,
	metadata m
	WHERE p.id = g.id
	ORDER BY g.id;
END;
$BODY$
LANGUAGE plpgsql;