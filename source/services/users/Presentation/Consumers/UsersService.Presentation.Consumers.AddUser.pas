unit UsersService.Presentation.Consumers.AddUser;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Logging,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Mappers,
  Fido.Logging.Utils,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Attributes,
  Fido.EventsDriven.Publisher.Intf,

  UsersService.Domain.UseCases.Add.Intf,
  UsersService.Domain.Entities.User;

type
  IUserCreatedDto = interface(IInvokable)
    function UserId: TGuid;
    function FirstName: string;
    function LastName: string;
  end;

  TAddUserConsumerController = class
  private
    FLogger: ILogger;
    FAddUseCase: IAddUseCase;
    FEventsPublisher: IEventsDrivenPublisher<string>;

    function MapDto(const UserCreatedDto: IUserCreatedDto): TUser;
    function Add(const User: TUser): Context<Void>;
    function DoNotifyUserAdded(const User: Tuser): Context<Void>.MonadFunc<Void>;
    function DoAdd(const User: TUser): Context<Void>;
    function OnException(const User: TUser): OnFailureEvent<Void>;
  public
    constructor Create(const Logger: ILogger; const AddUseCase: IAddUseCase; const EventsPublisher: IEventsDrivenPublisher<string>);

    [TriggeredByEvent('Authentication', 'UserAdded')]
    procedure Run(const UserCreatedDto: IUserCreatedDto);
  end;

implementation

{ TAddUserConsumerController }

constructor TAddUserConsumerController.Create(
  const Logger: ILogger;
  const AddUseCase: IAddUseCase;
  const EventsPublisher: IEventsDrivenPublisher<string>);
begin
  inherited Create;

  FLogger := Utilities.CheckNotNullAndSet(Logger, 'Logger');
  FAddUseCase := Utilities.CheckNotNullAndSet(AddUseCase, 'AddUseCase');
  FEventsPublisher := Utilities.CheckNotNullAndSet(EventsPublisher, 'DistribuitedEventPublisher');
end;

function TAddUserConsumerController.MapDto(const UserCreatedDto: IUserCreatedDto): TUser;
begin
  Mappers.Map<IUserCreatedDto, TUser>(UserCreatedDto, Result);
end;

function TAddUserConsumerController.DoNotifyUserAdded(const User: Tuser): Context<Void>.MonadFunc<Void>;
begin
  Result := function(const Value: Void): Context<Void>
    begin
      Result := Void.Map<Boolean>(FEventsPublisher.Trigger('Users', 'UserAdded', JSONMarshaller.From(User.Id).DeQuotedString('"')));
    end;
end;

function TAddUserConsumerController.DoAdd(const User: TUser): Context<Void>;
begin
  Result := FAddUseCase.Run(User);
end;

function TAddUserConsumerController.OnException(const User: TUser): OnFailureEvent<Void>;
begin
  Result := function(const E: Exception): Nullable<Void>
    begin
      FEventsPublisher.Trigger('Users', 'UserAddFailed', JSONMarshaller.From(User.Id).DeQuotedString('"')).Value;
      FLogger.Error(E.Message, E);
      Result := Nullable<Void>.Create(Void.Get);
    end;
end;

function TAddUserConsumerController.Add(const User: TUser): Context<Void>;
begin
  Result := &Try<TUser>.
    New(User).
    Map<Void>(DoAdd).
    Match(OnException(User)).
    Map<Void>(DoNotifyUserAdded(User));
end;

procedure TAddUserConsumerController.Run(const UserCreatedDto: IUserCreatedDto);
begin
  Context<IUserCreatedDto>(UserCreatedDto).
    Map<TUser>(MapDto).
    Map<Void>(Add).Value;
end;

initialization

  Mappers.RegisterMapper<IUserCreatedDto, TUser>(procedure(const Source: IUserCreatedDto; var Destination: TUser)
    begin
      Destination.SetId(Source.UserId);
      Destination.SetFirstName(Source.FirstName);
      Destination.SetLastName(Source.LastName);
    end);

end.
