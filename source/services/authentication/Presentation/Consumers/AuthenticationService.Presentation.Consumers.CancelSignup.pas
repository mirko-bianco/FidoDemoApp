unit AuthenticationService.Presentation.Consumers.CancelSignup;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.EventsDriven.Attributes,

  AuthenticationService.Domain.UseCases.Remove.Intf;

type
  TCancelSignupConsumerController = class
  private
    FRemoveUseCase: IRemoveUseCase;
    function DoRemove(const UserId: TGuid): Context<Void>;
  public
    constructor Create(const RemoveUseCase: IRemoveUseCase);

    [TriggeredByEvent('Users', 'UserAddFailed')]
    procedure Run(const UserId: TGuid);
  end;

implementation

{ TCancelSignupConsumerController }

constructor TCancelSignupConsumerController.Create(const RemoveUseCase: IRemoveUseCase);
begin
  inherited Create;

  FRemoveUseCase := Utilities.CheckNotNullAndSet(RemoveUseCase, 'RemoveUseCase');
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
    Match(procedure
      begin
      end).Value;
end;

end.
