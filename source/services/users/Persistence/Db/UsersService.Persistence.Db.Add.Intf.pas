unit UsersService.Persistence.Db.Add.Intf;

interface

uses
  Fido.VirtualStatement.Intf,
  Fido.VirtualStatement.Attributes;

type

  [Statement(stCommand, 'SQL_Users_Insert')]
  IInsertUserCommand = interface(IVirtualStatement)
    ['{F2482C88-AC0A-420E-983D-4DF60E4E1FEF}']

    function Execute(const Id: string; const FirstName: string; const LastName: string): Integer;
  end;

implementation

end.
