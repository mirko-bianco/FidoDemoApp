unit AuthenticationService.Domain.TokensCache.Intf;

interface

type
  IServerTokensCache = interface(IInvokable)
    ['{4C70A227-69EB-428B-93E5-5816DDF6A8C4}']

    procedure Invalidate(const UserId: TGuid);
    function Validate(const UserId: TGuid; const RefreshToken: string): Boolean;
  end;

implementation

end.
