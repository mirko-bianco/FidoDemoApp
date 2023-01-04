unit AuthenticationService.Persistence.Repositories.User;

interface

uses
  System.SysUtils,

  Spring,
  Spring.Collections,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,
  Fido.Functional.Retries,
  Fido.DesignPatterns.Retries,

  AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf,
  AuthenticationService.Persistence.Gateways.Login.Intf,
  AuthenticationService.Persistence.Gateways.Remove.Intf,
  AuthenticationService.Persistence.Gateways.Signup.Intf,
  AuthenticationService.Domain.Entities.UserStatus,
  AuthenticationService.Domain.Entities.User,
  AuthenticationService.Domain.Repositories.User.Intf;

type
  TUserRepository = class(TInterfacedObject, IUserRepository)
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
  private var
    FChangeActiveStatusGateway: IChangeActiveStatusGateway;
    FLoginGateway: ILoginGateway;
    FRemoveGateway: IRemoveGateway;
    FSignupGateway: ISignupGateway;

    procedure AffectedRowsMustBe1(const AffectedRows: Integer);
    function DoRemove(const Id: string): Context<Integer>;
    function DoValidateLoginResult(const Id: TGuid): Context<Integer>.FunctorFunc<Void>;
    function DoSignup(const Params: TSignupParams): Context<Integer>;
    function DoValidateSignupResult(const User: TUser): Context<Integer>.FunctorFunc<Void>;
    function DoChangeState(const Data: TChangeActiveStatusGatewayCallData): Context<Integer>;
  public
    constructor Create(
      const ChangeActiveStatusGateway: IChangeActiveStatusGateway;
      const LoginGateway: ILoginGateway;
      const RemoveGateway: IRemoveGateway;
      const SignupGateway: ISignupGateway);

    function UpdateActiveByUserId(const UserStatus: TUserStatus): Context<Void>;
    function Login(const User: TUser): Context<TGuid>;
    function Remove(const Id: TGuid): Context<Void>;
    function Store(const Id: TGuid; const User: TUser): Context<Void>;
  end;

implementation

{ TChangeActiveStatusRepository }

constructor TUserRepository.Create(
  const ChangeActiveStatusGateway: IChangeActiveStatusGateway;
  const LoginGateway: ILoginGateway;
  const RemoveGateway: IRemoveGateway;
  const SignupGateway: ISignupGateway);
begin
  inherited Create;

  FChangeActiveStatusGateway := Utilities.CheckNotNullAndSet(ChangeActiveStatusGateway, 'ChangeActiveStatusGateway');
  FLoginGateway := Utilities.CheckNotNullAndSet(LoginGateway, 'LoginGateway');
  FRemoveGateway := Utilities.CheckNotNullAndSet(RemoveGateway, 'RemoveGateway');
  FSignupGateway := Utilities.CheckNotNullAndSet(SignupGateway, 'SignupGateway');
end;

function TUserRepository.Login(const User: TUser): Context<TGuid>;
begin
  Result := FLoginGateway.Get(User.Username, User.HashedPassword);
end;

function TUserRepository.DoRemove(const Id: string): Context<Integer>;
begin
  Result := FRemoveGateway.Execute(Id);
end;

function TUserRepository.DoValidateLoginResult(const Id: TGuid): Context<Integer>.FunctorFunc<Void>;
begin
  result := Void.MapProc<Integer>(procedure(const AffectedRecords: Integer)
    begin
      if AffectedRecords = 0 then
        raise EUserRepository.CreateFmt('User "%s" could not be removed.', [Id.ToString]);
    end);
end;

function TUserRepository.Remove(const Id: TGuid): Context<Void>;
begin
  Result := &Try<string>.
    New(Id.ToString).
    Map<Integer>(DoRemove).
    Match(EUserRepository, Format('User "%s" could not be removed. %s', [Id.ToString, 'Error message: %s'])).
    Map<Void>(DoValidateLoginResult(Id));
end;

function TUserRepository.DoSignup(const Params: TSignupParams): Context<Integer>;
begin
  Result := FSignupGateway.Execute(Params.Id, Params.Username, Params.HashedPassword);
end;

function TUserRepository.DoValidateSignupResult(const User: TUser): Context<Integer>.FunctorFunc<Void>;
begin
  Result := Void.MapProc<Integer>(procedure(const AffectedRecords: Integer)
    begin
      if AffectedRecords = 0 then
        raise EUserRepository.CreateFmt('User "%s" could not be stored.', [User.Username]);
    end);
end;

function TUserRepository.Store(const Id: TGuid; const User: TUser): Context<Void>;
begin
  Result := &Try<TSignupParams>.
    New(TSignupParams.Create(Id.ToString, User.Username, User.HashedPassword)).
      Map<Integer>(DoSignup).
      Match(EUserRepository, Format('User "%s" could not be stored. %s', [User.Username, 'Error message: %s'])).
    Map<Void>(DoValidateSignupResult(User));
end;

procedure TUserRepository.AffectedRowsMustBe1(const AffectedRows: Integer);
begin
  if AffectedRows <> 1 then
    raise EUserRepository.CreateFmt('%d Users found.', [AffectedRows]);
end;

function TUserRepository.DoChangeState(const Data: TChangeActiveStatusGatewayCallData): Context<Integer>;
begin
  Result := FChangeActiveStatusGateway.Execute(Data);
end;

function TUserRepository.UpdateActiveByUserId(const UserStatus: TUserStatus): Context<Void>;
begin
  Result := TryOut<Integer>.
    New(
      Retry<TChangeActiveStatusGatewayCallData>.
        New(TChangeActiveStatusGatewayCallData.Create(UserStatus.Id, UserStatus.Active)).
        Map<Integer>(DoChangeState, Retries.GetRetriesOnExceptionFunc())).
    Match(EUserRepository, Format('User "%s" could not be updated. Error message: %%s', [UserStatus.Id.ToString])).
    Map<Void>(Void.MapProc<Integer>(AffectedRowsMustBe1));
end;

{ TUserRepository.TSignupParams }

constructor TUserRepository.TSignupParams.Create(
  const Id: string;
  const Username: string;
  const HashedPassword: string);
begin
  FId := Id;
  FUsername := Username;
  FHashedPassword := HashedPassword;
end;

end.

