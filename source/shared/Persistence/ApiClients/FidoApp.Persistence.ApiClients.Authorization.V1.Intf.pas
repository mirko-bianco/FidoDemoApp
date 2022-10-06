unit FidoApp.Persistence.ApiClients.Authorization.V1.Intf;

interface

uses
  System.SysUtils,
  Spring,

  Fido.Types,
  Fido.Http.Types,
  Fido.Api.Client.VirtualApi.Attributes,
  Fido.Api.Client.VirtualApi.Intf,
  Fido.Api.Client.VirtualApi.Configuration.Intf,
  Fido.Api.Client.VirtualApi.Configuration,

  FidoApp.Constants,
  FidoApp.Types,
  FidoApp.Persistence.ApiClients.Configuration.Tokens;

type
  {$M+}
  IAuthorizationV1ApiClientConfiguration = interface(ITokensAwareClientVirtualApiConfiguration)
    ['{5467AAD1-41F8-4772-87FB-3FCF6F39930B}']
  end;

  TAuthorizationV1ApiClientConfiguration = class(TTokensAwareClientVirtualApiConfiguration, IAuthorizationV1ApiClientConfiguration)
  end;

  IAuthorizationV1ApiClient = interface(IClientVirtualApi)
    ['{B3949100-FF1E-478C-9825-E85DBC9F5FED}']

    [Endpoint(rmGet, '/role')]
    [HeaderParam(Constants.HEADER_AUTHORIZATION)]
    [HeaderParam('RefreshToken', Constants.HEADER_REFRESHTOKEN)]
	  function GetRole: IUserRoleAndPermissions;
  end;
  {$M-}

implementation

end.

