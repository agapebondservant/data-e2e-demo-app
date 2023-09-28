from imblearn.over_sampling import RandomOverSampler
import pandas as pd
from sqlalchemy import create_engine
from collections import Counter

cnx = create_engine('postgresql+psycopg2://gpadmin:Uu4jcDSjqlDVQ@44.201.91.88:5432/dev?sslmode=require')
ros = RandomOverSampler(random_state=0, shrinkage=5)
df = pd.read_sql_query("SELECT index, time_elapsed, cc_num, amt, lat, long, is_fraud FROM credit_card_transactions", cnx)
X, y = df.loc[:, df.columns != 'is_fraud'], df[['is_fraud']]
X_resampled, y_resampled = ros.fit_resample(X, y)
df_resampled = pd.concat([X_resampled, y_resampled], axis=1)
df_resampled.to_sql(name='credit_card_transactions_resampled', con=cnx, if_exists='replace', chunksize=100, index=True, index_label="id")

compression_opts = dict(method='zip', archive_name='credit_card_resampled.csv')
df_resampled.to_csv('credit_card_resampled.csv', chunksize=100, index=True, index_label="id")
