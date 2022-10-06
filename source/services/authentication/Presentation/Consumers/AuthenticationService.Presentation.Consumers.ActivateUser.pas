unit AuthenticationService.Presentation.Consumers.ActivateUser;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Logging.Utils,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Attributes,
  Fido.EventsDriven.Publisher.Intf,

  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf,
  AuthenticationService.Domain.Entities.UserStatus;

type
  TActivateUserConsumerController = class
  private
    FLogger: ILogger;
    FChangeActiveStatusUseCase: IChangeActiveStatusUsecase;
    FEventsPublisher: IEventsDrivenPublisher<string>;

    function DoChangeStatus(const UserStatus: Shared<TUserStatus>): Context<Void>;
    function OnException(const UserId: TGuid): OnFailureEvent<Void>;
  public
    constructor Create(const Logger: ILogger; const ChangeActiveStatusUseCase: IChangeActiveStatusUsecase; const EventsPublisher: IEventsDrivenPublisher<string>);

    [TriggeredByEvent('Users', 'UserAdded')]
    procedure Run(const UserId: TGuid);
  end;

implementation

{ TActivateUserConsumerController }

constructor TActivateUserConsumerController.Create(
  const Logger: ILogger;
  const ChangeActiveStatusUseCase: IChangeActiveStatusUsecase;
  const EventsPublisher: IEventsDrivenPublisher<string>);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FChangeActiveStatusUseCase := Utilities.CheckNotNullAndSet(ChangeActiveStatusUseCase, 'ChangeActiveStatusUseCase');
  FEventsPublisher := Utilities.CheckNotNullAndSet(EventsPublisher, 'EventsPublisher');
end;

function TActivateUserConsumerController.DoChangeStatus(const UserStatus: Shared<TUserStatus>): Context<Void>;
begin
  Result := FChangeActiveStatusUseCase.Run(UserStatus);
end;

function TActivateUserConsumerController.OnException(const UserId: TGuid): OnFailureEvent<Void>;
begin
  Result := function(const E: TObject): Void
    begin
      FEventsPublisher.Trigger('Authentication', 'UserActivationFailed', JSONMarshaller.From(UserId)).Value;
      FLogger.Error((E as Exception).Message, E as Exception);
    end;
end;

procedure TActivateUserConsumerController.Run(const UserId: TGuid);
begin
  Logging.LogDuration(
    FLogger,
    Self.ClassName,
    'Run',
    procedure
    begin
      &Try<Shared<TUserStatus>>.
        New(TUserStatus.Create(UserId, True)).
        Map<Void>(DoChangeStatus).
        Match(OnException(UserId)).Value;
    end);
end;

end.
