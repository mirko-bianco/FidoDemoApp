unit AuthorizationService.Persistence.Gateways.GetRoleByUserId;

interface

uses
  Fido.Exceptions,
  Fido.Utilities,
  Fido.Functional,

  Spring.Collections,

  AuthorizationService.Persistence.Db.GetRoleByUserId.Intf,
  AuthorizationService.Persistence.Gateways.GetRoleByUserId.Intf,
  AuthorizationService.Domain.Entities.UserRole;

type
  EGetUserRoleByUserIdGateway = class(EFidoException);

  TGetUserRoleByUserIdGateway = class(TInterfacedObject, IGetUserRoleByUserIdGateway)
  private
    FQuery: IGetUserRoleByUserIdQuery;

    function ExtractUserRoleRecord(const List: IReadOnlyList<IUserRoleRecord>): IUserRoleRecord;
    function ConvertToUserRole(const Data: IUserRoleRecord): TUserRole;
    function GetUserRole(const UserId: string): IReadonlyList<IUserRoleRecord>;
  public
    constructor Create(const Query: IGetUserRoleByUserIdQuery);

    function Open(const UserId: string): Context<TUserRole>;
  end;

implementation

{ TGetUserRoleByUserIdGateway }

constructor TGetUserRoleByUserIdGateway.Create(const Query: IGetUserRoleByUserIdQuery);
begin
  inherited Create;
  FQuery := Utilities.CheckNotNullAndSet(Query, 'Query');
end;

function TGetUserRoleByUserIdGateway.ExtractUserRoleRecord(const List: IReadOnlyList<IUserRoleRecord>): IUserRoleRecord;
begin
  if List.Count <> 1 then
    Exit(nil);

  Result := List[0];
end;

function TGetUserRoleByUserIdGateway.ConvertToUserRole(const Data: IUserRoleRecord): TUserRole;
begin
  if not Assigned(Data) then
    Exit(Default(TUserRole));

  Result := TUserRole.Create(TGuid.Empty, Data.Role);
end;

function TGetUserRoleByUserIdGateway.GetUserRole(const UserId: string): IReadonlyList<IUserRoleRecord>;
begin
  Result := FQuery.Open(UserId);
end;

function TGetUserRoleByUserIdGateway.Open(const UserId: string): Context<TUserRole>;
begin
  Result := Context<string>.
    New(UserId).
    Map<IReadonlyList<IUserRoleRecord>>(GetUserRole).
    Map<IUserRoleRecord>(ExtractUserRoleRecord).
    Map<TUserRole>(ConvertToUserRole);
end;

end.
