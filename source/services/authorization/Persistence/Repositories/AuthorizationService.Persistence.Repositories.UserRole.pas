unit AuthorizationService.Persistence.Repositories.UserRole;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Collections,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,

  AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.SetRoleByUserId.Intf,
  AuthorizationService.Domain.Entities.UserRole,
  AuthorizationService.Domain.Repositories.UserRole.Intf;

type
  TUserRoleRepository = class(TInterfacedObject, IUserRoleRepository)
  private
    FGetGateway: IGetUserRoleByUserIdGateway;
    FSetGateway: IUpsertUserRoleByUserIdGateway;
    function ExtractRole(const Data: TUserRole): string;
    function Upsert(const UserRole: TUserRole): Context<Integer>;
    procedure CheckAffectedRecord(const AffectedRecords: Integer);
    function DoUpsert(const UserRole: TUserRole): Context<Integer>;
  public
    constructor Create(
      const GetGateway: IGetUserRoleByUserIdGateway;
      const SetGateway: IUpsertUserRoleByUserIdGateway);

    function GetRoleByUserId(const UserId: TGuid): Context<string>;
    function SetRoleByUserId(const UserRole: TUserRole): Context<Void>;
  end;

implementation

{ TGetRoleByUserIdRepository }

constructor TUserRoleRepository.Create(
  const GetGateway: IGetUserRoleByUserIdGateway;
  const SetGateway: IUpsertUserRoleByUserIdGateway);
begin
  inherited Create;

  FGetGateway := Utilities.CheckNotNullAndSet(GetGateway, 'GetGateway');
  FSetGateway := Utilities.CheckNotNullAndSet(SetGateway, 'SetGateway');
end;

function TUserRoleRepository.ExtractRole(const Data: TUserRole): string;
var
  Role: TUserRole;
begin
  Role := Data;

  if not Data.Initialized then
    Exit('');

  Result := Data.Role;
end;

function TUserRoleRepository.GetRoleByUserId(const UserId: TGuid): Context<string>;
begin
  Result := &Try<TUserRole>.
    New(FGetGateway.Open(UserId.ToString)).
    Map<string>(ExtractRole).
    Match(EUserRoleRepository, Format('Error while retrieving role for user "%s". %s', [UserId.ToString, 'Error message: %s']));
end;

function TUserRoleRepository.DoUpsert(const UserRole: TUserRole): Context<Integer>;
begin
  result := FSetGateway.Exec(UserRole);
end;

function TUserRoleRepository.Upsert(const UserRole: TUserRole): Context<Integer>;
begin
  Result := &Try<TUserRole>.
    New(UserRole).
    Map<Integer>(DoUpsert).
    Match(EUserRoleRepository, Format('Error while changing role for user "%s". %s', [UserRole.Id.ToString, 'Error message: %s']));
end;

procedure TUserRoleRepository.CheckAffectedRecord(const AffectedRecords: Integer);
begin
  if AffectedRecords <> 1 then
    raise EUserRoleRepository.CreateFmt('%d Records where affected', [AffectedRecords]);
end;

function TUserRoleRepository.SetRoleByUserId(const UserRole: TUserRole): Context<Void>;
begin
  Result := Context<TUserRole>.
    New(UserRole).
    Map<Integer>(Upsert).
    Map<Void>(Void.MapProc<Integer>(CheckAffectedRecord));
end;

end.

