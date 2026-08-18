-- route/start_stop/weekday 등가 조건 후 departure_time 범위 조회 지원 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS
    idx_bus_timetable_route_stop_weekday_time
ON public.bus_timetable (route_id, start_stop_id, weekday, departure_time);
