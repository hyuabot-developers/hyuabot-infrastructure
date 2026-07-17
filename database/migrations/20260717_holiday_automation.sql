begin;

alter table public_holiday
    add column if not exists source varchar(20),
    add column if not exists updated_at timestamptz;

update public_holiday
set source = coalesce(source, 'MANUAL'),
    updated_at = coalesce(updated_at, now())
where source is null or updated_at is null;

alter table public_holiday
    alter column source set default 'MANUAL',
    alter column source set not null,
    alter column updated_at set default now(),
    alter column updated_at set not null;

create table if not exists holiday_sync_state(
    source varchar(20) primary key,
    last_attempt_at timestamptz,
    last_success_at timestamptz,
    range_start date,
    range_end date,
    last_error text
);

do $$
begin
    if exists (
        select 1
        from shuttle_holiday
        group by holiday_date, calendar_type
        having count(*) > 1
    ) then
        raise exception 'Duplicate shuttle_holiday rows exist for holiday_date and calendar_type';
    end if;
end
$$;

drop index if exists idx_shuttle_holiday_date;
create unique index idx_shuttle_holiday_date
    on shuttle_holiday(holiday_date, calendar_type);

commit;
