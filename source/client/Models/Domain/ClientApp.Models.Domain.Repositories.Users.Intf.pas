unit ClientApp.Models.Domain.Repositories.Users.Intf;

interface

uses
  FidoApp.Types,
  Fido.Functional;

type
  IUsersRepository = interface(IInvokable)
    ['{E5714E41-C0CB-4384-B5F0-3592B7F3FF0E}']

    function GetAll(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<IGetAllUsersV1Result>;
  end;

implementation

end.
