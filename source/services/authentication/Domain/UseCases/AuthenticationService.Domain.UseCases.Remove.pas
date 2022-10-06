unit AuthenticationService.Domain.UseCases.Remove;

interface

uses
  System.SysUtils,
  Spring,

  Fido.Types,
  Fido.Utilities,
  Fido.Exceptions,
  Fido.Functional,

  AuthenticationService.Domain.UseCases.Remove.Intf,
  AuthenticationService.Domain.Repositories.User.Intf;

type
  TRemoveUseCase = class(TInterfacedObject, IRemoveUseCase)
  private var
    FRepositoryFactory: TFunc<IUserRepository>;
  public
    constructor Create(const RepositoryFactory: TFunc<IUserRepository>);

    function Run(const Id: TGuid): Context<Void>;
  end;

implementation

{ TAuthenticationUseCaseRemove }

constructor TRemoveUseCase.Create(
  const RepositoryFactory: TFunc<IUserRepository>);
begin
  inherited Create;

  FRepositoryFactory := Utilities.CheckNotNullAndSet<TFunc<IUserRepository>>(RepositoryFactory, 'RepositoryFactory');
end;

function TRemoveUseCase.Run(const Id: TGuid): Context<Void>;
begin
  Result := FRepositoryFactory().Remove(Id);
end;

end.
