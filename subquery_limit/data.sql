-- insert 1000 projects
insert into sq_limit_test.project
  select generate_series(0, 999);

-- insert 1,000,000 tasks
insert into sq_limit_test.task (project_id, status)
  select floor(random()*1000), floor(random()*3)
  from  generate_series(0, 999_999);

analyze;
  
