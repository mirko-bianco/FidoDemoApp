unit UsersService.Persistence.Gateways.Remove;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  UsersService.Persistence.Gateways.Remove.Intf,
  UsersService.Persistence.Db.Remove.Intf;

type
  TDeleteUserGateway = class(TInterfacedObject, IDeleteUserGateway)
  private
    FCommand: IDeleteUserCommand;
    function DoDelete(const Id: string): Integer;

  public
    constructor Create(const Command: IDeleteUserCommand);

    function Execute(const Id: string): Context<Integer>;
  end;

implementation

{ TDeleteUserGateway }

constructor TDeleteUserGateway.Create(const Command: IDeleteUserCommand);
begin
  inherited Create;

  FCommand := Utilities.CheckNotNullAndSet(Command, 'Command');
end;

function TDeleteUserGateway.DoDelete(const Id: string): Integer;
begin
  Result := FCommand.Execute(Id);
end;

function TDeleteUserGateway.Execute(const Id: string): Context<Integer>;
begin
  Result := Context<string>.
    New(Id).
    Map<Integer>(DoDelete);
end;

end.
