unit UsersService.Persistence.Db.Remove.Intf;

interface

uses
  Fido.VirtualStatement.Intf,
  Fido.VirtualStatement.Attributes;

type

  [Statement(stCommand, 'SQL_Users_Delete')]
  IDeleteUserCommand = interface(IVirtualStatement)
    ['{C964322E-B99E-4007-9245-1E92746FDC04}']

    function Execute(const Id: string): Integer;
  end;

implementation

end.
