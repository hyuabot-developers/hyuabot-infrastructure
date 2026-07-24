begin;

create table if not exists shuttle_initial_stop_rule(
    seq serial primary key,
    rule_name varchar(80) not null,
    period_type varchar(20) not null references shuttle_period_type(period_type),
    weekday boolean not null,
    start_time time,
    end_time time,
    stop_name varchar(15) not null references shuttle_stop(stop_name),
    priority int not null default 0,
    enabled boolean not null default true,
    polygon jsonb not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint chk_shuttle_initial_stop_rule_name
        check (length(trim(rule_name)) > 0),
    constraint chk_shuttle_initial_stop_rule_time_range
        check (
            (start_time is null and end_time is null)
            or
            (start_time is not null and end_time is not null and start_time <> end_time)
        ),
    constraint chk_shuttle_initial_stop_rule_polygon_type
        check (jsonb_typeof(polygon) = 'array'),
    constraint chk_shuttle_initial_stop_rule_polygon_size
        check (jsonb_array_length(polygon) >= 3)
);

create index if not exists idx_shuttle_initial_stop_rule_active
    on shuttle_initial_stop_rule(enabled, period_type, weekday, priority desc, seq);

commit;
