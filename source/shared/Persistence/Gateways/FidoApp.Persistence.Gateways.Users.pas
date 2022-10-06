unit FidoApp.Persistence.Gateways.Users;

interface

uses
  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Retries,
  Fido.DesignPatterns.Retries,

  FidoApp.Types,
  FidoApp.Persistence.Gateways.Users.Intf,
  FidoApp.Persistence.ApiClients.Users.V1.Intf;

type
  TUsersV1ApiClientGateway = class(TInterfacedObject, IUsersV1ApiClientGateway)
  private type
    TGetAllData = record
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
    FApi: IUsersV1ApiClient;
    FTimeout: Cardinal;
    function DoGetAll(const Params: TGetAllData): IGetAllUsersV1Result;

  public
    constructor Create(const Api: IUsersV1ApiClient; const Timeout: Cardinal = INFINITE);

    function GetAll(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<IGetAllUsersV1Result>;
  end;

implementation

{ TUsersV1ApiClientGateway }

constructor TUsersV1ApiClientGateway.Create(
  const Api: IUsersV1ApiClient;
  const Timeout: Cardinal = INFINITE);
begin
  inherited Create;

  FApi := Utilities.CheckNotNullAndSet(Api, 'Api');
  FTimeout := Timeout;
end;

function TUsersV1ApiClientGateway.DoGetAll(const Params: TGetAllData): IGetAllUsersV1Result;
begin
  Result := FApi.GetAll(Params.OrderBy, Params.Page, Params.Limit);
end;

function TUsersV1ApiClientGateway.GetAll(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer): Context<IGetAllUsersV1Result>;
begin
  Result := Retry<TGetAllData>.
    New(TGetAllData.Create(OrderBy, Page, Limit)).
    MapAsync<IGetAllUsersV1Result>(DoGetAll, FTimeout, False, Retries.GetRetriesOnExceptionFunc());
end;

{ TUsersV1ApiClientGateway.TGetData }

constructor TUsersV1ApiClientGateway.TGetAllData.Create(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer);
begin
  FOrderBy := OrderBy;
  FPage := Page;
  FLimit := Limit;
end;

end.
