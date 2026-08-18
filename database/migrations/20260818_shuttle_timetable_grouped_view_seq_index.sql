-- 셔틀 시간표 grouped materialized view의 seq 기반 조회 지원 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS
    idx_shuttle_timetable_grouped_view_seq
ON public.shuttle_timetable_grouped_view (seq);
