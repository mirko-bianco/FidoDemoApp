unit FidoApp.Presentation.Controllers.ApiServers.Health;

interface

uses
  System.JSON,

  Spring,

  Fido.Types,
  Fido.Http.Types,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  THealthApiServerController = class(TObject)
  public
    [Path(rmGet, '/health')]
    [ConsulHealthCheck]
    [ExcludeGlobalMiddleware]
    function Default: TResult<string>;
  end;
  {$M-}

implementation

{ THealthApiServerController }

function THealthApiServerController.Default: TResult<string>;
begin
  Result := TResult<string>.CreateSuccess('It Works!');
end;

end.
