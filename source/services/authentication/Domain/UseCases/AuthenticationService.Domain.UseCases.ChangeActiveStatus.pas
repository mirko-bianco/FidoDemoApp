unit AuthenticationService.Domain.UseCases.ChangeActiveStatus;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Tries,

  AuthenticationService.Domain.UseCases.ChangeActiveStatus.Intf,
  AuthenticationService.Domain.Repositories.User.Intf,
  AuthenticationService.Domain.Entities.UserStatus;

type
  TChangeActiveStatusUseCase = class(TInterfacedObject, IChangeActiveStatusUseCase)
  private var
    FRepositoryFactory: TFunc<IUserRepository>;
    function DoUpdateActiveByUserId(const UserStatus: TUserStatus): Context<Void>;

  public
    constructor Create(const RepositoryFactory: TFunc<IUserRepository>);

    function Run(const UserStatus: TUserStatus): Context<Void>;
  end;

implementation

{ TAuthenticationUseCaseChangeActiveStatus }

constructor TChangeActiveStatusUseCase.Create(
  const RepositoryFactory: TFunc<IUserRepository>);
begin
  inherited Create;

  FRepositoryFactory := Utilities.CheckNotNullAndSet<TFunc<IUserRepository>>(RepositoryFactory, 'RepositoryFactory');
end;

function TChangeActiveStatusUseCase.DoUpdateActiveByUserId(const UserStatus: TUserStatus): Context<Void>;
begin
  Result := FRepositoryFactory().UpdateActiveByUserId(UserStatus);
end;

function TChangeActiveStatusUseCase.Run(const UserStatus: TUserStatus): Context<Void>;
begin
  Result := &Try<TUserStatus>.
    New(UserStatus).
    Map<Void>(DoUpdateActiveByUserId).
    Match(EChangeActiveStatusUseCaseFailure, 'Could not change the state.');
end;

end.
