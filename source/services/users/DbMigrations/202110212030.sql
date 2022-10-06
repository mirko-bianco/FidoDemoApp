create table if not exists users.users (
  id varchar(100) unique not null primary key, 
  firstname varchar(100) not null, 
  lastname varchar(100) not null,
  active integer not null default 1
);