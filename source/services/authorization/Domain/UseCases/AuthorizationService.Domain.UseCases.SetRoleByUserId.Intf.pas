unit AuthorizationService.Domain.UseCases.SetRoleByUserId.Intf;

interface

uses
  Fido.Exceptions,
  Fido.Functional,

  AuthorizationService.Domain.Entities.UserRole;

type
  ESetRoleByUserIdUseCase = class abstract (EFidoException);

  ESetRoleByUserIdUseCaseFailure = class(ESetRoleByUserIdUseCase);

  ISetRoleByUserIdUseCase = interface(IInvokable)
    ['{E1124A5D-4C03-431A-9EBB-E24B80E28DE1}']

    function Run(const UserRole: TUserRole): Context<Void>;
  end;

implementation

end.
