# Partition Count

We're interested in the performance of PostgreSQL as we change the number of
partitions. In particular, if we have extremely large partition counts, but
are able to [partition prune](https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITION-PRUNING)
down to a single partition, is performance negatively impacted?

We create some partitioned tables here with roughly the same amount of
data. It's not an extreme amount, on the order of ~2GB. The we run some
`pgbench` experiments agains those tables to get an idea of `SELECT` and
`INSERT` performance. We also haven't done any tuning of memory or things
like that on the database image (just using the stock `postgres:16-alpine`
image with hardly any configuration options), so there's more exploration
of the space to see whether there are performance cliffs to fall off. There
are also lots of `pgbench` options, like number of clients and such to
consider.

## How to Run the Experiments

Requires [Docker](https://docs.docker.com/desktop/install/mac-install/).
`pgbench` is required, which you can get through [Postgres.app](https://postgresapp.com/)
(which I am using). `brew install postgresql@16` probably has it for you as
well. `expect` is also required, which came with my system (a MacBook Pro).
And `make`, of course.

Then:

```
make all
```

and then wait a loooooong time (`create_data.sql` execution time grows
ridiculously with `npart`).

## Results

Here are some results (output pruned significantly, since it is pretty
noisy).

### Number of partitions = 1000, Rows per partition = 20000

```
 pg_size_pretty 
----------------
 1688 kB

Select Benchmark*****************************************************
latency average = 0.826 ms
tps = 1209.999757 (without initial connection time)

Insert Benchmark*****************************************************
latency average = 1.111 ms
tps = 899.786774 (without initial connection time)
```

### Number of partitions = 10000, Rows per partition = 2000

```
 pg_size_pretty 
----------------
 216 kB

Select Benchmark*****************************************************
latency average = 0.905 ms
tps = 1104.883694 (without initial connection time)

Insert Benchmark*****************************************************
latency average = 1.248 ms
tps = 801.025167 (without initial connection time)
```

### Number of partitions = 50000, Rows per partition = 400

```
 pg_size_pretty 
----------------
 56 kB

Select Benchmark*****************************************************
latency average = 1.126 ms
tps = 888.269819 (without initial connection time)

Insert Benchmark*****************************************************
latency average = 1.447 ms
tps = 691.101361 (without initial connection time)
```

## Discussion



