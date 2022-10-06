unit ClientApp.ViewModels.Users.Intf;

interface

uses
  System.Threading,

  Spring.Collections,

  Fido.DesignPatterns.Observable.Intf,
  Fido.Functional,

  FidoApp.Types,

  ClientApp.Types;

type
  IUsersViewModel = interface(IObservable)
    ['{66B6A288-8A1D-4936-AFD0-24842F478D40}']

    function Run: Context<Void>; overload;

    function PagesCount: Integer;
    function ChangePageNumber(const PageNumber: Integer): Context<Void>;
    function PageNumber: Integer;
    function CanPrior: Boolean;
    function Prior: Context<Void>;
    function CanNext: Boolean;
    function Next: Context<Void>;
    function OrderBy: TGetAllUsersOrderBy;
    function ChangeOrderBy(const OrderBy: TGetAllUsersOrderBy): Context<Void>;
    function Users: IReadonlyList<IUser>;

    procedure Close;

  end;

implementation

end.

