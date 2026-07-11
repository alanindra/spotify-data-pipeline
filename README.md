# [WIP] Spotify Data Pipeline

Create and transform tables from your recent Spotify extended stream data, so you can explore your streaming history effortlessly without having to wait for the end of year :)

## Features
1. Store and update raw data table for downstream tasks
2. Run data transformation jobs

## Getting started

- input
    - metadata
        - Contains YourLibrary.json file
    - streaming_history
        - Contains StreamingHistory_music*.json files
    - extended_streaming_history
        - Contains Streaming_History_Audio*.json files
        - Contains Streaming_History_Video*.json files

Once processed, the data will be moved to processed dir

- output
    - metadata
        - metadata_{date}_{counter} (info latest updated date per table)
    - tables
        - spotify_master_table.csv
        - spotify_artist_table.csv
        - spotify_trackts_table.csv
        - spotify_albums_table.csv
        - spotify_churn_monthly_snapshot.csv

- processed
    - {time}
        - Contains untransformed and unenriched tables

- logs
    - must contain table name, update time (upstream for metadata)

### TODO
fix churn logic (current table shows listening activity. meaning, there should not any instance of churn. prolly need crossjoin.)