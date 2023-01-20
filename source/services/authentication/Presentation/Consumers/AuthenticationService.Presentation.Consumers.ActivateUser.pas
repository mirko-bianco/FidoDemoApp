unit AuthenticationService.Presentation.Consumers.ActivateUser;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Attributes,
  Fido.EventsDriven.Publisher.Intf,

  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf,
  AuthenticationService.Domain.Entities.UserStatus;

type
  TActivateUserConsumerController = class
  private
    FChangeActiveStatusUseCase: IChangeActiveStatusUsecase;
    FEventsPublisher: IEventsDrivenPublisher<string>;

    function DoChangeStatus(const UserStatus: TUserStatus): Context<Void>;
    function OnException(const UserId: TGuid): OnFailureEvent<Void>;
  public
    constructor Create(const ChangeActiveStatusUseCase: IChangeActiveStatusUsecase; const EventsPublisher: IEventsDrivenPublisher<string>);

    [TriggeredByEvent('Users', 'UserAdded')]
    procedure Run(const UserId: TGuid);
  end;

implementation

{ TActivateUserConsumerController }

constructor TActivateUserConsumerController.Create(
  const ChangeActiveStatusUseCase: IChangeActiveStatusUsecase;
  const EventsPublisher: IEventsDrivenPublisher<string>);
begin
  inherited Create;

  FChangeActiveStatusUseCase := Utilities.CheckNotNullAndSet(ChangeActiveStatusUseCase, 'ChangeActiveStatusUseCase');
  FEventsPublisher := Utilities.CheckNotNullAndSet(EventsPublisher, 'EventsPublisher');
end;

function TActivateUserConsumerController.DoChangeStatus(const UserStatus: TUserStatus): Context<Void>;
begin
  Result := FChangeActiveStatusUseCase.Run(UserStatus);
end;

function TActivateUserConsumerController.OnException(const UserId: TGuid): OnFailureEvent<Void>;
begin
  Result := function(const E: Exception): Nullable<Void>
    begin
      FEventsPublisher.Trigger('Authentication', 'UserActivationFailed', JSONMarshaller.From(UserId)).Value;
      raise AcquireExceptionObject;
    end;
end;

procedure TActivateUserConsumerController.Run(const UserId: TGuid);
begin
  &Try<TUserStatus>.
    New(TUserStatus.Create(UserId, True)).
    Map<Void>(DoChangeStatus).
    Match(OnException(UserId)).Value;
end;

end.
