unit AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf;

interface

uses
  System.SysUtils,

  Spring.Collections,

  Fido.Functional,

  FidoApp.Types;

type
  EGetRoleByUserIdUseCase = class abstract (Exception);

  EGetRoleByUserIdUseCaseFailure = class(EGetRoleByUserIdUseCase);

  EGetRoleByUserIdUseCaseUnauthorized = class(EGetRoleByUserIdUseCase);

  TUserRoleAndPermissions = record
  private
    FRole: string;
    FPermissions: IReadonlyList<Permission>;
  public
    constructor Create(const Role: string; const Permissions: IReadonlyList<Permission>);

    function Role: string;
    function Permissions: IReadonlyList<Permission>;
  end;

  IGetRoleByUserIdUseCase = interface(IInvokable)
    ['{4E8D6EF3-C63A-4580-8F98-247C778A3003}']

    function Run(const Authorization: string): Context<TUserRoleAndPermissions>;
  end;

implementation

{ TUserRole }

constructor TUserRoleAndPermissions.Create(const Role: string; const Permissions: IReadonlyList<Permission>);
begin
  FRole := Role;
  FPermissions := Permissions;
end;

function TUserRoleAndPermissions.Permissions: IReadonlyList<Permission>;
begin
  Result := FPermissions;
end;

function TUserRoleAndPermissions.Role: string;
begin
  Result := FRole;
end;

end.
