insert into authorization.userroles (userid, role) VALUES(:userid, :role)
  ON DUPLICATE KEY UPDATE role = :role;