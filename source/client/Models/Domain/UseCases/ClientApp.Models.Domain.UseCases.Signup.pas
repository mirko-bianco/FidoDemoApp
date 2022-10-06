unit ClientApp.Models.Domain.UseCases.Signup;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Functional,
  Fido.Utilities,
  Fido.Logging.Utils,

  ClientApp.Models.Domain.Usecases.Signup.Intf,
  ClientApp.Models.Domain.Repositories.Authentication.Intf,
  ClientApp.Models.Domain.Entities.SignupUser;

type
  TSignupUseCase = class(TInterfacedObject, ISignupUseCase)
  private
    FRepository: IAuthenticationRepository;
    FLogger: ILogger;
  public
    constructor Create(const Logger: ILogger; const Repository: IAuthenticationRepository);

    function Run(const User: TSignupUser): Context<Void>;
  end;

implementation

{ TSignupUseCase }

constructor TSignupUseCase.Create(
  const Logger: ILogger;
  const Repository: IAuthenticationRepository);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FRepository := Utilities.CheckNotNullAndSet(Repository, 'Repository');
end;

function TSignupUseCase.Run(const User: TSignupUser): Context<Void>;
begin
  User.Validate;
  Result := Logging.LogDuration<Context<Void>>(
    FLogger,
    ClassName,
    'Run',
    function: Context<Void>
    begin
      Result := FRepository.Signup(User);
    end);
end;

end.
