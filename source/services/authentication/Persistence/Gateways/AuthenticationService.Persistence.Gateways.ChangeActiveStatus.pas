unit AuthenticationService.Persistence.Gateways.ChangeActiveStatus;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  AuthenticationService.Persistence.Db.ChangeActiveStatus.Intf,
  AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf;

type
  TChangeActiveStatusGateway = class(TInterfacedObject, IChangeActiveStatusGateway)
  private
    FCommand: IUpdateActiveStatusCommand;
    function DoChangeStatus(const CallData: TChangeActiveStatusGatewayCallData): Integer;
  public
    constructor Create(Command: IUpdateActiveStatusCommand);

    function Execute(const CallData: TChangeActiveStatusGatewayCallData): Context<Integer>;
  end;

implementation

{ TChangeActiveStatusGateway }

constructor TChangeActiveStatusGateway.Create(Command: IUpdateActiveStatusCommand);
begin
  inherited Create;

  FCommand := Utilities.CheckNotNullAndSet(Command, 'Command');
end;

function TChangeActiveStatusGateway.DoChangeStatus(const CallData: TChangeActiveStatusGatewayCallData): Integer;
begin
  Result := FCommand.Execute(CallData.Id, CallData.Status);
end;

function TChangeActiveStatusGateway.Execute(const CallData: TChangeActiveStatusGatewayCallData): Context<Integer>;
begin
  Result := Context<TChangeActiveStatusGatewayCallData>.
    New(CallData).
    Map<Integer>(DoChangeStatus);
end;

end.
