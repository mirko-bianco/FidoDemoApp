unit FidoApp.Domain.ClientTokensCache.Intf;

interface

uses
  FidoApp.Types,

  Fido.DesignPatterns.Observable.Intf;

type
  IClientTokensCache = interface(IObservable)
    ['{C1E93A1A-0E4A-4364-81F5-6DE9B33A5087}']

    procedure SetTokens(const Value: ITokens);
    function Tokens: ITokens;
  end;

implementation

end.
