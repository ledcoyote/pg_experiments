# Limit-Offset Paging a Query With Aggregations on Joined Tables

In this experiment we are interested in performance when we are joining two
tables together and performing aggregations on the results, which are paged
using the limit-offset method*. We consider a case where we are aggregating
counts on the joined table when placing a limit and offset on the outer table.

If we naively do a straight join and put the limit on the outermost query, we
get the correct result, and if there is no offset, then the performance is about
as good as we can get. However, if the limit is large we do end up counting a
large portion of the joined table, which can be slow.

>try `\set l 500` and `\set o 0`. The three queries perform similarly, but
rather slowly.

To compensate, we can use a very small limit. However, for the naive method of
joining, we end up having to read and aggregate over a lot of the joined table,
especially as the page number gets higher, since the database has to read and
discard the offset rows when using this pagination method.

>try `\set l 10` and `\set o 100`. The naive method has to join and aggregate
over a lot of the task table. The buffers is large.

To do better, we can force the limit onto the outer table using a CTE or
subquery (which produce identical plans). The rows produced are precisely the
ones we will use for our join and results in a much smaller number of total
buffers read and an overall fast execution time.

`*` Limit-Offset paging isn't a great way to do paging. There are better
methods, such as the ["seek" method](https://use-the-index-luke.com/sql/partial-results/fetch-next-page),
but it is a simple approach. We can consider other paging approaches at another
time.

## Results - Limit 500 Offset 0

```
                                                                            QUERY PLAN                                                                             
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.70..26028.45 rows=500 width=36) (actual time=0.654..158.015 rows=500 loops=1)
   Buffers: shared hit=557
   ->  GroupAggregate  (cost=0.70..52056.20 rows=1000 width=36) (actual time=0.653..157.947 rows=500 loops=1)
         Group Key: p.id
         Buffers: shared hit=557
         ->  Merge Join  (cost=0.70..32046.20 rows=1000000 width=12) (actual time=0.024..106.338 rows=499950 loops=1)
               Merge Cond: (p.id = t.project_id)
               Buffers: shared hit=557
               ->  Index Only Scan using project_pkey on project p  (cost=0.28..43.27 rows=1000 width=4) (actual time=0.014..0.162 rows=501 loops=1)
                     Heap Fetches: 501
                     Buffers: shared hit=6
               ->  Index Only Scan using task_project_fk_idx on task t  (cost=0.42..19500.42 rows=1000000 width=8) (actual time=0.007..43.078 rows=499950 loops=1)
                     Heap Fetches: 0
                     Buffers: shared hit=551
 Planning:
   Buffers: shared hit=14
 Planning Time: 0.258 ms
 Execution Time: 158.085 ms
(18 rows)

                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=0.70..26761.28 rows=500 width=36) (actual time=0.300..138.256 rows=500 loops=1)
   Group Key: project.id
   Buffers: shared hit=1698
   ->  Nested Loop  (cost=0.70..16756.28 rows=500000 width=12) (actual time=0.015..90.758 rows=499949 loops=1)
         Buffers: shared hit=1698
         ->  Limit  (cost=0.28..21.77 rows=500 width=4) (actual time=0.009..0.187 rows=500 loops=1)
               Buffers: shared hit=6
               ->  Index Only Scan using project_pkey on project  (cost=0.28..43.27 rows=1000 width=4) (actual time=0.008..0.134 rows=500 loops=1)
                     Heap Fetches: 500
                     Buffers: shared hit=6
         ->  Index Only Scan using task_project_fk_idx on task t  (cost=0.42..23.47 rows=1000 width=8) (actual time=0.004..0.080 rows=1000 loops=500)
               Index Cond: (project_id = project.id)
               Heap Fetches: 0
               Buffers: shared hit=1692
 Planning:
   Buffers: shared hit=8
 Planning Time: 0.119 ms
 Execution Time: 138.304 ms
(18 rows)

                                                                      QUERY PLAN                                                                      
------------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=0.70..26761.28 rows=500 width=36) (actual time=0.349..146.607 rows=500 loops=1)
   Group Key: project.id
   Buffers: shared hit=1698
   ->  Nested Loop  (cost=0.70..16756.28 rows=500000 width=12) (actual time=0.016..96.784 rows=499949 loops=1)
         Buffers: shared hit=1698
         ->  Limit  (cost=0.28..21.77 rows=500 width=4) (actual time=0.009..0.240 rows=500 loops=1)
               Buffers: shared hit=6
               ->  Index Only Scan using project_pkey on project  (cost=0.28..43.27 rows=1000 width=4) (actual time=0.009..0.184 rows=500 loops=1)
                     Heap Fetches: 500
                     Buffers: shared hit=6
         ->  Index Only Scan using task_project_fk_idx on task t  (cost=0.42..23.47 rows=1000 width=8) (actual time=0.005..0.085 rows=1000 loops=500)
               Index Cond: (project_id = project.id)
               Heap Fetches: 0
               Buffers: shared hit=1692
 Planning:
   Buffers: shared hit=8
 Planning Time: 0.139 ms
 Execution Time: 146.660 ms
(18 rows)
```

## Results - Limit 10 Offset 100

```
                                                                            QUERY PLAN                                                                             
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=5206.25..5726.81 rows=10 width=36) (actual time=39.818..42.969 rows=10 loops=1)
   Buffers: shared hit=122
   ->  GroupAggregate  (cost=0.70..52056.20 rows=1000 width=36) (actual time=0.616..42.957 rows=110 loops=1)
         Group Key: p.id
         Buffers: shared hit=122
         ->  Merge Join  (cost=0.70..32046.20 rows=1000000 width=12) (actual time=0.024..28.988 rows=109721 loops=1)
               Merge Cond: (p.id = t.project_id)
               Buffers: shared hit=122
               ->  Index Only Scan using project_pkey on project p  (cost=0.28..43.27 rows=1000 width=4) (actual time=0.014..0.059 rows=111 loops=1)
                     Heap Fetches: 111
                     Buffers: shared hit=3
               ->  Index Only Scan using task_project_fk_idx on task t  (cost=0.42..19500.42 rows=1000000 width=8) (actual time=0.007..11.577 rows=109721 loops=1)
                     Heap Fetches: 0
                     Buffers: shared hit=119
 Planning:
   Buffers: shared hit=14
 Planning Time: 0.258 ms
 Execution Time: 43.006 ms
(18 rows)

                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=5.00..564.36 rows=10 width=36) (actual time=0.370..3.328 rows=10 loops=1)
   Group Key: project.id
   Buffers: shared hit=36
   ->  Nested Loop  (cost=5.00..364.25 rows=10000 width=12) (actual time=0.041..2.231 rows=9890 loops=1)
         Buffers: shared hit=36
         ->  Limit  (cost=4.58..5.00 rows=10 width=4) (actual time=0.031..0.034 rows=10 loops=1)
               Buffers: shared hit=3
               ->  Index Only Scan using project_pkey on project  (cost=0.28..43.27 rows=1000 width=4) (actual time=0.009..0.027 rows=110 loops=1)
                     Heap Fetches: 110
                     Buffers: shared hit=3
         ->  Index Only Scan using task_project_fk_idx on task t  (cost=0.42..25.93 rows=1000 width=8) (actual time=0.006..0.092 rows=989 loops=10)
               Index Cond: (project_id = project.id)
               Heap Fetches: 0
               Buffers: shared hit=33
 Planning:
   Buffers: shared hit=8
 Planning Time: 0.134 ms
 Execution Time: 3.347 ms
(18 rows)

                                                                     QUERY PLAN                                                                     
----------------------------------------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=5.00..564.36 rows=10 width=36) (actual time=0.367..3.321 rows=10 loops=1)
   Group Key: project.id
   Buffers: shared hit=36
   ->  Nested Loop  (cost=5.00..364.25 rows=10000 width=12) (actual time=0.039..2.224 rows=9890 loops=1)
         Buffers: shared hit=36
         ->  Limit  (cost=4.58..5.00 rows=10 width=4) (actual time=0.030..0.033 rows=10 loops=1)
               Buffers: shared hit=3
               ->  Index Only Scan using project_pkey on project  (cost=0.28..43.27 rows=1000 width=4) (actual time=0.008..0.026 rows=110 loops=1)
                     Heap Fetches: 110
                     Buffers: shared hit=3
         ->  Index Only Scan using task_project_fk_idx on task t  (cost=0.42..25.93 rows=1000 width=8) (actual time=0.005..0.091 rows=989 loops=10)
               Index Cond: (project_id = project.id)
               Heap Fetches: 0
               Buffers: shared hit=33
 Planning:
   Buffers: shared hit=8
 Planning Time: 0.093 ms
 Execution Time: 3.337 ms
(18 rows)
```

