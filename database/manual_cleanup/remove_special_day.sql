-- Opt-in cleanup for environments where special_day was already created.
-- Run only after all backend images no longer map SpecialDay and the updater
-- no longer writes KASI special-day sync state. See the infrastructure README.
begin;

delete from holiday_sync_state where source = 'KASI_SPECIAL';
drop table if exists special_day;

commit;
