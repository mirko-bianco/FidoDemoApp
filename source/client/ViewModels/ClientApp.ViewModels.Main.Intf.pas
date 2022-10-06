unit ClientApp.ViewModels.Main.Intf;

interface

uses
  Fido.DesignPatterns.Observable.Intf;

type
  IMainViewModel = interface(IObservable)
    ['{A241E761-9AED-4CA1-B137-576A704F830E}']

    procedure PressLogButton;
    procedure PressUsersButton;

    procedure OnCloseLoginView;
  end;

implementation

end.

