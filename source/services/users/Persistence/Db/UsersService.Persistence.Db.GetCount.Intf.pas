unit UsersService.Persistence.Db.GetCount.Intf;

interface

uses
  Spring.Collections,

  Fido.VirtualStatement.Intf,
  Fido.VirtualStatement.Attributes,

  UsersService.Persistence.Db.Types;

type
  [Statement(stScalarQuery, 'SQL_Users_Count')]
  IGetUsersCountQuery = interface(IVirtualStatement)
    ['{1E387A5B-67BF-454A-8E4D-FA24EB02BDF8}']

    function Open: Integer;
  end;

implementation

end.
