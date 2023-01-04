program ClientApp;

{$STRONGLINKTYPES ON}

uses
  System.StartUpCopy,
  System.SysUtils,
  System.UITypes,
  System.IniFiles,
  FMX.Forms,
  FMX.Dialogs,
  Spring,
  Spring.Container,
  FidoApp.Utils,
  FidoApp.Domain.ClientTokensCache.Intf,
  ClientApp.Messages in 'ClientApp.Messages.pas',
  ClientApp.Types in 'ClientApp.Types.pas',
  ClientApp.DI in 'ClientApp.DI.pas',
  ClientApp.Views.Login.Intf in 'Views\ClientApp.Views.Login.Intf.pas',
  ClientApp.Views.Login in 'Views\ClientApp.Views.Login.pas' {LoginView},
  ClientApp.Views.Main in 'Views\ClientApp.Views.Main.pas' {MainView},
  ClientApp.ViewModels.Login.Intf in 'ViewModels\ClientApp.ViewModels.Login.Intf.pas',
  ClientApp.ViewModels.Login in 'ViewModels\ClientApp.ViewModels.Login.pas',
  ClientApp.ViewModels.Main.Intf in 'ViewModels\ClientApp.ViewModels.Main.Intf.pas',
  ClientApp.ViewModels.Main in 'ViewModels\ClientApp.ViewModels.Main.pas',
  ClientApp.Models.Domain.Repositories.Authentication.Intf in 'Models\Domain\ClientApp.Models.Domain.Repositories.Authentication.Intf.pas',
  ClientApp.Models.Domain.Entities.LoginUser in 'Models\Domain\Entities\ClientApp.Models.Domain.Entities.LoginUser.pas',
  ClientApp.Models.Domain.Entities.SignupUser in 'Models\Domain\Entities\ClientApp.Models.Domain.Entities.SignupUser.pas',
  ClientApp.Models.Domain.Usecases.Login.Intf in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.Login.Intf.pas',
  ClientApp.Models.Domain.Usecases.Login in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.Login.pas',
  ClientApp.Models.Domain.Usecases.ShowLoginView.Intf in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.ShowLoginView.Intf.pas',
  ClientApp.Models.Domain.Usecases.ShowLoginView in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.ShowLoginView.pas',
  ClientApp.Models.Domain.Usecases.Signup.Intf in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.Signup.Intf.pas',
  ClientApp.Models.Domain.UseCases.Signup in 'Models\Domain\UseCases\ClientApp.Models.Domain.UseCases.Signup.pas',
  ClientApp.Models.Persistence.Repositories.Authentication in 'Models\Persistence\Repositories\ClientApp.Models.Persistence.Repositories.Authentication.pas',
  ClientApp.Models.Persistence.Repositories.Users in 'Models\Persistence\Repositories\ClientApp.Models.Persistence.Repositories.Users.pas',
  ClientApp.Models.Domain.Repositories.Users.Intf in 'Models\Domain\ClientApp.Models.Domain.Repositories.Users.Intf.pas',
  ClientApp.Models.Domain.Usecases.GetAllUsers.Intf in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.GetAllUsers.Intf.pas',
  ClientApp.Models.Domain.Usecases.GetAllUsers in 'Models\Domain\UseCases\ClientApp.Models.Domain.Usecases.GetAllUsers.pas',
  ClientApp.ViewModels.Users.Intf in 'ViewModels\ClientApp.ViewModels.Users.Intf.pas',
  ClientApp.ViewModels.Users in 'ViewModels\ClientApp.ViewModels.Users.pas';

{$R *.res}

var
  Container: Shared<TContainer>;
  IniFile: Shared<TMemIniFile>;
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  Container := TContainer.Create;
  IniFile := TMemIniFile.Create(Utils.Files.GetIniFilename);

  Application.Initialize;
  ClientApp.DI.Register(Application, Container, IniFile);
  Container.Value.Resolve<TMainView>;

  Application.Run;
end.
