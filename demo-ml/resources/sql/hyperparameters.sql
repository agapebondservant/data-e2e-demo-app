--liquibase formatted sql
--changeset gpadmin:XYZCHANGESETID1 splitStatements:false
---------------------------------------------------------------------------------
-- HYPERPARAMETERS
---------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS hyperparams();
CREATE OR REPLACE FUNCTION hyperparams(code text)
RETURNS INTEGER
AS $BODY$
BEGIN
    SELECT current_setting('hyperparams.' || code)::integer;
END;
$BODY$
LANGUAGE plpgsql;
COMMENT ON FUNCTION hyperparams(code text)
IS 'Global holding place for setting and retrieving model hyperparameters';

SET hyperparams.random_forest_num_trees TO 3;
SET hyperparams.random_forest_num_random_features TO 2;
SET hyperparams.random_forest_num_permutations TO 1;
SET hyperparams.random_forest_max_depth TO 8;
SET hyperparams.random_forest_min_split TO 3;
SET hyperparams.random_forest_min_bucket TO 1;
SET hyperparams.random_forest_num_splits_per_continuous_var TO 10;