unit UsersService.Domain.UseCases.GetAll.Intf;

interface

uses
  System.SysUtils,

  Spring.Collections,

  Fido.Exceptions,
  Fido.Functional,

  FidoApp.Types,

  UsersService.Domain.Entities.User;

type
  EGetAllUseCase = class abstract (EFidoException);

  EGetAllUseCaseValidation = class(EGetAllUseCase);

  EGetAllUseCaseFailure = class(EGetAllUseCase);

  TGetAllV1Result = record
  private
    FCount: Integer;
    FUsers: IReadonlyList<TUser>;
  public
    constructor Create(const Count: Integer; const Users: IReadonlyList<TUser>);

    function Count: Integer;
    function Users: IReadonlyList<TUser>;
  end;

  IGetAllUseCase = interface(IInvokable)
    ['{9A11E98C-EF87-4C1E-A43B-34FB7634B317}']

    function Run(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<TGetAllV1Result>;
  end;

implementation

{ TGetAllV1Result }

function TGetAllV1Result.Count: Integer;
begin
  Result := FCount;
end;

constructor TGetAllV1Result.Create(const Count: Integer; const Users: IReadonlyList<TUser>);
begin
  FCount := Count;
  FUsers := Users;
end;

function TGetAllV1Result.Users: IReadonlyList<TUser>;
begin
  Result := FUsers;
end;

end.

