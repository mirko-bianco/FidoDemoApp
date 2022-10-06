unit AuthorizationService.Domain.UseCases.SetRoleByUserId;

interface

uses
  System.SysUtils,

  JOSE.Core.JWT,

  Spring,
  Spring.Collections,

  Fido.JSON.Marshalling,
  Fido.Functional,
  Fido.Functional.Tries,

  FidoApp.Constants,

  AuthorizationService.Domain.UseCases.ConvertToJWT.Intf,
  AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf,
  AuthorizationService.Domain.Repositories.UserRole.Intf,
  AuthorizationService.Domain.Entities.UserRole;

type
  IPermissions = IReadonlyList<string>;

  TSetRoleByUserIdUseCase = class(TInterfacedObject, ISetRoleByUserIdUseCase)
  private
    FRepositoryFactory: TFunc<IUserRoleRepository>;
    function DoSetUserRole(const UserRole: TUserRole): Context<Void>;
  public
    constructor Create(const RepositoryFactory: TFunc<IUserRoleRepository>);

    function Run(const UserRole: TUserRole): Context<Void>;
  end;

implementation

{ TSetRoleByUserIdUseCase }

constructor TSetRoleByUserIdUseCase.Create(
  const RepositoryFactory: TFunc<IUserRoleRepository>);
begin
  inherited Create;

  Guard.CheckTrue(Assigned(RepositoryFactory), 'RepositoryFactory');

  FRepositoryFactory := RepositoryFactory;
end;

function TSetRoleByUserIdUseCase.DoSetUserRole(const UserRole: TUserRole): Context<Void>;
begin
  Result := FRepositoryFactory().SetRoleByUserId(UserRole);
end;

function TSetRoleByUserIdUseCase.Run(const UserRole: TUserRole): Context<Void>;
begin
  Result := &Try<TUserRole>.
    New(UserRole).
    Map<Void>(DoSetUserRole).
    Match(ESetRoleByUserIdUseCaseFailure);
end;

end.
