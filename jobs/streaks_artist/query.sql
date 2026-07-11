WITH
    monthly_stream_rank as (
        SELECT
            strftime('%Y-%m', ts) AS year_month
            , master_metadata_album_artist_name artist
            , count(*) cnt_stream
            , row_number() over (partition by strftime('%Y-%m', ts) order by count(*) DESC) as rank_helper
        FROM
            extended_stream_table
        WHERE master_metadata_album_artist_name IS NOT NULL
        GROUP BY 1,2
    )

    , top_10_stream as (
        select * from monthly_stream_rank where rank_helper <= 10
    )

    , streaks_top_10_stream as (
        select 
            year_month
            , artist
            , streak_status 
        from (
            select 
                year_month
                , artist
                , cnt_stream
                , sumdiff
                , CASE
                    WHEN sumdiff - lag(sumdiff) over (partition by artist order by year_month) = 0 then 'STREAKS' 
                    WHEN sumdiff - lag(sumdiff) over (partition by artist order by year_month) is null then 'FIRST STREAM' 
                    ELSE 'NO STREAKS'
                END AS streak_status
            from (
                select 
                    *
                    , sum(diff) over (partition by artist order by year_month) sumdiff
                from (
                    select 
                        year_month
                        , (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT)) month_index
                        , artist
                        , cnt_stream
                        , CASE 
                            WHEN (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                over (partition by artist order by year_month) = 1 then 0
                            WHEN (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                over (partition by artist order by year_month) is null then 1
                            ELSE (CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                - lag(CAST(substr(year_month, 1, 4) AS INT) * 12 + CAST(substr(year_month, 6, 2) AS INT))
                                over (partition by artist order by year_month)
                        END AS diff
                    from top_10_stream 
                )
            )
        )
    )

SELECT * from streaks_top_10_stream

;