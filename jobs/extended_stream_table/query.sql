select 
    ts timestamp
    , DATE(ts, '{utc_timezone}') AS date
    , STRFTIME('%H:%M', ts, '{utc_timezone}') AS time_hm
    , STRFTIME('%H', ts, '{utc_timezone}') AS time_h
    , ms_played
    , ms_played / 1000.0 as sec_played
    , ms_played / 60000.0 as min_played
    , platform
    , conn_country
    , master_metadata_track_name
    , master_metadata_album_artist_name
    , master_metadata_album_album_name
    , spotify_track_uri
    , episode_name
    , episode_show_name
    , spotify_episode_uri
    , audiobook_title
    , audiobook_uri
    , audiobook_chapter_uri
    , audiobook_chapter_title
    , reason_start
    , reason_end
    , shuffle
    , skipped
    , offline
    , datetime(offline_timestamp, 'unixepoch', '{utc_timezone}') offline_timestamp
    , STRFTIME('%H:%M', datetime(offline_timestamp, 'unixepoch', '{utc_timezone}')) AS offline_time_hm
    , STRFTIME('%H', datetime(offline_timestamp, 'unixepoch', '{utc_timezone}')) AS offline_time_h
    , incognito_mode
from 
    raw_extended_stream_table
where ms_played <> 0

;