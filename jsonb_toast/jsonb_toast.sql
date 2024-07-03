-- jsonb_toast.sql
-- 2024 Charlie Keith
-- I was curious to see how large a JSONB value could be before PostgreSQL's
-- TOAST mechanism kicks in. This file does that experiment. Can be run using
-- `psql postgresql://localhost:5432/postgres -U postgres -f jsonb_toast.sql`
-- ref: https://www.postgresql.org/docs/current/storage-toast.html

-- functions to generate random text
drop function if exists gen_string_unicode;
create function gen_string_unicode(n integer)
returns text
as $$
  declare output text := '';
begin
  for i in 1..n loop
    -- get code points between 0x010000 and 0x10FFFD
    -- these should all occupy 4 bytes in UTF-8
    output := output || chr((floor(random() * 1048575) + 65536)::integer);
  end loop;
  return output;
end;
$$ language plpgsql;

drop function if exists gen_string_ascii;
create function gen_string_ascii(n integer)
returns text
as $$
declare
  output text := '';
  -- ascii code points should occupy 1 byte in UTF-8
  -- select from alphanumerics, since symbols/punctuation can
  -- result in bad json
  characters text :=
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  selection integer := 0;
begin
  for i in 1..n loop
    selection := (floor(random() * 62))::integer;
    output := output || substring(characters from selection for 1);
  end loop;
  return output;
end;
$$ language plpgsql;

-- create a table with just a single jsonb column
drop table if exists jsonb_test_table;
create table jsonb_test_table (
  data jsonb
);

-- insert some data
-- the simplest possible json doc, just a string literal
insert into jsonb_test_table (data)
select
  (('"' || gen_string_unicode(499) || '"')::json) -- usually no toast
  from generate_series(1,1) as i;
insert into jsonb_test_table (data)
select
  (('"' || gen_string_unicode(500) || '"')::json) -- usually no toast
  from generate_series(1,1) as i;
-- insert into jsonb_test_table (data)
-- select
--   (('"' || gen_string_ascii(2031) || '"')::json) -- usually no toast
--   from generate_series(1,1000) as i;
-- insert into jsonb_test_table (data)
-- select
--   (('"' || gen_string_ascii(2032) || '"')::json) -- usually no toast
--   from generate_series(1,1000) as i;
  --(('"' || gen_string_unicode(500) || '"')::json), -- usually toast
  --(('"' || gen_string_ascii(2031) || '"')::json),  -- usually no toast
  --(('"' || gen_string_ascii(2032) || '"')::json);  -- usually toast

-- function to get the toast table
drop function if exists get_toast_table;
create function get_toast_table()
  returns text
as $$
declare
begin
  return (select reltoastrelid::regclass
    from pg_class
    where relname='jsonb_test_table');
end;
$$ language plpgsql;

-- check sizes and if how many rows have been toasted
select pg_column_size(jsonb_test_table.*) from jsonb_test_table;
drop function if exists num_toasted_rows;
create function num_toasted_rows() returns integer
as $$
declare
  output integer := 0;
begin
  execute 
    'select count(distinct chunk_id) from ' || get_toast_table()
    into output;
  return output;
end;
$$ language 'plpgsql';
select num_toasted_rows();

