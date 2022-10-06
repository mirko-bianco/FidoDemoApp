select
  id,
  username,
  hashedpassword
from
  authentication.users
where
  username = :username and
  hashedpassword = :hashedpassword and 
  active = 1