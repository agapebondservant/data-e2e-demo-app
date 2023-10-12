--liquibase formatted sql
--changeset gpadmin:XYZCHANGESETID1 splitStatements:false
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
#variable_conflict use_column
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


    -- Model versions
    CREATE TABLE IF NOT EXISTS rf_model_versions (
        training_run_timestamp BIGINT,
        passed BOOLEAN
    );

    -- Model evaluations
    CREATE TABLE IF NOT EXISTS rf_credit_card_transactions_model_evaluations (
        training_run_timestamp BIGINT,
        total_rows_processed INTEGER,
        total_rows_skipped INTEGER,
        num_failed_groups INTEGER,
        oob_error NUMERIC,
        passed BOOLEAN default 'y'
    );

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


	-- 2. ingest data into training table and inference table
	CREATE TEMPORARY TABLE creditcardtemp AS (
    SELECT "id",
       	time_elapsed,
       	cc_num,
       	amt,
       	lat,
       	long,
       	is_fraud,
       	rank() over (ORDER BY random()) FROM credit_card_transactions_resampled);

    INSERT INTO rf_credit_card_transactions_training (id, time_elapsed, amt, lat, long, is_fraud, cls_weight_label)
    SELECT "id",
            time_elapsed,
            amt,
            lat,
            long,
            is_fraud,
            0
            FROM creditcardtemp
            WHERE rank < (SELECT COUNT(1) FROM creditcardtemp)/2; --TODO: Remove hardcoded training size

    INSERT INTO rf_credit_card_transactions_inference (id, time_elapsed, amt, lat, long, is_fraud, cls_weight_label)
    SELECT "id",
            time_elapsed,
            amt,
            lat,
            long,
            is_fraud,
            1
            FROM creditcardtemp
            WHERE rank >= (SELECT COUNT(1) FROM creditcardtemp)/2; --TODO: Remove hardcoded inference size

    DROP TABLE creditcardtemp;

	-- 3. generate RandomForest model
	perform madlib.forest_train('rf_credit_card_transactions_training',         -- source table
	                           'rf_credit_card_transactions_model',    -- output model table
	                           'id',              -- id column
	                           'is_fraud',           -- response
	                           'time_elapsed, amt, lat, long',   -- features
	                           NULL,              -- exclude columns
	                           NULL,              -- grouping columns
	                           hyperparams('random_forest_num_trees'),       -- number of trees
	                           hyperparams('random_forest_num_random_features'),        -- number of random features
	                           TRUE::boolean,     -- variable importance
	                           hyperparams('random_forest_num_permutations'),        -- num_permutations
	                           hyperparams('random_forest_max_depth'),        -- max depth
	                           hyperparams('random_forest_min_split'),        -- min split
	                           hyperparams('random_forest_min_bucket'),        -- min bucket
	                           hyperparams('random_forest_num_splits_per_continuous_var')        -- number of splits per continuous variable
	                           );


	-- view importances
	perform madlib.get_var_importance('rf_credit_card_transactions_model','rf_credit_card_transactions_importances');
	--SELECT * FROM rf_credit_card_transactions_importances ORDER BY oob_var_importance DESC;

	-- 4. predict outputs
	perform madlib.forest_predict('rf_credit_card_transactions_model',        -- tree model
	                             'rf_credit_card_transactions_inference',             -- new data table
	                             'rf_credit_card_transactions_inference_results',  -- output table
	                             'response');           -- show response

	-- 5. log model data in new schema
	perform create_new_random_forest_training_schema(training_timestamp);

	-- 6. perform model evaluations
	perform run_random_forest_model_evaluations(training_timestamp);

	RETURN QUERY
	SELECT id, time_passed, amount, latitude, longitude, is_fraud_flag, training_run_timestamp, cls_weight
	FROM rf_credit_card_inferences_vw;
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
                   'CREATE TABLE %I.rf_credit_card_transactions_inference_results AS SELECT * FROM public.rf_credit_card_transactions_inference_results;'
                   'CREATE TABLE %I.rf_credit_card_transactions_inference AS SELECT * FROM public.rf_credit_card_transactions_inference;',
                   'm' || training_run_timestamp, 'm' || training_run_timestamp, 'm' || training_run_timestamp, 'm' || training_run_timestamp,
                   'm' || training_run_timestamp, 'm' || training_run_timestamp, 'm' || training_run_timestamp);
END;
$BODY$
LANGUAGE plpgsql;
COMMENT ON FUNCTION create_new_random_forest_training_schema(bigint)
IS 'Creates snapshot of newly trained RandomForest model as a new schema';


DROP FUNCTION IF EXISTS run_random_forest_model_evaluations();
CREATE OR REPLACE FUNCTION public.run_random_forest_model_evaluations(training_run_timestamp bigint)
RETURNS VOID
as $BODY$
BEGIN
    INSERT INTO rf_credit_card_transactions_model_evaluations(training_run_timestamp, total_rows_processed, total_rows_skipped, num_failed_groups, oob_error, passed)
        SELECT training_run_timestamp, total_rows_processed, total_rows_skipped, num_failed_groups, oob_error,
           	(SELECT total_rows_skipped < 1000 AND num_failed_groups < 1) passed
                FROM rf_credit_card_transactions_model_summary rcctms, rf_credit_card_transactions_model_group grp;
    CREATE OR REPLACE VIEW rf_credit_card_inferences_vw AS SELECT * FROM get_model_selection_random_forest();
END;
$BODY$
LANGUAGE plpgsql;
COMMENT ON FUNCTION public.run_random_forest_model_evaluations(training_run_timestamp bigint)
IS 'Evaluates performance of selected model identified by training_run_timestamp';

DROP FUNCTION IF EXISTS get_model_selection_random_forest() CASCADE;
CREATE OR REPLACE FUNCTION public.get_model_selection_random_forest()
RETURNS table (
    id bigint,
    time_passed bigint,
    amount real,
    latitude real,
    longitude real,
    is_fraud_flag real,
    training_run_timestamp bigint,
    cls_weight SMALLINT
)
as $BODY$
DECLARE
    selected_training_timestamp bigint;
BEGIN
    SELECT r.training_run_timestamp
        FROM rf_credit_card_transactions_model_evaluations r
        INTO selected_training_timestamp
        WHERE r.oob_error = (SELECT COALESCE(MIN(oob_error),0) FROM rf_credit_card_transactions_model_evaluations WHERE passed = 'y')
        OR TRUE;

    INSERT INTO rf_model_versions (training_run_timestamp, passed)
      SELECT r.training_run_timestamp, r.passed
        FROM rf_credit_card_transactions_model_evaluations r
        WHERE r.training_run_timestamp = selected_training_timestamp;

    RETURN QUERY
    EXECUTE format('SELECT g.id::bigint as id,'
    	'g.time_elapsed::bigint as time_passed,'
    	'g.amt::real as amount,'
    	'g.lat::real as latitude,'
    	'g.long::real as longitude,'
    	'p.estimated_is_fraud::real as is_fraud_flag,'
    	'%L::bigint as training_run_timestamp,'
    	'0::smallint as cls_weight '
    	'FROM %I.rf_credit_card_transactions_inference_results p,'
    	'%I.rf_credit_card_transactions_inference g, '
    	'rf_credit_card_transactions_model_evaluations k '
    	'WHERE p.id = g.id AND k.training_run_timestamp = %L::bigint AND k.passed IS TRUE '
    	'ORDER BY g.id;',
    	selected_training_timestamp, 'm' || selected_training_timestamp, 'm' || selected_training_timestamp, selected_training_timestamp);
END;
$BODY$
LANGUAGE plpgsql;
COMMENT ON FUNCTION public.get_model_selection_random_forest()
IS 'Using specified measures of error, selects the candidate model with the best performing metrics and returns inference data associated with the selected model';