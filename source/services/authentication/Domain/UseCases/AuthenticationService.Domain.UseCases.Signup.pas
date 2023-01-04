unit AuthenticationService.Domain.UseCases.Signup;

interface

uses
  System.SysUtils,
  System.Hash,
  System.RegularExpressions,
  Generics.Collections,

  Spring,

  Fido.Types,
  Fido.Utilities,
  Fido.Exceptions,
  Fido.Functional,
  Fido.Functional.Tries,

  AuthenticationService.Domain.UseCases.Signup.Intf,
  AuthenticationService.Domain.Repositories.User.Intf,
  AuthenticationService.Domain.Entities.User;

type
  TSignupUseCase = class(TInterfacedObject, ISignupUseCase)
  private type
    TSignupData = record
    private
      FId: TGuid;
      FUser: TUser;
    public
      constructor Create(const Id: TGuid; const User: TUser);

      property Id: TGuid read FId;
      property User: TUser read FUser;
    end;
  private var
    FRepositoryFactory: TFunc<IUserRepository>;

    function Validate(const Params: TSignupData): TSignupData;
    function DoStoreUser(const Params: TSignupData): TGuid;
  public
    constructor Create(const RepositoryFactory: TFunc<IUserRepository>);

    function Run(const User: TUser): Context<TGuid>;
  end;

implementation

{ TAuthenticationUseCaseSignup }

constructor TSignupUseCase.Create(
  const RepositoryFactory: TFunc<IUserRepository>);
begin
  inherited Create;

  FRepositoryFactory := Utilities.CheckNotNullAndSet<TFunc<IUserRepository>>(RepositoryFactory, 'RepositoryFactory');
end;

function TSignupUseCase.Validate(const Params: TSignupData): TSignupData;
begin
  Result := Params;
  Result.User.Validate;
end;

function TSignupUseCase.DoStoreUser(const Params: TSignupData): TGuid;
begin
  FRepositoryFactory().Store(Params.Id, Params.User).Value;
  Result := Params.Id;
end;

function TSignupUseCase.Run(const User: TUser): Context<TGuid>;
var
  SignupData: TSignupData;
begin
  SignupData := TSignupData.Create(TGuid.NewGuid, User);

  Result := &Try<TSignupData>.
    New(&Try<TSignupData>.
      New(SignupData).
      Map<TSignupData>(Validate).
      Match(ESignupUseCaseValidation)).
    Map<TGuid>(DoStoreUser).
    Match(ESignupUseCaseFailure);
end;

{ TSignupUseCase.TSignupData }

constructor TSignupUseCase.TSignupData.Create(
  const Id: TGuid;
  const User: TUser);
begin
  FId := Id;
  FUser := User;
end;

end.
