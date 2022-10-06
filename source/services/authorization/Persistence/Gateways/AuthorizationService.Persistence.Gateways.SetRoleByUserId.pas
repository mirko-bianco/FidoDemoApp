unit AuthorizationService.Persistence.Gateways.SetRoleByUserId;

interface

uses
  System.SysUtils,

  Fido.Utilities,
  Fido.Functional,

  AuthorizationService.Domain.Entities.UserRole,
  AuthorizationService.Persistence.Db.SetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf;

type
  TUpsertUserRoleByUserIdGateway = class(TInterfacedObject, IUpsertUserRoleByUserIdGateway)
  private
    FCommand: IUpsertUserRoleByUserIdCommand;
    function DoUpsertUSerRole(const UserRole: TUserRole): Integer;
  public
    constructor Create(const Command: IUpsertUserRoleByUserIdCommand);

    function Exec(const UserRole: TUserRole): Context<Integer>;
  end;

implementation

{ TUpsertUserRoleByUserIdGateway }

constructor TUpsertUserRoleByUserIdGateway.Create(const Command: IUpsertUserRoleByUserIdCommand);
begin
  inherited Create;

  FCommand := Utilities.CheckNotNullAndSet(Command, 'Command');
end;

function TUpsertUserRoleByUserIdGateway.DoUpsertUSerRole(const UserRole: TUserRole): Integer;
begin
  Result := FCommand.Exec(UserRole.Id.ToString, UserRole.Role);
end;

function TUpsertUserRoleByUserIdGateway.Exec(const UserRole: TUserRole): Context<Integer>;
begin
  Result := Context<TUserRole>.
    New(UserRole).
    Map<Integer>(DoUpsertUserRole);
end;

end.
