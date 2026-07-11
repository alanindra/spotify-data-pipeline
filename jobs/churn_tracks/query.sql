WITH
    monthly_stream_churn_status AS (
        SELECT
            year_month
            , track_name
            , artist_name
            -- , dense_rank() over (partition by artist_name, track_name order by sumdiff) as nth_streak
            , case 
                when status = 'ACTIVE' 
                AND LAG(status) OVER (PARTITION BY artist_name, track_name ORDER BY year_month) = 'CHURN' THEN 'REACTIVATED' 
                ELSE status
            END as final_status
        FROM (
            SELECT 
                *
                , case 
                    when sumdiff - lag(sumdiff) over (partition by artist_name, track_name order by year_month) is null then 'FIRST STREAM'
                    when sumdiff - lag(sumdiff) over (partition by artist_name, track_name order by year_month) = 0 then 'ACTIVE'
                    when sumdiff - lag(sumdiff) over (partition by artist_name, track_name order by year_month) <> 0 then 'CHURN'
                END AS status
            FROM (
                SELECT
                    *
                    , sum(diff) over (partition by artist_name, track_name order by year_month) sumdiff
                FROM (
                    SELECT 
                        *
                        , CASE 
                            WHEN (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                over (partition by artist_name, track_name order by year_month) = 1 then 0
                            WHEN (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                over (partition by artist_name, track_name order by year_month) is null then 1
                            ELSE (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                over (partition by artist_name, track_name order by year_month)
                            END
                        AS diff
                    FROM (
                        SELECT
                            strftime('%Y-%m', ts) AS year_month
                            , master_metadata_album_artist_name artist_name
                            , master_metadata_track_name track_name
                        FROM 
                            extended_stream_table
                        WHERE master_metadata_album_artist_name IS NOT NULL
                        ORDER BY strftime('%Y-%m', ts) ASC
                    )
                    GROUP BY 1,2,3
                )
            )
        )
    )

    , daily_stream_churn_status AS (
        SELECT
            date
            , track_name
            , artist_name
            -- , dense_rank() over (partition by artist_name, track_name order by sumdiff) as nth_streak
            , case 
                when status = 'ACTIVE' 
                AND LAG(status) OVER (PARTITION BY artist_name, track_name ORDER BY date) = 'CHURN' THEN 'REACTIVATED' 
                ELSE status
            END as final_status
        FROM (
            SELECT 
                *
                , case 
                    when sumdiff - lag(sumdiff) over (partition by artist_name, track_name order by date) is null then 'FIRST STREAM'
                    when sumdiff - lag(sumdiff) over (partition by artist_name, track_name order by date) = 0 then 'ACTIVE'
                    when sumdiff - lag(sumdiff) over (partition by artist_name, track_name order by date) <> 0 then 'CHURN'
                END AS status
            FROM (
                SELECT
                    *
                    , sum(diff) over (partition by artist_name, track_name order by date) sumdiff
                FROM (
                    SELECT 
                        *
                        , CASE 
                            WHEN julianday(date)
                                - lag(julianday(date))
                                over (partition by artist_name, track_name order by date) = 1 then 0
                            WHEN julianday(date)
                                - lag(julianday(date))
                                over (partition by artist_name, track_name order by date) is null then 1
                            ELSE julianday(date)
                                - lag(julianday(date))
                                over (partition by artist_name, track_name order by date)
                            END
                        AS diff
                    FROM (
                        SELECT
                            strftime('%Y-%m-%d', ts) AS date
                            , master_metadata_album_artist_name artist_name
                            , master_metadata_track_name track_name
                        FROM 
                            extended_stream_table
                        WHERE master_metadata_album_artist_name IS NOT NULL
                        ORDER BY strftime('%Y-%m-%d', ts) ASC
                    )
                    GROUP BY 1,2,3
                )
            )
        )
    )

    , final as (
        select 'Monthly' AS period, * from monthly_stream_churn_status
        union all
        select 'Daily' AS period, * from daily_stream_churn_status   
    )

SELECT * FROM final order by 1 DESC, 2 ASC

;