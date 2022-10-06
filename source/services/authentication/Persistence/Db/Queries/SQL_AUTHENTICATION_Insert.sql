insert into 
  authentication.users
  (id, username, hashedpassword, active)
values
  (:id, :username, :hashedpassword, 0)