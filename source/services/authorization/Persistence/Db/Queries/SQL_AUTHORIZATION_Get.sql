select
  userid,
  role
from
  authorization.userroles
where
  userid = :userid