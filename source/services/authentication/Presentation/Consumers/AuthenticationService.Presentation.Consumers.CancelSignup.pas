unit AuthenticationService.Presentation.Consumers.CancelSignup;

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

  AuthenticationService.Domain.UseCases.Remove.Intf;

type
  TCancelSignupConsumerController = class
  private
    FLogger: ILogger;
    FRemoveUseCase: IRemoveUseCase;
    function DoRemove(const UserId: TGuid): Context<Void>;
  public
    constructor Create(const Logger: ILogger; const RemoveUseCase: IRemoveUseCase);

    [TriggeredByEvent('Users', 'UserAddFailed')]
    procedure Run(const UserId: TGuid);
  end;

implementation

{ TCancelSignupConsumerController }

constructor TCancelSignupConsumerController.Create(
  const Logger: ILogger;
  const RemoveUseCase: IRemoveUseCase);
begin
  inherited Create;

  FRemoveUseCase := Utilities.CheckNotNullAndSet(RemoveUseCase, 'RemoveUseCase');
  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
end;

function TCancelSignupConsumerController.DoRemove(const UserId: TGuid): Context<Void>;
begin
  Result := FRemoveUseCase.Run(UserID);
end;

procedure TCancelSignupConsumerController.Run(const UserId: TGuid);
begin
  &Try<TGuid>.
    New(UserId).
    Map<Void>(DoRemove).
    Match(function(const E: Exception): Nullable<Void>
      begin
        FLogger.Error(E.Message, E);
        Result := Nullable<Void>.Create(Void.Get);
      end).Value;
end;

end.
