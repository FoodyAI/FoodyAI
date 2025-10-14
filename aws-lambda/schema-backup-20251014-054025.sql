                                                                  Table "public.users"
      Column      |           Type           | Collation | Nullable |           Default           | Storage  | Compression | Stats target | Description 
------------------+--------------------------+-----------+----------+-----------------------------+----------+-------------+--------------+-------------
 user_id          | character varying(255)   |           | not null |                             | extended |             |              | 
 email            | character varying(255)   |           | not null |                             | extended |             |              | 
 display_name     | character varying(255)   |           |          |                             | extended |             |              | 
 photo_url        | text                     |           |          |                             | extended |             |              | 
 gender           | character varying(50)    |           |          |                             | extended |             |              | 
 age              | integer                  |           |          |                             | plain    |             |              | 
 weight           | numeric(5,2)             |           |          |                             | main     |             |              | 
 height           | numeric(5,2)             |           |          |                             | main     |             |              | 
 activity_level   | character varying(50)    |           |          |                             | extended |             |              | 
 goal             | character varying(50)    |           |          |                             | extended |             |              | 
 daily_calories   | numeric(6,2)             |           |          |                             | main     |             |              | 
 bmi              | numeric(4,2)             |           |          |                             | main     |             |              | 
 theme_preference | character varying(50)    |           |          | 'system'::character varying | extended |             |              | 
 ai_provider      | character varying(50)    |           |          | 'openai'::character varying | extended |             |              | 
 created_at       | timestamp with time zone |           |          | CURRENT_TIMESTAMP           | plain    |             |              | 
 updated_at       | timestamp with time zone |           |          | CURRENT_TIMESTAMP           | plain    |             |              | 
 measurement_unit | character varying(20)    |           |          | 'metric'::character varying | extended |             |              | 
Indexes:
    "users_pkey" PRIMARY KEY, btree (user_id)
    "users_email_key" UNIQUE CONSTRAINT, btree (email)
Referenced by:
    TABLE "foods" CONSTRAINT "food_analyses_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
Access method: heap

Did not find any relation named "notifications_log".
Did not find any relation named "notification_campaigns".
