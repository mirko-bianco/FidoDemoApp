unit UsersService.Presentation.Consumers.RemoveUser;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.EventsDriven.Attributes,
  Fido.Logging.Utils,

  UsersService.Domain.UseCases.Remove.Intf;

type
  TRemoveUserConsumerController = class
  private
    FLogger: ILogger;
    FRemoveUseCase: IRemoveUseCase;
    function DoRemoveUser(const USerId: TGuid): Context<Void>;
  public
    constructor Create(const Logger: ILogger; const RemoveUseCase: IRemoveUseCase);

    [TriggeredByEvent('Authentication', 'UserActivationFailed')]
    procedure Run(const UserId: TGuid);
  end;

implementation

{ TRemoveUserConsumerController }

constructor TRemoveUserConsumerController.Create(
  const Logger: ILogger;
  const RemoveUseCase: IRemoveUseCase);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FRemoveUseCase := Utilities.CheckNotNullAndSet(RemoveUseCase, 'RemoveUseCase');
end;

function TRemoveUserConsumerController.DoRemoveUser(const USerId: TGuid): Context<Void>;
begin
  Result := FRemoveUseCase.Run(UserId);
end;

procedure TRemoveUserConsumerController.Run(const UserId: TGuid);
begin
  Logging.LogDuration(
    FLogger,
    Self.ClassName,
    'Run',
    procedure
    begin
      &Try<TGuid>.
        New(UserId).
        Map<Void>(DoRemoveUser).
        Match(function(const E: TObject): Void
          begin
            FLogger.Error((E as Exception).Message, (E as Exception));
          end).Value;
    end);
end;

end.
