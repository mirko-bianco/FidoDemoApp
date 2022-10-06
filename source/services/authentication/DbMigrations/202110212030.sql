create table if not exists authentication.users (
  id varchar(100) unique not null primary key, 
  username varchar(100) unique not null, 
  hashedpassword varchar(100) not null,
  active integer not null default 1
);