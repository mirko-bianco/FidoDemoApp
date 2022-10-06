unit FidoApp.Persistence.Repositories.Authentication;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Retries,
  Fido.Functional.Tries,
  Fido.DesignPatterns.Retries,

  FidoApp.Persistence.Gateways.Authentication.Intf,
  FidoApp.Domain.Repositories.Authentication.Intf;

type
  TAuthenticationRepository = class(TInterfacedObject, IAuthenticationRepository)
  private
    FGateway: IAuthenticationV1ApiClientGateway;
    function DoRefreshToken: Context<Void>;
  public
    constructor Create(const Gateway: IAuthenticationV1ApiClientGateway);

    function RefreshToken: Context<Void>;
  end;

implementation

{ TAuthenticationRepository }

constructor TAuthenticationRepository.Create(const Gateway: IAuthenticationV1ApiClientGateway);
begin
  inherited Create;

  FGateway := Utilities.CheckNotNullAndSet(Gateway, 'Gateway');
end;

function TAuthenticationRepository.DoRefreshToken: Context<Void>;
begin
  Result := FGateway.RefreshToken;
end;

function TAuthenticationRepository.RefreshToken: Context<Void>;
begin
  Result := Retry.Map<Void>(Context<Void>.New(function: Void
    begin
      Result := DoRefreshToken;
    end), Retries.GetRetriesOnExceptionFunc());
end;

end.

