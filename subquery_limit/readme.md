# Applying Limits to a Query With Aggregations on Joined Tables

In this experiment we are interested in performance when we are joining two
tables together and performing aggregations on the results. In particular, we
have a case where we are aggregating counts on the joined table when placing a
limit on the outer table.

If we naively do a straight join and put the limit on the outermost query, we
get the correct result, and if there is no offset, then the performance is about
as good as we can get. However, if the limit is large we do end up counting a
large portion of the joined table, which can be slow.

>try `\set l 500` and `\set o 0`. The three queries perform similarly, but
rather slowly.

To compensate, we can use a very small limit, and do offset paging. This isn't
a very good method of paging (compared to, say some kind of cursor method or
perhaps using the
[seek technique](https://use-the-index-luke.com/sql/partial-results/fetch-next-page),
but it's simple. However, for the naive method of joining, we end up having to
read a lot of the joined table, especially as the page number gets higher, since
the database has to read and discard the offset rows when using this pagination
method.

>try `\set l 10` and `\set o 100`. The naive method has to join over a lot of
the task table. The buffers is large.

To do better, we can force the limit onto the outer table using a CTE or
subquery. The number rows produced are precisely the ones we will use for our
join and results in a much smaller number of total buffers read and an overall
fast execution time.

