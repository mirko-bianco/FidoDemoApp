unit AuthorizationService.Domain.UseCases.GetRoleByUserId;

interface

uses
  System.SysUtils,

  JOSE.Core.JWT,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,

  FidoApp.Constants,

  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf,
  AuthorizationService.Domain.UseCases.GetRoleByUserId.Intf,
  AuthorizationService.Domain.Repositories.UserRole.Intf,
  AuthorizationService.Domain.ValueObjects.RolesAndPermissions;

type
  TGetRoleByUserIdUseCase = class(TInterfacedObject, IGetRoleByUserIdUseCase)
  private
    FRepositoryFactory: TFunc<IUserRoleRepository>;
    FConvertToJWTUseCase: IConvertToJWTUseCase;

    function OverrideRole(const Role: string): string;
    function ConvertToUserRole(const Role: string): TUserRoleAndPermissions;
    function DoConvertToJwt(const Authorization: string): Context<TJwt>;
    function DoGetRole(const Jwt: TJwt): Context<string>;
  public
    constructor Create(const RepositoryFactory: TFunc<IUserRoleRepository>; const ConvertToJWTUseCase: IConvertToJWTUseCase);

    function Run(const Authorization: string): Context<TUserRoleAndPermissions>;
  end;

implementation

{ TGetRoleByUserIdUseCase }

constructor TGetRoleByUserIdUseCase.Create(
  const RepositoryFactory: TFunc<IUserRoleRepository>;
  const ConvertToJWTUseCase: IConvertToJWTUseCase);
begin
  inherited Create;

  FRepositoryFactory := Utilities.CheckNotNullAndSet<TFunc<IUserRoleRepository>>(RepositoryFactory, 'RepositoryFactory');
  FConvertToJWTUseCase := Utilities.CheckNotNullAndSet(ConvertToJWTUseCase, 'ConvertToJWTUseCase');
end;

function TGetRoleByUserIdUseCase.OverrideRole(const Role: string): string;
begin
  if Role.IsEmpty then
    Exit(Constants.ROLE_DEFAULT);

  Result := Role;
end;

function TGetRoleByUserIdUseCase.ConvertToUserRole(const Role: string): TUserRoleAndPermissions;
begin
  Result := TUserRoleAndPermissions.Create(Role, TRolesAndPermissions.AvailableRoles[Role]);
end;

function TGetRoleByUserIdUseCase.DoConvertToJwt(const Authorization: string): Context<TJwt>;
begin
  Result := FConvertToJWTUseCase.Run(Authorization);
end;

function TGetRoleByUserIdUseCase.DoGetRole(const Jwt: TJwt): Context<string>;
begin
  Result := FRepositoryFactory().GetRoleByUserId(TGuid.Create(JWT.Claims.JSON.GetValue(Constants.CLAIM_USERID).Value.DeQuotedString('"')));
  Jwt.Free;
end;

function TGetRoleByUserIdUseCase.Run(const Authorization: string): Context<TUserRoleAndPermissions>;
begin
  Result := &Try<TJwt>.
    New(&Try<string>.
      New(Authorization).
      Map<TJWT>(DoConvertToJwt).
      Match(EGetRoleByUserIdUseCaseUnauthorized)).
    Map<string>(DoGetRole).
    Match(EGetRoleByUserIdUseCaseFailure).
    Map<string>(OverrideRole).
    Map<TUSerRoleAndPermissions>(ConvertToUserRole);
end;

end.
