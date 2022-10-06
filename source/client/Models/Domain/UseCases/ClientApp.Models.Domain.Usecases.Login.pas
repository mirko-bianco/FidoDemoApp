unit ClientApp.Models.Domain.Usecases.Login;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.DesignPatterns.Retries,
  Fido.Logging.Utils,

  ClientApp.Models.Domain.Usecases.Login.Intf,
  ClientApp.Models.Domain.Repositories.Authentication.Intf,
  ClientApp.Models.Domain.Entities.LoginUser;

type
  TLoginUseCase = class(TInterfacedObject, ILoginUseCase)
  private
    FRepository: IAuthenticationRepository;
    FLogger: ILogger;
  public
    constructor Create(const Logger: ILogger; const Repository: IAuthenticationRepository);

    function Run(const User: TLoginUser): Context<Void>;
  end;

implementation

{ TLoginUseCase }

constructor TLoginUseCase.Create(
  const Logger: ILogger;
  const Repository: IAuthenticationRepository);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FRepository := Utilities.CheckNotNullAndSet(Repository, 'Repository');
end;

function TLoginUseCase.Run(const User: TLoginUser): Context<Void>;
var
  Repository: IAuthenticationRepository;
begin
  Repository := FRepository;

  Result := Logging.LogDuration<Context<Void>>(
    FLogger,
    ClassName,
    'Run',
    function: Context<Void>
    begin
      Result := Repository.Login(User);
    end);
end;

end.
