unit FidoApp.Persistence.ApiClients.Configuration.Tokens;

interface

uses
  System.SysUtils,
  Rest.Types,

  Spring,

  Fido.Utilities,
  Fido.Types,
  Fido.Api.Client.VirtualApi.Attributes,
  Fido.Api.Client.VirtualApi.Intf,
  Fido.Api.Client.VirtualApi.Configuration.Intf,
  Fido.Api.Client.VirtualApi.Configuration,
  Fido.JSON.Marshalling,

  FidoApp.Constants,
  FidoApp.Types,
  FidoApp.Domain.ClientTokensCache.Intf;

type
  {$M+}
  ITokensAwareClientVirtualApiConfiguration = interface(IClientVirtualApiConfiguration)
    ['{B981EFDA-F80A-45B5-A8EF-91FCCFC98D38}']

    function GetAuthorization: string;
    [ApiParam(Constants.HEADER_REFRESHTOKEN)]
    function GetRefreshToken: string;

    procedure SetAuthorization(const Authorization: string);
    procedure SetRefreshToken(const RefreshToken: string);
  end;

  TTokensAwareClientVirtualApiConfiguration = class(TClientVirtualApiConfiguration, ITokensAwareClientVirtualApiConfiguration)
  private
    FCache: IClientTokensCache;
    FAccessToken: string;
    FRefreshToken: string;

    procedure ResetTokens;
    procedure SetTokens;
  public
    constructor Create(const BaseUrl: string; const Active: Boolean; const LiveEnvironment: Boolean; const Cache: IClientTokensCache);

    function GetAuthorization: string;
    function GetRefreshToken: string;

    procedure SetAuthorization(const Authorization: string);
    procedure SetRefreshToken(const RefreshToken: string);
  end;
  {$M-}

implementation

{ TTokensAwareClientVirtualApiConfiguration }

constructor TTokensAwareClientVirtualApiConfiguration.Create(
  const BaseUrl: string;
  const Active: Boolean;
  const LiveEnvironment: Boolean;
  const Cache: IClientTokensCache);
begin
  inherited Create(BaseUrl, Active, LiveEnvironment);

  FCache := Utilities.CheckNotNullAndSet(Cache, 'Cache');
end;

function TTokensAwareClientVirtualApiConfiguration.GetAuthorization: string;
begin
  Result := '';
  if Assigned(FCache.Tokens) then
    Result := Format('Bearer %s', [FCache.Tokens.AccessToken]);
end;

function TTokensAwareClientVirtualApiConfiguration.GetRefreshToken: string;
begin
  Result := '';
  if Assigned(FCache.Tokens) then
    Result := FCache.Tokens.RefreshToken;
end;

procedure TTokensAwareClientVirtualApiConfiguration.SetAuthorization(const Authorization: string);
var
  StrippedToken: string;
begin
  StrippedToken := Authorization.Replace('Bearer ', '');
  if FAccessToken.Equals(StrippedToken) then
    Exit;

  ResetTokens;
  FAccessToken := StrippedToken;
  SetTokens;
end;

procedure TTokensAwareClientVirtualApiConfiguration.SetRefreshToken(const RefreshToken: string);
begin
  if FRefreshToken.Equals(RefreshToken) then
    Exit;

  ResetTokens;
  FRefreshToken := RefreshToken;
  SetTokens;
end;

procedure TTokensAwareClientVirtualApiConfiguration.SetTokens;
begin
  if not (FAccessToken.IsEmpty or FRefreshToken.IsEmpty) and
     (not Assigned(FCache.Tokens) or
      (Assigned(FCache.Tokens) and
       not(FCache.Tokens.AccessToken.Equals(FAccessToken) and FCache.Tokens.RefreshToken.Equals(FRefreshToken)))) then
    FCache.SetTokens(JSONUnmarshaller.To<ITokens>(Format('{"AccessToken": "%s", "RefreshToken": "%s"}', [FAccessToken, FRefreshToken])));
end;

procedure TTokensAwareClientVirtualApiConfiguration.ResetTokens;
begin
  if not (FAccessToken.IsEmpty or FRefreshToken.IsEmpty) then
  begin
    FAccessToken := '';
    FRefreshToken := '';
  end;
end;

end.

