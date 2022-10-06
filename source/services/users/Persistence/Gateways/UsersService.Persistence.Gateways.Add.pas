unit UsersService.Persistence.Gateways.Add;

interface

uses

  Fido.Utilities,
  Fido.Functional,

  UsersService.Persistence.Db.Add.Intf,
  UsersService.Persistence.Gateways.Add.Intf;

type
  TInsertGateway = class(TInterfacedObject, IInsertGateway)
  private type
    TInsertUserParams = record
    private
      FId: string;
      FFirstName: string;
      FLastName: string;
    public
      constructor Create(const Id: string; const FirstName: string; const LastName: string);

      property Id: string read FId;
      property FirstName: string read FFirstName;
      property LastName: string read FLastName;
    end;
  private
    FCommand: IInsertUserCommand;
    function DoInsert(const Params: TInsertUserParams): Integer;

  public
    constructor Create(const Command: IInsertUserCommand);

    function Execute(const Id: string; const FirstName: string; const LastName: string): Context<Integer>;
  end;

implementation

{ TInsertGateway }

constructor TInsertGateway.Create(const Command: IInsertUserCommand);
begin
  inherited Create;

  FCommand := Utilities.CheckNotNullAndSet(Command, 'Command');
end;

function TInsertGateway.DoInsert(const Params: TInsertUserParams): Integer;
begin
  Result := FCommand.Execute(Params.Id, Params.FirstName, Params.LastName);
end;

function TInsertGateway.Execute(const Id: string; const FirstName: string; const LastName: string): Context<Integer>;
begin
  Result := Context<TInsertUserParams>.
    New(TInsertUserParams.Create(Id, FirstName, LastName)).
    Map<Integer>(DoInsert);
end;

{ TInsertGateway.TInsertUserParams }

constructor TInsertGateway.TInsertUserParams.Create(
  const Id: string;
  const FirstName: string;
  const LastName: string);
begin
  FId := Id;
  FFirstName := FirstName;
  FLastName := LastName;
end;

end.
