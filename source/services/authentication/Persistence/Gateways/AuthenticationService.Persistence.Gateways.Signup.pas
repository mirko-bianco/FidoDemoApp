unit AuthenticationService.Persistence.Gateways.Signup;

interface

uses
  Fido.Utilities,
  Fido.Functional,

  AuthenticationService.Persistence.Gateways.Signup.Intf,
  AuthenticationService.Persistence.Db.Signup.Intf;

type
  TSignupGateway = class(TInterfacedObject, ISignupGateway)
  private type
    TSignupParams = record
    private
      FId: string;
      FUsername: string;
      FHashedPassword: string;
    public
      constructor Create(const Id: string; const Username: string; const HashedPassword: string);

      property Id: string read FId;
      property Username: string read FUsername;
      property HashedPassword: string read FHashedPassword;
    end;
  private
    FCommand: IInsertUserCommand;
    function DoSignup(const Params: TSignupParams): Integer;

  public
    constructor Create(const Command: IInsertUserCommand);

    function Execute(const Id: string; const Username: string; const HashedPassword: string): Context<Integer>;
  end;

implementation

{ TSignupGateway }

constructor TSignupGateway.Create(const Command: IInsertUserCommand);
begin
  inherited Create;

  FCommand := Utilities.CheckNotNullAndSet(Command, 'Command');
end;

function TSignupGateway.DoSignup(const Params: TSignupParams): Integer;
begin
  Result := FCommand.Execute(Params.Id, Params.Username, Params.HashedPassword);
end;

function TSignupGateway.Execute(
  const Id: string;
  const Username: string;
  const HashedPassword: string): Context<Integer>;
begin
  Result := Context<TSignupParams>.
    New(TSignupParams.Create(Id, Username, HashedPassword)).
    Map<Integer>(DoSignup);
end;

{ TSignupGateway.TSignupParams }

constructor TSignupGateway.TSignupParams.Create(
  const Id: string;
  const Username: string;
  const HashedPassword: string);
begin
  FId := Id;
  FUsername := Username;
  FHashedPassword := HashedPassword;
end;

end.
