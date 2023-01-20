unit UsersService.Presentation.Consumers.RemoveUser;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.EventsDriven.Attributes,

  UsersService.Domain.UseCases.Remove.Intf;

type
  TRemoveUserConsumerController = class
  private
    FRemoveUseCase: IRemoveUseCase;
    function DoRemoveUser(const USerId: TGuid): Context<Void>;
  public
    constructor Create(const RemoveUseCase: IRemoveUseCase);

    [TriggeredByEvent('Authentication', 'UserActivationFailed')]
    procedure Run(const UserId: TGuid);
  end;

implementation

{ TRemoveUserConsumerController }

constructor TRemoveUserConsumerController.Create(const RemoveUseCase: IRemoveUseCase);
begin
  inherited Create;

  FRemoveUseCase := Utilities.CheckNotNullAndSet(RemoveUseCase, 'RemoveUseCase');
end;

function TRemoveUserConsumerController.DoRemoveUser(const USerId: TGuid): Context<Void>;
begin
  Result := FRemoveUseCase.Run(UserId);
end;

procedure TRemoveUserConsumerController.Run(const UserId: TGuid);
begin
  &Try<TGuid>.
    New(UserId).
    Map<Void>(DoRemoveUser).
    Match(procedure
      begin
      end).Value;
end;

end.
