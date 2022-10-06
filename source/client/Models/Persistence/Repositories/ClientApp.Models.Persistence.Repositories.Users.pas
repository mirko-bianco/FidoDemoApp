unit ClientApp.Models.Persistence.Repositories.Users;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Retries,
  Fido.Types,
  Fido.DesignPatterns.Retries,

  FidoApp.Types,
  FidoApp.Persistence.Gateways.Users.Intf,

  ClientApp.Models.Domain.Repositories.Users.Intf;

type
  TUsersRepository = class(TInterfacedObject, IUsersRepository)
  private type
    TGetAllInputParams = record
    private
      FOrderBy: TGetAllUsersOrderBy;
      FPage: Integer;
      FLimit: Integer;
    public
      constructor Create(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer);

      property OrderBy: TGetAllUsersOrderBy read FOrderBy;
      property Page: Integer read FPage;
      property Limit: Integer read FLimit;

    end;
  private var
    FGateway: IUsersV1ApiClientGateway;

    function DoGetAll(const Params: TGetAllInputParams): Context<IGetAllUsersV1Result>;
  public
    constructor Create(const Gateway: IUsersV1ApiClientGateway);

    function GetAll(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<IGetAllUsersV1Result>;
  end;

implementation

{ TUsersRepository }

constructor TUsersRepository.Create(const Gateway: IUsersV1ApiClientGateway);
begin
  inherited Create;

  FGateway := Utilities.CheckNotNullAndSet(Gateway, 'Gateway');
end;

function TUsersRepository.DoGetAll(const Params: TGetAllInputParams): Context<IGetAllUsersV1Result>;
begin
  Result := FGateway.GetAll(Params.OrderBy, Params.Page, Params.Limit);
end;

function TUsersRepository.GetAll(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer): Context<IGetAllUsersV1Result>;
begin
  Result := Retry<TGetAllInputParams>.
    New(TGetAllInputParams.Create(OrderBy, Page, Limit)).
    Map<IGetAllUsersV1Result>(DoGetAll, Retries.GetRetriesOnExceptionFunc());
end;

{ TUsersRepository.TGetAllInputParams }

constructor TUsersRepository.TGetAllInputParams.Create(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer);
begin
  FOrderBy := OrderBy;
  FPage := Page;
  FLimit := Limit;
end;

end.
