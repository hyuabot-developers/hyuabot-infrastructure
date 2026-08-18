-- 역명(language + name)으로 다국어 역명을 찾는 조회 지원 인덱스
-- CONCURRENTLY 사용으로 운영 중 테이블 쓰기 잠금을 최소화한다.
CREATE INDEX CONCURRENTLY IF NOT EXISTS
    idx_subway_station_translation_language_name
ON public.subway_station_translation (language, name)
INCLUDE (station_id);
