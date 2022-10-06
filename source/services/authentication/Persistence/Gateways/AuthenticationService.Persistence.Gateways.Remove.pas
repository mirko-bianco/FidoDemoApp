unit AuthenticationService.Persistence.Gateways.Remove;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  AuthenticationService.Persistence.Gateways.Remove.Intf,
  AuthenticationService.Persistence.Db.Remove.Intf;

type

  TRemoveGateway = class(TInterfacedObject, IRemoveGateway)
  private
    FCommand: IDeleteUserCommand;
    function DoRemoveUser(const Id: string): Integer;
  public
    constructor Create(const Command: IDeleteUserCommand);

    function Execute(const Id: string): Context<Integer>;
  end;

implementation

{ TRemoveGateway }

constructor TRemoveGateway.Create(const Command: IDeleteUserCommand);
begin
  inherited Create;

  FCommand := Utilities.CheckNotNullAndSet(Command, 'Command');
end;

function TRemoveGateway.DoRemoveUser(const Id: string): Integer;
begin
  Result := FCommand.Execute(Id);
end;

function TRemoveGateway.Execute(const Id: string): Context<Integer>;
begin
  Result := Context<string>.
    New(Id).
    Map<Integer>(DoRemoveUser);
end;

end.
