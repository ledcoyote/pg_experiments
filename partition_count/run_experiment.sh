#!/bin/bash
echo "Partitions=$npart, Rows=$mrows***************************************"
docker run \
  --name partition_exp \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  -d postgres:16-alpine \
  -c max_locks_per_transaction=256
sleep 5
# note: the default max_locks_per_transaction=64 errors for large npart

cat << EOF > set_params.sql
\set n $npart
\set m $mrows
EOF
psql postgresql://localhost:5432/postgres \
  -U postgres \
  -f set_params.sql \
  -f create_data.sql

echo "Select Benchmark*****************************************************"
cat << EOF > benchmark.sql
\set i random(1, $npart)
\set j random(1, $mrows)
begin;
  select * from base_table where id = :i and data = :j;
end;
EOF
pgbench -h localhost \
  -p 5432 \
  -U postgres \
  -f benchmark.sql \
  -c 1 \
  -T 120 \
  postgres

echo "Insert Benchmark*****************************************************"
cat << EOF > benchmark.sql
\set i random(1, $npart)
\set j random(1, $mrows)
\set k random(1, $mrows)
begin;
  insert into base_table (id, data, data_heap) values (:i,:j,:k);
end;
EOF
pgbench -h localhost \
  -p 5432 \
  -U postgres \
  -f benchmark.sql \
  -c 1 \
  -T 120 \
  postgres

rm benchmark.sql set_params.sql
docker stop partition_exp
docker rm partition_exp

