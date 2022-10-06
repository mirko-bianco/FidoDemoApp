unit AuthorizationService.Persistence.Db.GetRoleByUserId.Intf;

interface

uses
  Spring.Collections,

  Fido.VirtualQuery.Intf,
  Fido.VirtualQuery.Attributes;

type

  IUserRoleRecord = interface(IInvokable)
    ['{08CF06CD-902F-48F0-8648-1D0ADB3C6727}']

    function UserId: string;
    function Role: string;
  end;

  [SQLResource('SQL_AUTHORIZATION_Get')]
  IGetUserRoleByUserIdQuery = interface(IVirtualQuery)
    ['{218CEF98-1FA8-460A-859C-9DB5F35D23BF}']

    function Open(const UserId: string): IReadonlyList<IUserRoleRecord>;
  end;

implementation

end.
