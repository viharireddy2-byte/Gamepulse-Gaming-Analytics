-- Run with the target billing project selected in bq.
CREATE SCHEMA IF NOT EXISTS gamepulse OPTIONS(location='US');
CREATE TABLE IF NOT EXISTS gamepulse.raw_events (
 event_id STRING NOT NULL, event TIMESTAMP NOT NULL, ingested_at TIMESTAMP NOT NULL,
 user_id STRING NOT NULL, game_name STRING NOT NULL, event_name STRING NOT NULL,
 player_first_seen TIMESTAMP NOT NULL, country STRING, device_platform STRING,
 game_version STRING, install_source STRING, campaign_name STRING,
 install_cost NUMERIC, iap_revenue NUMERIC, ad_revenue NUMERIC, player_level INT64,
 continent STRING, region STRING, device_brand STRING, device_language STRING, device_model STRING,
 device_os_version STRING, ad_network STRING, campaign_id STRING, campaign_type STRING
) PARTITION BY DATE(event) CLUSTER BY game_name,user_id,event_name;
CREATE TABLE IF NOT EXISTS gamepulse.pipeline_state (
 batch_id STRING NOT NULL, published_at TIMESTAMP NOT NULL, status STRING NOT NULL
);
