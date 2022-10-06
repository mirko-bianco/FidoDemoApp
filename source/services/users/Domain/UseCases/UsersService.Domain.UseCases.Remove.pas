unit UsersService.Domain.UseCases.Remove;

interface

uses
  System.SysUtils,
  Spring,

  Fido.Types,
  Fido.Exceptions,
  Fido.Functional,
  Fido.Functional.Tries,

  UsersService.Domain.UseCases.Remove.Intf,
  UsersService.Domain.Repositories.User.Intf;

type
  TRemoveUseCase = class(TInterfacedObject, IRemoveUseCase)
  private var
    FRepositoryFactory: TFunc<IUserRepository>;
    function DoRemoveUser(const Id: TGuid): Context<Void>;

  public
    constructor Create(const RepositoryFactory: TFunc<IUserRepository>);

    function Run(const Id: TGuid): Context<Void>;
  end;

implementation

{ TUsersUseCaseRemove }

constructor TRemoveUseCase.Create(
  const RepositoryFactory: TFunc<IUserRepository>);
begin
  inherited Create;

  Guard.CheckTrue(Assigned(RepositoryFactory), 'RepositoryFactory');

  FRepositoryFactory := RepositoryFactory;
end;

function TRemoveUseCase.DoRemoveUser(const Id: TGuid): Context<Void>;
begin
  Result := FRepositoryFactory().Remove(Id);
end;

function TRemoveUseCase.Run(const Id: TGuid): Context<Void>;
begin
  Result := &Try<TGuid>.
    New(Id).
    Map<Void>(DoRemoveUser).
    Match(ERemoveUseCaseFailure);
end;

end.
