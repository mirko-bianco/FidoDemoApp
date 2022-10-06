create table if not exists authorization.userroles (
  userid varchar(100) unique not null primary key, 
  role varchar(100) not null
);