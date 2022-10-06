unit ClientApp.ViewModels.Login.Intf;

interface

uses
  System.Threading,

  Fido.Functional,
  Fido.DesignPatterns.Observable.Intf;

type
  ILoginViewModel = interface(IObservable)
    ['{002AB6A4-983E-4676-B20A-EC39CA075FE4}']

    procedure SwitchAction;
    function Username: string;
    procedure SetUsername(const Value: string);
    function Password: string;
    procedure SetPassword(const Value: string);
    function RepeatedPassword: string;
    procedure SetRepeatedPassword(const Value: string);
    function FirstName: string;
    procedure SetFirstName(const Value: string);
    function LastName: string;
    procedure SetLastName(const Value: string);

    function RunTask: Context<Void>;

    procedure Run;
    procedure Close;

  end;

implementation

end.

