unit AuthenticationService.Domain.TokensCache.Abstract;

interface

uses
  System.SysUtils,

  AuthenticationService.Domain.TokensCache.Intf;

type
  TAbstractServerTokensCache = class abstract (TInterfacedObject, IServerTokensCache)
  protected
    procedure DoInvalidate(const UserId: TGuid); virtual; abstract;
    function DoDoesKeyExist(const UserId: TGuid; out ExistingRefreshToken: string): Boolean; virtual; abstract;
    procedure DoSetCache(const UserId: TGuid; const RefreshToken: string); virtual; abstract;
  public

    procedure Invalidate(const UserId: TGuid);
    function Validate(const UserId: TGuid; const RefreshToken: string): Boolean;
  end;

implementation

{ TAbstractServerTokensCache }

procedure TAbstractServerTokensCache.Invalidate(const UserId: TGuid);
begin
  DoInvalidate(UserId);
end;

function TAbstractServerTokensCache.Validate(
  const UserId: TGuid;
  const RefreshToken: string): Boolean;
var
  ExistingRefreshToken: string;
begin
  Result := True;
  if not DoDoesKeyExist(UserId, ExistingRefreshToken) then
    DoSetCache(UserId, RefreshToken)
  else if not ExistingRefreshToken.Equals(RefreshToken) then
  begin
    Invalidate(UserId);
    Result := False;
  end;
end;

end.

