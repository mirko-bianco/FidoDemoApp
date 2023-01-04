unit UsersService.Presentation.Controllers.ApiServers.GetAll.V1;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Collections,

  Fido.Types,
  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Http.Types,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.Api.Server.Consul.Resource.Attributes,

  FidoApp.Constants,
  FidoApp.Types,

  UsersService.Domain.UseCases.GetAll.Intf,
  UsersService.Domain.Entities.User;

type
  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TGetAllV1ApiServerController = class(TObject)
  private type
    TGetAllInputParams = record
    private
      FOrderBy: TGetAllUsersOrderBy;
      FLimit: Integer;
      FOffset: Integer;
    public
      constructor Create(const OrderBy: TGetAllUsersOrderBy; const Limit: Integer; const Offset: Integer);

      property OrderBy: TGetAllUsersOrderBy read FOrderBy;
      property Limit: Integer read FLimit;
      property Offset: Integer read FOffset;
    end;
  private var
    FUseCase: IGetAllUseCase;

    function DoGetAllUsers(const Params: TGetAllInputParams): Context<TGetAllV1Result>;

  public
    constructor Create(const UseCase: IGetAllUseCase);

    [Path(rmGet, '/1')]
    [RequestMiddleware('Authenticated')]
    [RequestMiddleware('Authorized', Constants.PERMISSION_CAN_GET_ALL_USERS)]
    [ResponseMiddleware('ForwardTokens')]
    function Execute(const [QueryParam] OrderBy: TGetAllUsersOrderBy; const [QueryParam] Page: Integer; const [QueryParam] Limit: Integer): TGetAllV1Result;
  end;
  {$M-}

implementation

{ TGetAllV1ApiServerController }

function TGetAllV1ApiServerController.DoGetAllUsers(const Params: TGetAllInputParams): Context<TGetAllV1Result>;
begin
  Result := FUseCase.Run(Params.OrderBy, Params.Limit, Params.Offset);
end;

function TGetAllV1ApiServerController.Execute(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer): TGetAllV1Result;
begin
  Result := &Try<TGetAllInputParams>.
    New(TGetAllInputParams.Create(OrderBy, Page, Limit)).
    Map<TGetAllV1Result>(DoGetAllUsers).
    Match(function(const E: Exception): Nullable<TGetAllV1Result>
      begin
        if E.InheritsFrom(EGetAllUseCaseValidation) then
          raise EApiServer400.Create(E.Message);
      end);
end;

constructor TGetAllV1ApiServerController.Create(const UseCase: IGetAllUseCase);
begin
  inherited Create;

  FUseCase := Utilities.CheckNotNullAndSet(UseCase, 'UseCase');
end;

{ TGetAllV1ApiServerController.TGetAllInputParams }

constructor TGetAllV1ApiServerController.TGetAllInputParams.Create(
  const OrderBy: TGetAllUsersOrderBy;
  const Limit: Integer;
  const Offset: Integer);
begin
  FOrderBy := OrderBy;
  FLimit := Limit;
  FOffset := Offset;
end;

end.
