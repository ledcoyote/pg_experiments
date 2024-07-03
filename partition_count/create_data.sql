-- create_data.sql

-- function to create partitions and load them with data
drop function if exists gen_partitions;
create function gen_partitions(
  n integer, -- number of partitions
  m integer  -- number of rows per partition
) returns void
as $$
declare
begin
  -- define base table
  drop table if exists base_table;
  create table base_table (
    id bigint,
    data bigint,
    data_heap bigint
  ) partition by list (id);

  -- index
  create index id_data_indx on base_table (id, data);

  -- create partitions
  for i in 1..n loop
    execute
      'create table partition_table_' || i::text || ' '
      'partition of base_table '
      'for values in (' || i::text || ');';
  end loop;

  -- insert data
  insert into base_table (id, data, data_heap)
  select i, j, j from
    generate_series(1, n) as i,
    generate_series(1, m) as j;
end;
$$ language plpgsql;

-- create some tables
select gen_partitions(:n, :m);
vacuum full;

-- size of a single partition table
select pg_size_pretty(pg_total_relation_size('partition_table_1'));

