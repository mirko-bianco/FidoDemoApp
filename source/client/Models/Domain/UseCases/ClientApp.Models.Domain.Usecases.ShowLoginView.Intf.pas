unit ClientApp.Models.Domain.Usecases.ShowLoginView.Intf;

interface

uses
  System.SysUtils,

  Fido.Types,
  Fido.DesignPatterns.Observer.Intf,

  ClientApp.Views.Login.Intf;

type
  IShowLoginViewUseCase = interface(IInvokable)
    ['{9CAC778D-A35C-4355-9598-EDC17493C01C}']

    procedure Run;
  end;

implementation

end.
