unit ClientApp.ViewModels.Main;

interface

uses
  System.SysUtils,

  Spring,

  Fido.Utilities,
  Fido.DesignPatterns.Observable.Delegated,
  Fido.DesignPatterns.Observer.Intf,
  Fido.DesignPatterns.Observer.Notification.Intf,
  Fido.JSON.Marshalling,
  Fido.EventsDriven.Attributes,
  Fido.EventsDriven.Subscriber.Intf,

  FidoApp.Messages,
  FidoApp.Domain.ClientTokensCache.Intf,

  ClientApp.Types,
  ClientApp.Messages,
  ClientApp.ViewModels.Main.Intf,
  ClientApp.Models.Domain.UseCases.ShowLoginView.Intf;

type
  TMainViewModel = class(TDelegatedObservable, IMainViewModel, IObserver)
  private
    FSubscriber: IEventsDrivenSubscriber;
    FPublisher: IEventsDrivenPublisher;
    FShowLoginViewUseCase: IShowLoginViewUseCase;
    FTokensCache: IClientTokensCache;

    procedure ChangeBusyStatus(const Value: Boolean);
  public
    constructor Create(const Subscriber: IEventsDrivenSubscriber; const Publisher: IEventsDrivenPublisher; const TokensCache: IClientTokensCache; const ShowLoginViewUseCase: IShowLoginViewUseCase);
    destructor Destroy; override;

    procedure PressLogButton;
    procedure PressUsersButton;

    [TriggeredByEvent('LoginViewModel', VIEW_CLOSED_MESSAGE)]
    procedure OnCloseLoginView;

    procedure Notify(const Sender: IInterface; const Notification: INotification);
  end;

implementation

{ TMainViewModel }

procedure TMainViewModel.ChangeBusyStatus(const Value: Boolean);
begin
  FPublisher.Trigger('MainViewModel', VIEW_BUSY_MESSAGE, [Value]).Value;
end;

constructor TMainViewModel.Create(
  const Subscriber: IEventsDrivenSubscriber;
  const Publisher: IEventsDrivenPublisher;
  const TokensCache: IClientTokensCache;
  const ShowLoginViewUseCase: IShowLoginViewUseCase);
begin
  inherited Create(nil);
  FSubscriber := Utilities.CheckNotNullAndSet(Subscriber, 'Subscriber');
  FPublisher := Utilities.CheckNotNullAndSet(Publisher, 'Publisher');
  FShowLoginViewUseCase := Utilities.CheckNotNullAndSet(ShowLoginViewUseCase, 'ShowLoginViewUseCase');
  FTokensCache := Utilities.CheckNotNullAndSet(TokensCache, 'TokensCache');
  Subscriber.RegisterConsumer(Self);
  FTokensCache.RegisterObserver(Self);
end;

destructor TMainViewModel.Destroy;
begin
  FTokensCache.UnregisterObserver(Self);
  inherited;
end;

procedure TMainViewModel.Notify(const Sender: IInterface; const Notification: INotification);
begin
  if Notification.GetDescription.Equals(LOGGED_MESSAGE) then
    FPublisher.Trigger('MainViewModel', LOGGED_MESSAGE, Notification.GetData.AsType<TArray<TValue>>).Value
  else if Notification.GetDescription.Equals(TOKEN_CHANGED_MESSAGE) then
    FPublisher.Trigger('MainViewModel', TOKEN_CHANGED_MESSAGE, []).Value;
end;

procedure TMainViewModel.OnCloseLoginView;
begin
  ChangeBusyStatus(False);
end;

procedure TMainViewModel.PressLogButton;
begin
  if not Assigned(FTokensCache.Tokens) then
  begin
    ChangeBusyStatus(True);
    FShowLoginViewUseCase.Run;
  end
  else
    FTokensCache.SetTokens(nil);
end;

procedure TMainViewModel.PressUsersButton;
begin
end;

end.

