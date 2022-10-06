unit ClientApp.Models.Domain.Usecases.GetAllUsers;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Exceptions,
  Fido.Functional,
  Fido.DesignPatterns.Retries,
  Fido.Logging.Utils,

  FidoApp.Types,

  ClientApp.Models.Domain.Usecases.GetAllUsers.Intf,
  ClientApp.Models.Domain.Repositories.Users.Intf;

type
  TGetAllUsersUseCase = class(TInterfacedObject, IGetAllUsersUseCase)
  private
    FRepository: IUsersRepository;
    FLogger: ILogger;
  public
    constructor Create(const Logger: ILogger; const Repository: IUsersRepository);

    function Run(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<IGetAllUsersV1Result>;
  end;

implementation

{ TGetAllUsersUseCase }

constructor TGetAllUsersUseCase.Create(
  const Logger: ILogger;
  const Repository: IUsersRepository);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FRepository := Utilities.CheckNotNullAndSet(Repository, 'Repository');
end;

function TGetAllUsersUseCase.Run(
  const OrderBy: TGetAllUsersOrderBy;
  const Page: Integer;
  const Limit: Integer): Context<IGetAllUsersV1Result>;
begin
  Result := Logging.LogDuration<Context<IGetAllUsersV1Result>>(
    FLogger,
    ClassName,
    'Run',
    function: Context<IGetAllUsersV1Result>
    begin
      Result := FRepository.GetAll(OrderBy, Page, Limit);
    end);
end;

end.
