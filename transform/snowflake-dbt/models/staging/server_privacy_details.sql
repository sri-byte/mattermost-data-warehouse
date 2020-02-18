{{config({
    "materialized": "incremental",
    "schema": "staging"
  })
}}

WITH max_timestamp       AS (
    SELECT
        timestamp::DATE AS date
      , user_id
      , MAX(timestamp)  AS max_timestamp
    FROM {{ source('mattermost2', 'config_privacy') }}
    {% if is_incremental() %}

        -- this filter will only be applied on an incremental run
        WHERE timestamp::date > (SELECT MAX(date) FROM {{ this }})

    {% endif %}
    GROUP BY 1, 2
),
     server_privacy_details AS (
         SELECT
             timestamp::DATE         AS date
           , p.user_id               AS server_id
           , MAX(show_email_address) AS show_email_address
           , MAX(show_full_name)     AS show_full_name
         FROM {{ source('mattermost2', 'config_privacy') }} p
              JOIN max_timestamp         mt
                   ON p.user_id = mt.user_id
                       AND mt.max_timestamp = p.timestamp
         GROUP BY 1, 2
     )
SELECT *
FROM server_privacy_details