unit ClientApp.Models.Domain.Usecases.GetAllUsers.Intf;

interface

uses
  FidoApp.Types,
  Fido.Functional;

type
  IGetAllUsersUseCase = interface(IInvokable)
    ['{91BF41D1-B4A6-4FAF-86FA-32FC3B8E8C83}']

    function Run(const OrderBy: TGetAllUsersOrderBy; const Page: Integer; const Limit: Integer): Context<IGetAllUsersV1Result>;
  end;

implementation

end.
