unit AuthenticationService.Persistence.Db.Signup.Intf;

interface

uses
  Fido.VirtualStatement.Intf,
  Fido.VirtualStatement.Attributes;

type

  [Statement(stCommand, 'SQL_AUTHENTICATION_Insert')]
  IInsertUserCommand = interface(IVirtualStatement)
    ['{F2482C88-AC0A-420E-983D-4DF60E4E1FEF}']

    function Execute(const Id: string; const Username: string; const HashedPassword: string): Integer;
  end;

implementation

end.
