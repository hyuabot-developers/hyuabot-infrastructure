BEGIN;

CREATE TABLE IF NOT EXISTS subway_station_translation (
    station_id varchar(10) NOT NULL REFERENCES subway_route_station(station_id) ON UPDATE CASCADE ON DELETE CASCADE,
    language varchar(10) NOT NULL,
    name varchar(100) NOT NULL,
    source varchar(30) NOT NULL,
    is_verified boolean NOT NULL DEFAULT false,
    PRIMARY KEY (station_id, language),
    CONSTRAINT subway_station_translation_language_check
        CHECK (language IN ('ko', 'en', 'ja', 'zh-Hans', 'zh-Hant')),
    CONSTRAINT subway_station_translation_name_check
        CHECK (length(trim(name)) > 0)
);

INSERT INTO subway_station_translation (station_id, language, name, source, is_verified)
SELECT station_id, 'ko', station_name, 'HYUABOT_EXISTING', true
FROM subway_route_station
ON CONFLICT (station_id, language) DO NOTHING;

COMMIT;
