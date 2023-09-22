---------------------------------------------------------------------------------
-- TRAINING
---------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS run_random_forest_training();

CREATE OR REPLACE FUNCTION public.run_random_forest_training()
RETURNS table (
    id bigint,
    time_passed bigint,
    amount real,
    latitude real,
    longitude real,
    is_fraud_flag real,
    training_run_timestamp bigint,
    cls_weight_label SMALLINT
)
as $BODY$
DECLARE
    training_timestamp bigint := (select round(extract(epoch from current_date) + extract(epoch from current_time)));
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
		time_elapsed real,
		amt real,
		lat real,
		long real,
		is_fraud SMALLINT,
		cls_weight_label SMALLINT);

	-- Model versions
	CREATE TABLE IF NOT EXISTS rf_model_versions (
	    training_run_timestamp BIGINT
	);

	-- Inference data
	create table rf_credit_card_transactions_inference(
		id serial,
		time_elapsed real,
		amt real,
		lat real,
		long real,
		is_fraud SMALLINT,
		cls_weight_label SMALLINT);


	-- 2. ingest data into training table
	insert into rf_credit_card_transactions_training (id, time_elapsed, amt, lat, long, is_fraud, cls_weight_label)
	select t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud,
	      t.cls_weight_label
	from credit_card_transactions_training_vw t;

	-- 3. ingest data into inference table
	insert into rf_credit_card_transactions_inference (id, time_elapsed, amt, lat, long, is_fraud, cls_weight_label)
	select t.index,
	      t.time_elapsed,
	      t.amt,
	      t.lat,
	      t.long,
	      t.is_fraud,
	      t.cls_weight_label
	from credit_card_transactions_inference_vw t;

	-- 4. generate RandomForest model
	perform madlib.forest_train('rf_credit_card_transactions_training',         -- source table
	                           'rf_credit_card_transactions_model',    -- output model table
	                           'id',              -- id column
	                           'is_fraud',           -- response
	                           'time_elapsed, amt, lat, long',   -- features
	                           NULL,              -- exclude columns
	                           'cls_weight_label',              -- grouping columns
	                           3::integer,       -- number of trees
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

	-- 7. log model data in new schema
	perform create_new_random_forest_training_schema(training_timestamp);

	RETURN QUERY
	SELECT g.id::bigint as id,
	g.time_elapsed::bigint as time_passed,
	g.amt::real as amount,
	g.lat::real as latitude,
	g.long::real as longitude,
	p.estimated_is_fraud::real as is_fraud_flag,
	training_timestamp::bigint as training_run_timestamp,
	g.cls_weight_label::SMALLINT as cls_weight
	FROM rf_credit_card_transactions_inference_results p,
	rf_credit_card_transactions_inference g
	WHERE p.id = g.id
	ORDER BY g.id;
END;
$BODY$
LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS create_new_random_forest_training_schema();
CREATE OR REPLACE FUNCTION public.create_new_random_forest_training_schema(training_run_timestamp bigint)
RETURNS VOID
as $BODY$
BEGIN
    EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I;'
    			   'CREATE TABLE %I.rf_credit_card_transactions_model AS SELECT * FROM public.rf_credit_card_transactions_model;'
                   'CREATE TABLE %I.rf_credit_card_transactions_model_group AS SELECT * FROM public.rf_credit_card_transactions_model_group;'
                   'CREATE TABLE %I.rf_credit_card_transactions_model_summary AS SELECT * FROM  public.rf_credit_card_transactions_model_summary;'
                   'CREATE TABLE %I.rf_credit_card_transactions_importances AS SELECT * FROM public.rf_credit_card_transactions_importances;'
                   'INSERT INTO rf_model_versions(training_run_timestamp) VALUES(%L::bigint);',
                   'm' || training_run_timestamp, 'm' || training_run_timestamp, 'm' || training_run_timestamp, 'm' || training_run_timestamp, 'm' || training_run_timestamp, training_run_timestamp);
END;
$BODY$
LANGUAGE plpgsql;