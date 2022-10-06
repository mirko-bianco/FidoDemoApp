unit FidoApp.DI.Registration;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IniFiles,

  Spring,
  Spring.Container,

  Fido.Containers,
  Fido.Api.Client.VirtualApi.json,
  Fido.Jwt.Manager.Intf,
  Fido.KVStore.Intf,
  Fido.KVStore.Json,

  FidoApp.Types,
  FidoApp.Constants,
  FidoApp.Persistence.ApiClients.Authorization.V1.Intf,
  FidoApp.Persistence.ApiClients.Authentication.V1.Intf,
  FidoApp.Persistence.ApiClients.Users.V1.Intf,
  FidoApp.Persistence.Gateways.Authorization.Intf,
  FidoApp.Persistence.Gateways.Authorization,
  FidoApp.Persistence.Gateways.Authentication.Intf,
  FidoApp.Persistence.Gateways.Authentication,
  FidoApp.Persistence.Gateways.Users.Intf,
  FidoApp.Persistence.Gateways.Users,
  FidoApp.Persistence.Repositories.Authentication,
  FidoApp.Domain.Repositories.Authentication.Intf,
  FidoApp.Domain.ClientTokensCache.Intf,
  FidoApp.Domain.ClientTokensCache,
  FidoApp.Domain.Usecases.RefreshToken.Intf,
  FidoApp.Domain.Usecases.RefreshToken;

procedure RegisterAuthorizationApiV1(const Container: TContainer; const KVStore: IKVStore);

procedure RegisterAuthenticationApiV1(const Container: TContainer; const KVStore: IKVStore);

procedure RegisterUsersApiV1(const Container: TContainer; const KVStore: IKVStore);

procedure RegisterRefreshTokenUseCase(const Container: TContainer);

procedure RegisterTokensCache(const Container: TContainer);

implementation

procedure RegisterTokensCache(const Container: TContainer);
begin
  Container.RegisterType<IClientTokensCache>.DelegateTo(
    function: IClientTokensCache
    begin
      Result := TClientTokensCache.Create;
    end).AsSingleton;
end;

procedure RegisterAuthorizationApiV1(
  const Container: TContainer;
  const KVStore: IKVStore);
begin
  Container.RegisterType<IAuthorizationV1ApiClientConfiguration>.DelegateTo(
    function: IAuthorizationV1ApiClientConfiguration
    begin
      Result := TAuthorizationV1ApiClientConfiguration.Create(
        Format('%s:%d/authorization/api/1',
               [KVStore.Get('gateway.address', Constants.TIMEOUT).Value,
                JSONKVStore.Get<Integer>(KVStore, 'gateway.port', Constants.TIMEOUT)]),
        True,
        True,
        Container.Resolve<IClientTokensCache>);
    end).AsSingleton;

  Containers.RegisterJSONClientApi<IAuthorizationV1ApiClient, IAuthorizationV1ApiClientConfiguration>(Container);

  Container.RegisterType<IAuthorizationV1ApiClientGateway>.DelegateTo(
    function: IAuthorizationV1ApiClientGateway
    begin
      Result := TAuthorizationV1ApiClientGateway.Create(
        Container.Resolve<IAuthorizationV1ApiClient>,
        Constants.TIMEOUT)
    end);
end;

procedure RegisterAuthenticationApiV1(
  const Container: TContainer;
  const KVStore: IKVStore);
begin
  Container.RegisterType<IAuthenticationV1ApiClientConfiguration>.DelegateTo(
    function: IAuthenticationV1ApiClientConfiguration
    begin
      Result := TAuthenticationV1ApiClientConfiguration.Create(
        Format('%s:%d/authentication/api/1',
               [KVStore.Get('gateway.address', Constants.TIMEOUT).Value,
                JSONKVStore.Get<Integer>(KVStore, 'gateway.port', Constants.TIMEOUT)]),
        True,
        True,
        Container.Resolve<IClientTokensCache>);
    end).AsSingleton;

  Containers.RegisterJSONClientApi<IAuthenticationV1ApiClient, IAuthenticationV1ApiClientConfiguration>(Container);

  Container.RegisterType<IAuthenticationV1ApiClientGateway>.DelegateTo(
    function: IAuthenticationV1ApiClientGateway
    begin
      Result := TAuthenticationV1ApiClientGateway.Create(
        Container.Resolve<IAuthenticationV1ApiClient>,
        Constants.TIMEOUT)
    end);
end;

procedure RegisterUsersApiV1(
  const Container: TContainer;
  const KVStore: IKVStore);
begin
  Container.RegisterType<IUsersV1ApiClientConfiguration>.DelegateTo(
    function: IUsersV1ApiClientConfiguration
    begin
      Result := TUsersV1ApiClientConfiguration.Create(
        Format('%s:%d/users/api/1',
               [KVStore.Get('gateway.address', Constants.TIMEOUT).Value,
                JSONKVStore.Get<Integer>(KVStore, 'gateway.port', Constants.TIMEOUT)]),
        True,
        True,
        Container.Resolve<IClientTokensCache>);
    end).AsSingleton;

  Containers.RegisterJSONClientApi<IUsersV1ApiClient, IUsersV1ApiClientConfiguration>(Container);

  Container.RegisterType<IUsersV1ApiClientGateway>.DelegateTo(
    function: IUsersV1ApiClientGateway
    begin
      Result := TUsersV1ApiClientGateway.Create(
        Container.Resolve<IUsersV1ApiClient>,
        Constants.TIMEOUT)
    end);
end;

procedure RegisterRefreshTokenUseCase(const Container: TContainer);
begin
  Container.RegisterType<IAuthenticationRepository, TAuthenticationRepository>;
  Container.RegisterType<IRefreshTokenUseCase, TRefreshTokenUseCase>;
end;

end.
