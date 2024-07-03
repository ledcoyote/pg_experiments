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

## Results

Here are some results (output pruned significantly, since it is pretty
noisy).

### Number of partitions = 1000, Rows per partition = 20000

```
foobar
```

### Number of partitions = 10000, Rows per partition = 2000

```
foobar
```

### Number of partitions = 50000, Rows per partition = 400

```
foobar
```

## Discussion



