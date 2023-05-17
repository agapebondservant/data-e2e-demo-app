CREATE TABLE IF NOT EXISTS public.credit_card_transactions( time serial not null, v1 numeric, v2 numeric, v3 numeric, v4 numeric, v5 numeric, v6 numeric, v7 numeric, v8 numeric, v9 numeric,
v10 numeric, v11 numeric, v12 numeric, v13 numeric, v14 numeric, v15 numeric, v16 numeric, v17 numeric, v18 numeric, v19 numeric, v20 numeric, v21 numeric, v22 numeric,
v23 numeric, v24 numeric, v25 numeric, v26 numeric, v27 numeric, v28 numeric, amount real, class smallint);

CREATE TEMPORARY TABLE IF NOT EXISTS  t (time serial not null, V1 numeric, V2 numeric, V3 numeric, V4 numeric, V5 numeric, V6 numeric, V7 numeric, V8 numeric, V9 numeric, V10 numeric, V11 numeric, V12 numeric, V13 numeric, V14 numeric, V15 numeric, V16 numeric, V17 numeric, V18 numeric, V19 numeric, V20 numeric, V21 numeric, V22 numeric,
V23 numeric, V24 numeric, V25 numeric, V26 numeric, V27 numeric, V28 numeric, amount real, class smallint);

COPY t (time, V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, V11, V12, V13, V14, V15, V16, V17, V18, V19, V20, V21, V22, V23, V24, V25, V26, V27, V28, amount, class)
from './creditcard.csv'
CSV HEADER LOG ERRORS SEGMENT REJECT LIMIT 50 ROWS;

INSERT INTO public.credit_card_transactions SELECT time, V1 , V2 , V3 , V4 , V5 , V6 , V7 , V8 , V9 , V10 , V11 ,
V12 , V13 , V14 , V15 , V16 , V17 , V18 , V19 , V20 , V21 ,
V22 , V23 , V24 , V25 , V26 , V27 , V28 ,  amount, class from t;



