unit AuthenticationService.Persistence.Gateways.Login;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Collections,

  Fido.Exceptions,
  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,

  AuthenticationService.Domain.Entities.User,
  AuthenticationService.Persistence.Db.Login.Intf,
  AuthenticationService.Persistence.Gateways.Login.Intf;

type
  ELoginGateway = class(EFidoException);

  TLoginGateway = class(TInterfacedObject, ILoginGateway)
  private type
    TQueryUserParams = record
    private
        FUsername: string;
        FHashedPassword: string;
    public
      constructor Create(const Username: string; const HashedPassword: string);

      property Username: string read FUsername;
      property HashedPassword: string read FHashedPassword;
    end;
  private
    FQuery: IGetUserByUsernameAndHashedPasswordQuery;
    function DoQueryUser(const Params: TQueryUserParams): IReadonlyList<ILoginDbUserRecord>;
    function DoVerifyResult(const List: IReadOnlyList<ILoginDbUserRecord>): ILoginDbUserRecord;
    function DoGetId(const User: ILoginDbUserRecord): TGuid;
  public
    constructor Create(const Query: IGetUserByUsernameAndHashedPasswordQuery);

    function Get(const Username: string; const HashedPassword: string): Context<TGuid>;
  end;

implementation

{ TGetUserByUsernameAndHashedPasswordGateway }

constructor TLoginGateway.Create(const Query: IGetUserByUsernameAndHashedPasswordQuery);
begin
  inherited Create;

  FQuery := Utilities.CheckNotNullAndSet(Query, 'Query');
end;

function TLoginGateway.DoQueryUser(const Params: TQueryUserParams): IReadonlyList<ILoginDbUserRecord>;
begin
  Result := FQuery.Open(Params.Username, Params.HashedPassword);
end;

function TLoginGateway.DoVerifyResult(const List: IReadOnlyList<ILoginDbUserRecord>): ILoginDbUserRecord;
begin
  if List.Count <> 1 then
    raise ELoginGateway.CreateFmt('%d Users found.', [List.Count]);

  Result := List[0];
end;

function TLoginGateway.DoGetId(const User: ILoginDbUserRecord): TGuid;
begin
  Result := TGuid.Create(User.Id);
end;

function TLoginGateway.Get(const Username: string; const HashedPassword: string): Context<TGuid>;
begin
  Result := &Try<ILoginDbUserRecord>.
    New(Context<TQueryUserParams>.
      New(TQueryUserParams.Create(Username, HashedPassword)).
      Map<IReadonlyList<ILoginDbUserRecord>>(DoQueryUser).
      Map<ILoginDbUserRecord>(DoVerifyResult)).
    Map<TGuid>(DoGetId).
    Match(ELoginGateway, Format('User "%s" could not be found. %s', [Username, 'Error message: %s']));
end;

{ TLoginGateway.TQueryUserParams }

constructor TLoginGateway.TQueryUserParams.Create(
  const Username: string;
  const HashedPassword: string);
begin
  FUsername := Username;
  FHashedPassword := HashedPassword;
end;

end.
