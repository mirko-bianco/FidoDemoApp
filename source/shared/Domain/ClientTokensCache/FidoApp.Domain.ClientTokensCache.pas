unit FidoApp.Domain.ClientTokensCache;

interface

uses
  System.SysUtils,
  System.Classes,

  Spring,

  Fido.Exceptions,
  Fido.Boxes,
  Fido.DesignPatterns.Observable.Delegated,
  Fido.DesignPatterns.Observer.Notification.Intf,

  FidoApp.Types,
  FidoApp.Messages,
  FidoApp.Domain.ClientTokensCache.Intf;

type
  EClientTokenCache = class(EFidoException);

  TClientTokensCache = class(TDelegatedObservable, IClientTokensCache)
  private type
    TData = record
    private
      FAccessToken: string;
      FRefreshToken: string;
    public
      constructor Create(const AccessToken: string; const RefreshToken: string);

      property AccessToken: string read FAccessToken;
      property RefreshToken: string read FRefreshToken;
    end;
  private var
    FData: IBox<TData>;

    procedure DoSetTokens(const Data: IBox<TData>; const Value: ITokens);
  public
    constructor Create;

    procedure SetTokens(const Value: ITokens);
    function Tokens: ITokens;
  end;

implementation

Type
  TTokens = class(TInterfacedObject, ITokens)
  strict private
    FAccessToken: string;
    FRefreshToken: string;
  public
    constructor Create(const AccessToken: string; const RefreshToken: string);

    function AccessToken: string;
    function RefreshToken: string;
  end;

{ TTokensCache }

constructor TClientTokensCache.Create;
var
  Data: TData;
begin
  inherited Create(nil);
  FData := Box<TData>.Setup(Data);
end;

procedure TClientTokensCache.SetTokens(const Value: ITokens);
begin
  if Tokens = Value then
    Exit;

  DoSetTokens(FData, Value);
end;

function TClientTokensCache.Tokens: ITokens;
begin
  if FData.Value.AccessToken.IsEmpty then
    Exit(nil);
  Result := TTokens.Create(FData.Value.AccessToken, FData.Value.RefreshToken);
end;

procedure TClientTokensCache.DoSetTokens(
  const Data: IBox<TData>;
  const Value: ITokens);
var
  LData: TData;
begin
  if Assigned(Value) then
    LData := TData.Create(Value.AccessToken, Value.RefreshToken);

  Data.UpdateValue(LData);
  Broadcast(LOGGED_MESSAGE, TValue.From<TArray<TValue>>([Assigned(Value)]));
end;

{ TTokens }

function TTokens.AccessToken: string;
begin
  Result := FAccessToken;
end;

constructor TTokens.Create(
  const AccessToken: string;
  const RefreshToken: string);
begin
  inherited Create;
  FAccessToken := AccessToken;
  FRefreshToken := RefreshToken;
end;

function TTokens.RefreshToken: string;
begin
  Result := FRefreshToken;
end;

{ TClientTokensCache.TData }

constructor TClientTokensCache.TData.Create(
  const AccessToken: string;
  const RefreshToken: string);
begin
  FAccessToken := AccessToken;
  FRefreshToken := RefreshToken;
end;

end.
