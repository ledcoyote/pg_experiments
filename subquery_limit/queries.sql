\set l 10
\set o 100
\set sort 'asc'

-- naive
explain (analyze, buffers)
select
  p.id,
  count(t.project_id) filter (where t.status = 0) as "status_0",
  count(t.project_id) filter (where t.status = 1) as "status_1",
  count(t.project_id) filter (where t.status = 2) as "status_2",
  count(t.project_id) as "total"
from sq_limit_test.project as p
join sq_limit_test.task as t
  on t.project_id = p.id
group by p.id
order by p.id :sort
limit :l offset :o;

-- CTE
explain (analyze, buffers)
with p as (
  select id
  from sq_limit_test.project
  order by id :sort
  limit :l offset :o)
select
  p.id,
  count(t.project_id) filter (where t.status = 0) as "status_0",
  count(t.project_id) filter (where t.status = 1) as "status_1",
  count(t.project_id) filter (where t.status = 2) as "status_2",
  count(t.project_id) as "total"
from p
join sq_limit_test.task as t
  on t.project_id = p.id
group by p.id;

-- subquery
explain (analyze, buffers)
select
  p.id,
  count(t.project_id) filter (where t.status = 0) as "status_0",
  count(t.project_id) filter (where t.status = 1) as "status_1",
  count(t.project_id) filter (where t.status = 2) as "status_2",
  count(t.project_id) as "total"
from (
  select id
  from sq_limit_test.project
  order by id :sort
  limit :l offset :o) as p
join sq_limit_test.task as t
  on t.project_id = p.id
group by p.id;
