-- create_data.sql
-- Charlie Keith 2024
-- How many partitions is safe to use in PostgreSQL if we're able to
-- effectively parition-prune? The docs state that "The query planner is
-- generally able to handle partition hierarchies with up to a few thousand
-- partitions fairly well, provided that typical queries allow the query
-- planner to prune all but a small number of partitions." What if we can
-- always prune to a single partition when LIST-partitioning? Can we grow
-- the number of the partitions unbounded?
--
-- https://www.postgresql.org/docs/current/ddl-partitioning.html
--
-- Usage:
-- $ docker run --name pg_experiments \
-- $   -e POSTGRES_PASSWORD=password \
-- $   -p 5432:5432 \
-- $   -d postgres:16-alpine \
-- $   -c max_locks_per_transaction=256
-- $ psql postgresql://localhost:5432/postgres -U postgres
-- postgres=# \i number_of_partitions.sql
--
-- (note: the default max_locks_per_transaction=64 causes an error when
-- creating a large number of partitions, e.g. 10000)

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

