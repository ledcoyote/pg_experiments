drop schema sq_limit_test cascade;
create schema sq_limit_test;

-- create a project and a tasks table
create table sq_limit_test.project(
  id serial primary key
);

create table sq_limit_test.task(
  id serial primary key,
  status int,
  project_id int references sq_limit_test.project (id)
);

create index task_project_fk_idx
  on sq_limit_test.task (project_id, status);

