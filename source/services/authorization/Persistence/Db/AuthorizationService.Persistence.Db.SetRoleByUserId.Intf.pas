unit AuthorizationService.Persistence.Db.SetRoleByUserId.Intf;

interface

uses
  Fido.VirtualStatement.Intf,
  Fido.VirtualStatement.Attributes;

type

  [Statement(stCommand, 'SQL_AUTHORIZATION_Upsert')]
  IUpsertUserRoleByUserIdCommand = interface(IVirtualStatement)
    ['{6C2C3464-F536-4811-9C54-F03CDAF41110}']

    function Exec(const UserId: string; const Role: string): Integer;
  end;

implementation

end.
