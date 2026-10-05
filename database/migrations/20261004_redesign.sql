begin;

-- B4/B6: GBIS v2 realtime details.
alter table bus_realtime add column if not exists current_stop_name varchar(50);
alter table bus_realtime add column if not exists plate_no varchar(20);
alter table bus_realtime add column if not exists crowded smallint;
alter table bus_realtime add column if not exists state_code smallint;

-- B5: reading room reservation failure reason.
alter table reading_room add column if not exists unable_message varchar(255);

-- B7: Seoul Metro arrival messages and seconds.
alter table subway_realtime add column if not exists arrival_message varchar(100);
alter table subway_realtime add column if not exists arrival_message_detail varchar(100);
alter table subway_realtime add column if not exists remaining_seconds int;
alter table subway_realtime add column if not exists arrival_code smallint;

-- B11: static station access facilities.
create table if not exists subway_station_facility (
    seq serial primary key,
    station_id varchar(10) not null references subway_route_station(station_id),
    facility_type varchar(20) not null check (facility_type in ('elevator', 'escalator', 'wheelchair_lift', 'route')),
    sort_order int not null default 0,
    exit_no varchar(10),
    from_place varchar(50),
    to_place varchar(50),
    description_korean varchar(200),
    description_english varchar(200),
    source varchar(30) not null default 'KR_NETWORK',
    unique (station_id, facility_type, sort_order)
);

-- B12: GBIS v2 route stops and vehicle locations.
create table if not exists bus_route_station (
    route_id int not null references bus_route(route_id),
    station_seq int not null,
    station_id int not null,
    station_name varchar(50) not null,
    updated_at timestamptz not null default now(),
    primary key (route_id, station_seq)
);
create table if not exists bus_location (
    route_id int not null references bus_route(route_id),
    plate_no varchar(20) not null,
    station_seq int not null,
    station_id int,
    crowded smallint,
    remaining_seat_count int,
    low_plate boolean,
    state_code smallint,
    last_updated_time timestamptz not null,
    primary key (route_id, plate_no)
);

-- B13: KORAIL operating information.
create table if not exists subway_train_delay (
    run_date date not null,
    train_number varchar(10) not null,
    route_id int,
    delay_minutes int,
    reference_station_name varchar(30),
    updated_at timestamptz not null default now(),
    primary key (run_date, train_number)
);

-- B14: Seoul Metro alerts.
create table if not exists subway_alert (
    alert_id varchar(50) primary key,
    route_id int,
    title varchar(200) not null,
    content text,
    starts_at timestamptz,
    ends_at timestamptz,
    source varchar(30) not null default 'SEOUL_METRO',
    updated_at timestamptz not null default now()
);
create index if not exists idx_subway_alert_route on subway_alert(route_id, ends_at);

commit;
