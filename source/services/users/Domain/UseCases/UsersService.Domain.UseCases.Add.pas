unit UsersService.Domain.UseCases.Add;

interface

uses
  System.SysUtils,
  System.Hash,
  System.RegularExpressions,

  Spring,

  Fido.Types,
  Fido.Exceptions,
  Fido.Functional,
  Fido.Functional.Tries,

  UsersService.Domain.UseCases.Add.Intf,
  UsersService.Domain.Repositories.User.Intf,
  UsersService.Domain.Entities.User;

type
  TAddUseCase = class(TInterfacedObject, IAddUseCase)
  private var
    FRepositoryFactory: TFunc<IUserRepository>;

    function Validate(const User: TUser): TUser;
    function DoAddUser(const User: TUser): Context<Void>;
  public
    constructor Create(const RepositoryFactory: TFunc<IUserRepository>);

    function Run(const User: TUser): Context<Void>;
  end;

implementation

{ TUsersUseCaseAdd }

constructor TAddUseCase.Create(
  const RepositoryFactory: TFunc<IUserRepository>);
begin
  inherited Create;

  Guard.CheckTrue(Assigned(RepositoryFactory), 'RepositoryFactory');

  FRepositoryFactory := RepositoryFactory;
end;

function TAddUseCase.Validate(const User: TUser): TUser;
begin
  Result := User;
  Result.Validate;
end;

function TAddUseCase.DoAddUser(const User: TUser): Context<Void>;
begin
  Result := FRepositoryFactory().Store(User);
end;

function TAddUseCase.Run(const User: TUser): Context<Void>;
begin
  Result := &Try<TUser>.
    New(&Try<TUser>.
      New(User).
      Map<TUser>(Validate).
      Match(function(const E: TObject): TUser
        begin
          raise EAddUseCaseValidation.Create((E as Exception).Message);
        end)).
    Map<Void>(DoAddUser).
    Match(EAddUseCaseFailure);
end;

end.
