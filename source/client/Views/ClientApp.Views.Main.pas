unit ClientApp.Views.Main;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,

  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Controls.Presentation,
  FMX.DialogService,
  FMX.StdCtrls,
  FMX.Memo.Types,
  FMX.ScrollBox,
  FMX.Memo,

  Spring,

  Fido.Utilities,
  Fido.Api.Client.Exception,
  Fido.EventsDriven.Attributes,
  Fido.EventsDriven.Subscriber.Intf,

  Fido.Gui.Binding.Attributes,
  Fido.Gui.Types,
  Fido.Gui.Fmx.Binding,

  FidoApp.Messages,

  ClientApp.Messages,
  ClientApp.ViewModels.Main.Intf;

type
  TMainView = class(TForm, IInterface)
    MainToolbar: TToolBar;
    [MethodToActionBinding('PressLogButton', oeetAfter)]
    btnLog: TSpeedButton;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    [MethodToActionBinding('PressUsersButton', oeetAfter)]
    btnUsers: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FSubscriber: IEventsDrivenSubscriber;
    FViewModel: IMainViewModel;

    procedure SetSubscriber(const Subscriber: IEventsDrivenSubscriber);
    procedure SetViewModel(const ViewModel: IMainViewModel);

    procedure FormCloseQueryNo(Sender: TObject; var CanClose: Boolean);
    procedure FormCloseQueryYes(Sender: TObject; var CanClose: Boolean);
  public
    [TriggeredByEvent('MainViewModel', LOGGED_MESSAGE)]
    procedure OnLogStatusChanged(const Logged: Boolean);
    [TriggeredByEvent('MainViewModel', VIEW_BUSY_MESSAGE)]
    procedure OnBusyChange(const Busy: Boolean);

    property Subscriber: IEventsDrivenSubscriber write SetSubscriber;
    property ViewModel: IMainViewModel write SetViewModel;
  end;

implementation

{$R *.fmx}

{ TMainView }

procedure TMainView.FormCloseQueryYes(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
end;

procedure TMainView.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TMainView.FormCloseQueryNo(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := False;
end;

procedure TMainView.SetSubscriber(const Subscriber: IEventsDrivenSubscriber);
begin
  if Assigned(FSubscriber) then
    raise Exception.Create('Subscriber is already assigned');

  FSubscriber := Subscriber;
end;

procedure TMainView.OnBusyChange(const Busy: Boolean);
begin
  MainToolBar.Enabled := not Busy;

  case Busy of
    True: Self.OnCloseQuery := FormCloseQueryNo;
    False: Self.OnCloseQuery := FormCloseQueryYes;
  end;
end;

procedure TMainView.OnLogStatusChanged(const Logged: Boolean);
begin
  case Logged of
    True: btnLog.Text := 'Logout';
    False: btnLog.Text := 'Login';
  end;
end;

procedure TMainView.SetViewModel(const ViewModel: IMainViewModel);
begin
  if Assigned(FViewModel) then
    raise Exception.Create('ViewModel is already assigned');

  FViewModel := Utilities.CheckNotNullAndSet(ViewModel, 'ViewModel');

  Guibinding.Setup<IMainViewModel, TMainView>(FViewModel, Self);
  Guibinding.MethodsSetup<IMainViewModel, TMainView>(FViewModel, Self);

  FSubscriber.RegisterConsumer(Self);

  FViewModel.PressLogButton;
end;

end.
