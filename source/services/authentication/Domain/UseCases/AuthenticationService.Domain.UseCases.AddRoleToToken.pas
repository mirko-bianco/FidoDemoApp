unit AuthenticationService.Domain.UseCases.AddRoleToToken;

interface

uses
  System.SysUtils,
  System.JSON,

  JOSE.Core.JWT,

  Spring,
  Spring.Collections,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.JSON.Marshalling,

  FidoApp.Constants,
  FidoApp.Types,

  AuthenticationService.Domain.UseCases.AddRoleToToken.Intf,
  AuthenticationService.Domain.Repositories.UserRole.Intf;

type
  TAddRoleToTokenUseCase = class(TInterfacedObject, IAddRoleToTokenUseCase)
  private var
    FRepositoryFactory: TFunc<IUserRoleRepository>;

    function UpdateAccessToken(const AccessToken: TJwt): Context<IUserRoleAndPermissions>.FunctorProc;
    function DoGetRoleAndPermissions(const AccessToken: TJWT): Context<Void>;
  public
    constructor Create(const RepositoryFactory: TFunc<IUserRoleRepository>);

    function Run(const AccessToken: TJWT): Context<Void>;
  end;

implementation

{ TUseCaseAddRoleToToken }

function TAddRoleToTokenUseCase.UpdateAccessToken(const AccessToken: TJwt): Context<IUserRoleAndPermissions>.FunctorProc;
begin
  Result := procedure(const UserRole: IUserRoleAndPermissions)
    var
      Permissions: TJsonArray;
    begin
      AccessToken.Claims.SetClaimOfType<string>(Constants.CLAIM_USERROLE, UserRole.Role);

      Permissions := TJsonArray.Create;
      UserRole.Permissions.ForEach(procedure(const Item: Permission)
        begin
          Permissions.Add(Integer(Item));
        end);
      AccessToken.Claims.JSON.AddPair(Constants.CLAIM_PERMISSIONS, Permissions);
    end;
end;

function TAddRoleToTokenUseCase.DoGetRoleAndPermissions(const AccessToken: TJWT): Context<Void>;
begin
  Result := FRepositoryFactory.GetByToken.Map<Void>(Void.MapProc<IUserRoleAndPermissions>(UpdateAccessToken(AccessToken)));
end;

function TAddRoleToTokenUseCase.Run(const AccessToken: TJWT): Context<Void>;
begin
  Result := &Try<TJWT>.
    New(AccessToken).
    Map<Void>(DoGetRoleAndPermissions).
    Match(EAddRoleToTokenUseCaseFailure);
end;

constructor TAddRoleToTokenUseCase.Create(const RepositoryFactory: TFunc<IUserRoleRepository>);
begin
  inherited Create;

  FRepositoryFactory := Utilities.CheckNotNullAndSet<TFunc<IUserRoleRepository>>(RepositoryFactory, 'RepositoryFactory');
end;

end.
