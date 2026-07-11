WITH
    monthly_stream_rank as (
        SELECT
            strftime('%Y-%m', ts) AS year_month
            , master_metadata_album_artist_name artist
            , master_metadata_track_name track
            , count(*) cnt_stream
            , row_number() over (partition by strftime('%Y-%m', ts) order by count(*) DESC) as rank
        FROM
            extended_stream_table
        WHERE master_metadata_track_name IS NOT NULL
        GROUP BY 1,2,3
    )

    , monthly_streaks_top_10_stream as (
        select 
            year_month
            , track
            , artist
            , rank
            , cnt_stream
            , streak_status 
        from (
            select 
                year_month
                , track
                , artist
                , cnt_stream
                , rank
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
                        , artist
                        , cnt_stream
                        , rank
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
                    from monthly_stream_rank 
                )
            )
        )
        order by year_month ASC, rank ASC
    )

    , monthly_streaks_agg AS (
        SELECT 
            track
            , artist
            , nth_streak
            , count(*) as cnt_streaks
            , min(year_month) as streak_start_date
            , max(year_month) as streak_end_date
        FROM (
            SELECT 
                year_month
                , track
                , artist
                , rank
                , cnt_stream
                , streak_status
                , streaks_helper
                , dense_rank() over (partition by track order by streaks_helper) as nth_streak
            FROM (
                SELECT 
                    *
                    , sum(case when streak_status in ('FIRST STREAM','NO STREAKS') then 1 else 0 end)
                        over (partition by track order by year_month) as streaks_helper
                from monthly_streaks_top_10_stream
            )
            WHERE streak_status = 'STREAKS'
        ) AS main
        GROUP BY 1,2,3
    )

    , daily_stream_rank as (
        SELECT
            strftime('%Y-%m-%d', ts) AS date
            , master_metadata_track_name track
            , master_metadata_album_artist_name artist
            , count(*) cnt_stream
            , row_number() over (partition by strftime('%Y-%m', ts) order by count(*) DESC) as rank
        FROM
            extended_stream_table
        WHERE master_metadata_track_name IS NOT NULL
        GROUP BY 1,2,3
    )

    , daily_streaks_top_10_stream as (
        select 
            date
            , track
            , artist
            , rank
            , cnt_stream
            , streak_status 
        from (
            select 
                date
                , track
                , artist
                , cnt_stream
                , rank
                , sumdiff
                , CASE
                    WHEN sumdiff - lag(sumdiff) over (partition by track order by date) = 0 then 'STREAKS' 
                    WHEN sumdiff - lag(sumdiff) over (partition by track order by date) is null then 'FIRST STREAM' 
                    ELSE 'NO STREAKS'
                END AS streak_status
            from (
                select 
                    *
                    , sum(diff) over (partition by track order by date) sumdiff
                from (
                    select 
                        date
                        , (CAST(substr(date, 1, 4) AS INT) * 12 + CAST(substr(date, 6, 2) AS INT)) month_index
                        , track
                        , artist
                        , cnt_stream
                        , rank
                        , CASE 
                            WHEN julianday(date)
                                - lag(julianday(date))
                                over (partition by track order by date) = 1 then 0
                            WHEN julianday(date)
                                - lag(julianday(date))
                                over (partition by track order by date) is null then 1
                            ELSE julianday(date)
                                - lag(julianday(date))
                                over (partition by track order by date)
                        END AS diff
                    from daily_stream_rank 
                )
            )
        )
        order by date ASC, rank ASC
    )

    , daily_streaks_agg AS (
        SELECT 
            track
            , artist
            , nth_streak
            , count(*) as cnt_streaks
            , min(date) as streak_start_date
            , max(date) as streak_end_date
        FROM (
            SELECT 
                date
                , track
                , artist
                , rank
                , cnt_stream
                , streak_status
                , streaks_helper
                , dense_rank() over (partition by track order by streaks_helper) as nth_streak
            FROM (
                SELECT 
                    *
                    , sum(case when streak_status in ('FIRST STREAM','NO STREAKS') then 1 else 0 end)
                        over (partition by track order by date) as streaks_helper
                from daily_streaks_top_10_stream
            )
            WHERE streak_status = 'STREAKS'
        ) AS main
        GROUP BY 1,2,3
    )

    , final AS (
        select 
            'Monthly' AS period
            , * 
            , row_number() over (partition by track order by cnt_streaks DESC) as streak_rank
        from monthly_streaks_agg
        UNION ALL
        select 
            'Daily' AS period
            , * 
            , row_number() over (partition by track order by cnt_streaks DESC) as streak_rank
        from daily_streaks_agg
    ) 

SELECT * FROM final order by 1 DESC,2

;
