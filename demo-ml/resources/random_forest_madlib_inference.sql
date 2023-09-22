---------------------------------------------------------------------------------
-- PREDICTION
---------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS rf_model_versions_local (
    training_run_timestamp BIGINT
);
CREATE UNIQUE INDEX IF NOT EXISTS rf_model_versions_local_idx on rf_model_versions_local (training_run_timestamp);

DROP FUNCTION IF EXISTS setup_madlib_tmp_source_table;
DROP FUNCTION IF EXISTS setup_madlib_tmp_prediction_table;
DROP FUNCTION IF EXISTS run_random_forest_prediction;
DROP FUNCTION IF EXISTS get_model_version;

CREATE OR REPLACE FUNCTION get_model_version()
RETURNS bigint
AS
$BODY$
DECLARE
	model_version bigint;
BEGIN
	SELECT t.training_run_timestamp FROM
        (SELECT training_run_timestamp, rank() OVER (order by training_run_timestamp)
         FROM rf_model_versions) t
    INTO model_version
    WHERE t.rank=least( (select count(1) from rf_model_versions_local) + 1,
                      (select count(1) from rf_model_versions) );
    RETURN model_version;
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION setup_madlib_tmp_source_table(table_prefix VARCHAR, id BIGINT, time_elapsed BIGINT, amt real, lat real, long real, cls_weight_label int, is_fraud SMALLINT)
RETURNS VOID
AS
$BODY$
BEGIN
	EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I;'
	               'create table if not exists %I."tmptbl" as select * from (values (%L::bigint,%L::bigint,%L::real,%L::real,%L::real,%L::int,%L::SMALLINT))  t(id, time_elapsed, amt, lat, long, cls_weight_label, is_fraud);'
	               'create table if not exists %I."rf_credit_card_transactions_model" as select * from rf_credit_card_transactions_model;'
	               'create table if not exists %I."rf_credit_card_transactions_model_group" as select * from rf_credit_card_transactions_model_group;'
	               'create table if not exists %I."rf_credit_card_transactions_model_summary" as select * from rf_credit_card_transactions_model_summary;'
	               'create table if not exists %I."rf_credit_card_transactions_importances" as select * from rf_credit_card_transactions_importances;',
			table_prefix,
			table_prefix,
			id,
			time_elapsed,
			amt,
			lat,
			long,
			cls_weight_label,
			is_fraud,
			table_prefix,
			table_prefix,
			table_prefix,
			table_prefix,
			table_prefix);
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
	EXECUTE format(
	'DROP TABLE IF EXISTS %I."tmp_prediction_results";'
	'SELECT madlib.forest_predict(''%s.rf_credit_card_transactions_model'',''%s.tmptbl'',''%s.tmp_prediction_results'',''response'')',
	table_prefix,table_prefix,table_prefix,table_prefix);
END;
$BODY$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION run_random_forest_prediction(time_elapsed BIGINT, amt REAL, lat REAL, long REAL, cls_weight_label INT DEFAULT 0, is_fraud SMALLINT DEFAULT NULL, id BIGINT DEFAULT 1)
RETURNS TABLE(result SMALLINT) AS
$$
DECLARE
	table_prefix VARCHAR;
	model_version BIGINT;
	done VARCHAR;
	result SMALLINT;
BEGIN
	SELECT get_model_version() INTO model_version;
	SELECT 'm' || model_version INTO table_prefix;
	SELECT setup_madlib_tmp_source_table(table_prefix, id, time_elapsed, amt, lat, long, cls_weight_label, is_fraud) INTO done;
	SELECT setup_madlib_tmp_prediction_table(table_prefix) INTO done;
	EXECUTE format('INSERT INTO rf_model_versions_local(training_run_timestamp) VALUES(%L::bigint) ON CONFLICT (training_run_timestamp) DO NOTHING;',
					model_version);
	RETURN QUERY
	EXECUTE format('SELECT estimated_is_fraud FROM %I."tmp_prediction_results" p, %I."tmptbl" g WHERE p.id = g.id ORDER BY g.id;',
                    table_prefix, table_prefix);

end $$
LANGUAGE plpgsql;