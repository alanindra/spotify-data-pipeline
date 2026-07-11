WITH
    monthly_stream_rank as (
        SELECT
            strftime('%Y-%m', ts) AS year_month
            , master_metadata_track_name track
            , count(*) cnt_stream
            , row_number() over (partition by strftime('%Y-%m', ts) order by count(*) DESC) as rank_helper
        FROM
            extended_stream_table
        WHERE master_metadata_track_name IS NOT NULL
        GROUP BY 1,2
    )

    , top_10_stream as (
        select * from monthly_stream_rank where rank_helper <= 10
    )

    , streaks_top_10_stream as (
        select 
            year_month
            , track
            , cnt_stream
            , sumdiff
            , CASE
                WHEN sumdiff - lag(sumdiff) over (partition by track order by year_month) = 0 then 'STREAKS' 
                WHEN sumdiff - lag(sumdiff) over (partition by track order by year_month) is null then 'FIRST STREAM' 
                ELSE 'NO STREAKS'
            END AS streak_status
        from (
            select 
                *
                , sum(diff) over (partition by track order by year_month) sumdiff
            from (
                select 
                    year_month
                    , (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT)) month_index
                    , track
                    , cnt_stream
                    , CASE 
                        WHEN (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                            - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                            over (partition by track order by year_month) = 1 then 0
                        WHEN (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                            - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                            over (partition by track order by year_month) is null then 1
                        ELSE (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                            - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                            over (partition by track order by year_month)
                    END AS diff
                from top_10_stream 
            )
        )
    )
    
    , calculate_streak as (
        select 
            track
            , sumdiff
            , streak_status
            , count(*) cnt_month_streaks
        FROM streaks_top_10_stream
        WHERE streak_status NOT IN ('NO STREAKS','FIRST STREAM')
        GROUP BY 1,2,3
    )

SELECT 
    cs.track
    , cs.cnt_month_streaks
    , MIN(s10.year_month) AS streak_date_start
    , MAX(s10.year_month) AS streak_date_end
FROM calculate_streak cs
LEFT JOIN streaks_top_10_stream s10
    ON cs.sumdiff = s10.sumdiff
    AND cs.track = s10.track
GROUP BY 1,2
order by cs.cnt_month_streaks DESC, cs.track ASC 
    
;