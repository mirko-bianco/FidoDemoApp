unit FidoApp.Persistence.ApiClients.Users.V1.Intf;

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
  IUsersV1ApiClientConfiguration = interface(ITokensAwareClientVirtualApiConfiguration)
    ['{33CF9366-106A-4230-AD38-77F138DE56BA}']
  end;

  TUsersV1ApiClientConfiguration = class(TTokensAwareClientVirtualApiConfiguration, IUsersV1ApiClientConfiguration)
  end;

  IUsersV1ApiClient = interface(IClientVirtualApi)
    ['{42727F69-94B5-41F6-9919-3C4007877E40}']

    [Endpoint(rmGet, '/')]
    [HeaderParam(Constants.HEADER_AUTHORIZATION)]
    [HeaderParam('RefreshToken', Constants.HEADER_REFRESHTOKEN)]
	  function GetAll(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): IGetAllUsersV1Result;
  end;
  {$M-}

implementation

end.

