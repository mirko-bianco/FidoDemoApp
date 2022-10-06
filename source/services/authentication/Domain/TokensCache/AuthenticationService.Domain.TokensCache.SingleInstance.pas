unit AuthenticationService.Domain.TokensCache.SingleInstance;

interface

uses
  System.SysUtils,
  System.Generics.Defaults,
  System.Hash,

  Spring.Collections,

  AuthenticationService.Domain.TokensCache.Abstract;

type
  TSingleInstanceServerTokensCache = class(TAbstractServerTokensCache)
  private
    FPairs: IDictionary<string, string>;
  protected
    procedure DoInvalidate(const UserId: TGuid); override;
    function DoDoesKeyExist(const UserId: TGuid; out ExistingRefreshToken: string): Boolean; override;
    procedure DoSetCache(const UserId: TGuid; const RefreshToken: string); override;
  public
    constructor Create;
  end;

implementation

{ TSingleInstanceServerTokensCache }

constructor TSingleInstanceServerTokensCache.Create;
begin
  inherited;

  FPairs := TCollections.CreateDictionary<string, string>;
end;

function TSingleInstanceServerTokensCache.DoDoesKeyExist(
  const UserId: TGuid;
  out ExistingRefreshToken: string): Boolean;
begin
  Result := FPairs.ContainsKey(UserId.ToString);
  if Result then
    ExistingRefreshToken := FPairs[UserId.ToString];
end;

procedure TSingleInstanceServerTokensCache.DoInvalidate(const UserId: TGuid);
begin
  FPairs.Remove(UserId.ToString);
end;

procedure TSingleInstanceServerTokensCache.DoSetCache(
  const UserId: TGuid;
  const RefreshToken: string);
begin
  FPairs[UserId.ToString] := RefreshToken
end;

end.

