unit ClientApp.Models.Domain.Usecases.ShowLoginView;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Types,
  Fido.Utilities,
  Fido.Logging.Utils,
  Fido.DesignPatterns.Observer.Intf,

  ClientApp.Views.Login.Intf,
  ClientApp.Models.Domain.Usecases.ShowLoginView.Intf;

type
  TShowLoginViewUseCase = class(TInterfacedObject, IShowLoginViewUseCase)
  private
    FLoginViewFactoryFunc: TFunc<ILoginView>;
    FLogger: ILogger;
  public
    constructor Create(const Logger: ILogger; const LoginViewFactoryFunc: TFunc<ILoginView>);

    procedure Run;
  end;

implementation

{ TShowLoginViewUseCase }

constructor TShowLoginViewUseCase.Create(
  const Logger: ILogger;
  const LoginViewFactoryFunc: TFunc<ILoginView>);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FLoginViewFactoryFunc := Utilities.CheckNotNullAndSet<TFunc<ILoginView>>(LoginViewFactoryFunc, 'LoginViewFactoryFunc');
end;

procedure TShowLoginViewUseCase.Run;
var
  LoginView: ILoginView;
begin
  Logging.LogDuration(
    FLogger,
    ClassName,
    'Run',
    procedure
    begin
      LoginView := FLoginViewFactoryFunc();
      LoginView.Show;
    end);
end;

end.
