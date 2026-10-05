-- Remove storage owned only by retired B13 and B14 APIs.
begin;

drop table if exists subway_alert;
drop table if exists subway_train_delay;

commit;
