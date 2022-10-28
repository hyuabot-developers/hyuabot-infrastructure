drop schema public cascade;
create schema public;

-- 셔틀버스 운행 기간 종류
create table shuttle_period_type (
    periodType varchar(15) primary key
);

-- 셔틀버스 운행 노선
create table shuttle_route (
    routeName varchar(15) primary key
);

-- 셔틀버스 정류장
create table shuttle_stop (
    stopName varchar(15) primary key
);

-- 셔틀버스 운행 기간 (학기중, 계절학기, 방학)
create table shuttle_period(
    -- 셔틀버스 운행 기간 ID
    periodID serial primary key,
    periodType varchar(15) not null,
    periodStart timestamptz not null,
    periodEnd timestamptz not null,
    constraint fk_periodType
        foreign key (periodType)
        references shuttle_period_type(periodType)
);

-- 셔틀버스 운행 시간표
create table shuttle_timeTable(
    periodType varchar(15) not null,
    isWeekends boolean not null,
    routeName varchar(15) not null,
    departureTime timestamptz not null,
    startStop varchar(15) not null,
    constraint fk_periodType
        foreign key (periodType)
        references shuttle_period_type(periodType),
    constraint fk_routeName
        foreign key (routeName)
        references shuttle_route(routeName),
    constraint fk_startStop
        foreign key (startStop)
        references shuttle_stop(stopName)
);
