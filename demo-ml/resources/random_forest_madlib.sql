---------------------------------------------------------------------------------
-- TRAINING
---------------------------------------------------------------------------------

DROP FUNCTION run_random_forest_training();

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
	m.training_time::bigint as training_run_timestamp,
	g.cls_weight_label::SMALLINT as cls_weight
	FROM rf_credit_card_transactions_inference_results p,
	rf_credit_card_transactions_inference g,
	metadata m
	WHERE p.id = g.id
	ORDER BY g.id;
END;
$BODY$
LANGUAGE plpgsql;

---------------------------------------------------------------------------------
-- PREDICTION
---------------------------------------------------------------------------------
DROP FUNCTION setup_madlib_tmp_source_table;
DROP FUNCTION setup_madlib_tmp_prediction_table;
DROP FUNCTION run_random_forest_prediction;

CREATE OR REPLACE FUNCTION setup_madlib_tmp_source_table(table_prefix VARCHAR, id BIGINT, time_elapsed BIGINT, amt real, lat real, long real, cls_weight_label int, is_fraud SMALLINT)
RETURNS VOID
AS
$BODY$
BEGIN
	EXECUTE format('create table "tmptbl_%s" as select * from (values (%L::bigint,%L::bigint,%L::real,%L::real,%L::real,%L::int,%L::SMALLINT))  t(id, time_elapsed, amt, lat, long, cls_weight_label, is_fraud)',
			table_prefix,
			id,
			time_elapsed,
			amt,
			lat,
			long,
			cls_weight_label,
			is_fraud);
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION setup_madlib_tmp_prediction_table(table_prefix VARCHAR) 
RETURNS void
AS
$BODY$
DECLARE
	done VARCHAR;
BEGIN
	EXECUTE format('SELECT madlib.forest_predict(''rf_credit_card_transactions_model'',''tmptbl_%s'',''tmp_prediction_results_%s'',''response'')',table_prefix,table_prefix);
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION run_random_forest_prediction(time_elapsed BIGINT, amt REAL, lat REAL, long REAL, cls_weight_label INT DEFAULT 0, is_fraud SMALLINT DEFAULT NULL, id BIGINT DEFAULT 1)
RETURNS SMALLINT AS
$$
DECLARE
	table_prefix VARCHAR;
	done VARCHAR;
	result SMALLINT;
BEGIN
	SELECT TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH12MMSS') INTO table_prefix;
	SELECT setup_madlib_tmp_source_table(table_prefix, id, time_elapsed, amt, lat, long, cls_weight_label, is_fraud) INTO done;
	SELECT setup_madlib_tmp_prediction_table(table_prefix) INTO done;
	EXECUTE format('SELECT estimated_is_fraud FROM "tmp_prediction_results_%s" p, "tmptbl_%s" g WHERE p.id = g.id ORDER BY g.id ',
					table_prefix,
				    table_prefix) INTO result;
	RETURN result;

end $$
LANGUAGE plpgsql;