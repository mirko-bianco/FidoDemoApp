unit AuthenticationService.Domain.TokensCache.KVStore;

interface

uses
  System.SysUtils,

  Fido.Utilities,
  Fido.KVStore.Intf,

  FidoApp.Constants,

  AuthenticationService.Domain.TokensCache.Abstract;

type
  TKVStoreServerTokensCache = class(TAbstractServerTokensCache)
  private
    FKVStore: IKVStore;
  protected
    procedure DoInvalidate(const UserId: TGuid); override;
    function DoDoesKeyExist(const UserId: TGuid; out ExistingRefreshToken: string): Boolean; override;
    procedure DoSetCache(const UserId: TGuid; const RefreshToken: string); override;
  public
    constructor Create(const KVStore: IKVStore);
  end;

implementation

{ TKVStoreServerTokensCache }

constructor TKVStoreServerTokensCache.Create(const KVStore: IKVStore);
begin
  inherited Create;

  FKVStore := Utilities.CheckNotNullAndSet(KVStore, 'KVStore');
end;

function TKVStoreServerTokensCache.DoDoesKeyExist(
  const UserId: TGuid;
  out ExistingRefreshToken: string): Boolean;
begin
  ExistingRefreshToken := FKVStore.Get(UserId.ToString, Constants.TIMEOUT);
  Result := not ExistingRefreshToken.IsEmpty;
end;

procedure TKVStoreServerTokensCache.DoInvalidate(const UserId: TGuid);
begin
  FKVStore.Delete(UserId.ToString, Constants.TIMEOUT).Value;
end;

procedure TKVStoreServerTokensCache.DoSetCache(
  const UserId: TGuid;
  const RefreshToken: string);
begin
  FKVStore.Put(UserId.ToString, RefreshToken, Constants.TIMEOUT).Value;
end;

end.

