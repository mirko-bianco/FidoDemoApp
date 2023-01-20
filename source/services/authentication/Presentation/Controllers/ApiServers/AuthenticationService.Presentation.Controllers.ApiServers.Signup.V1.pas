unit AuthenticationService.Presentation.Controllers.ApiServers.Signup.V1;

interface

uses
  System.SysUtils,
  Generics.Collections,

  Spring,

  Fido.Utilities,
  Fido.Functional,
  Fido.Functional.Ifs,
  Fido.Functional.Tries,
  Fido.Types,
  Fido.Http.Types,
  Fido.Api.Server.Exceptions,
  Fido.Api.Server.Resource.Attributes,
  Fido.JSON.Marshalling,
  Fido.Api.Server.Consul.Resource.Attributes,
  Fido.EventsDriven.Publisher.Intf,

  FidoApp.Constants,

  AuthenticationService.Domain.UseCases.Signup.Intf,
  AuthenticationService.Domain.UseCases.Remove.Intf,
  AuthenticationService.Domain.Entities.User;

type
  ISignupParams = interface(IInvokable)
    ['{C83412AE-F2EE-4C4C-AC48-217B43DC19F0}']
    function Username: string;
    function Password: string;
    function FirstName: string;
    function LastName: string;
  end;

  {$M+}
  [BaseUrl(Constants.API_PREFIX)]
  [Consumes(mtJson)]
  [Produces(mtJson)]
  TSignupV1ApiServerController = class(TObject)
  private type
    TSignupAndIdParams = record
    private
      FParams: ISignupParams;
      FId: TGuid;
    public
      constructor Create(const Params: ISignupParams; const Id: TGuid);

      property Params: ISignupParams read FParams;
      property Id: TGuid read FId;
    end;
    TPublishedParams = record
    private
      FId: TGuid;
      FIsPublished: Boolean;
    public
      constructor Create(const Id: TGuid; const IsPublished: Boolean);

      property Id: TGuid read FId;
      property IsPublished: Boolean read FIsPublished;
    end;

  private var
    FSignupUseCase: ISignupUseCase;
    FRemoveUseCase: IRemoveUseCase;
    FEventsPublisher: IEventsDrivenPublisher<string>;

    function ValidateRegisterParams(const RegisterParams: ISignupParams): ISignupParams;
    function MapToUser(const RegisterParams: ISignupParams): TUser;
    function Signup(const User: TUser): Context<TGuid>;
    function TryToPublish(const Params: TSignupAndIdParams): TPublishedParams;
    function DeleteAndRaise(const Params: TPublishedParams): TGuid;
    function ReturnId(const Params: TPublishedParams): TGuid;
    function Predicate(const Params: TPublishedParams): Boolean;
    function ValidateAndSignup(const RegisterParams: ISignupParams): TSignupAndIdParams;
    function DoSignup(const RegisterParams: ISignupParams): Context<TGuid>;
  public
    constructor Create(const SignupUseCase: ISignupUseCase; const RemoveUseCase: IRemoveUseCase; const EventsPublisher: IEventsDrivenPublisher<string>);

    [Path(rmPost, '/1/signup')]
    [ResponseCode(201, 'Created')]
    function Execute(const [BodyParam] RegisterParams: ISignupParams): TGuid;
  end;
  {$M-}

implementation

{ TSignupV1ApiServerController }

constructor TSignupV1ApiServerController.Create(
  const SignupUseCase: ISignupUseCase;
  const RemoveUseCase: IRemoveUseCase;
  const EventsPublisher: IEventsDrivenPublisher<string>);
begin
  inherited Create;

  FSignupUseCase := Utilities.CheckNotNullAndSet(SignupUseCase, 'SignupUseCase');
  FRemoveUseCase := Utilities.CheckNotNullAndSet(RemoveUseCase, 'RemoveUseCase');
  FEventsPublisher := Utilities.CheckNotNullAndSet(EventsPublisher, 'EventsPublisher');
end;

function TSignupV1ApiServerController.ValidateRegisterParams(const RegisterParams: ISignupParams): ISignupParams;
begin
  Result := RegisterParams;
  if RegisterParams.FirstName.IsEmpty or
     RegisterParams.LastName.IsEmpty then
    raise ESignupUseCaseValidation.Create('Firstname and Lastname cannot be empty.');
end;

function TSignupV1ApiServerController.MapToUser(const RegisterParams: ISignupParams): TUser;
begin
  Result := TUser.Create(RegisterParams.Username, RegisterParams.Password);
end;

function TSignupV1ApiServerController.Signup(const User: TUser): Context<TGuid>;
begin
  Result := FSignupUseCase.Run(User);
end;

function TSignupV1ApiServerController.TryToPublish(const Params: TSignupAndIdParams): TPublishedParams;
begin
  Result.Create(
    Params.Id,
    FEventsPublisher.Trigger('Authentication', 'UserAdded',
      Format('{"UserId": %s, "FirstName": "%s", "LastName": "%s"}',
      [JSONMarshaller.From(Params.Id), Params.Params.FirstName, Params.Params.LastName])).Value);
end;

function TSignupV1ApiServerController.Predicate(const Params: TPublishedParams): Boolean;
begin
  Result := Params.IsPublished;
end;

function TSignupV1ApiServerController.DeleteAndRaise(const Params: TPublishedParams): TGuid;
begin
  FRemoveUseCase.Run(Params.Id).Value;
  raise ERemoveUseCaseFailure.Create('Could not signup at this time');
end;

function TSignupV1ApiServerController.ReturnId(const Params: TPublishedParams): TGuid;
begin
  Result := Params.Id;
end;

function TSignupV1ApiServerController.ValidateAndSignup(const RegisterParams: ISignupParams): TSignupAndIdParams;
begin
  Result := TSignupAndIdParams.Create(
    RegisterParams,
    Context<ISignupParams>.
      New(RegisterParams).
      Map<ISignupParams>(ValidateRegisterParams).
      Map<TUser>(MapToUser).
      Map<TGuid>(Signup).Value
    );
end;

function TSignupV1ApiServerController.DoSignup(const RegisterParams: ISignupParams): Context<TGuid>;
begin
  Result := &If<TPublishedParams>.
    New(Context<ISignupParams>.
      New(RegisterParams).
      Map<TSignupAndIdParams>(ValidateAndSignup).
      Map<TPublishedParams>(TryToPublish)).
    Map(Predicate).
      &Then<TGuid>(ReturnId, DeleteAndRaise);
end;

function TSignupV1ApiServerController.Execute(const RegisterParams: ISignupParams): TGuid;
begin
  Result := &Try<ISignupParams>.
    New(RegisterParams).
    Map<TGuid>(DoSignup).
    Match(function(const E: Exception): Nullable<TGuid>
      begin
        if E is ESignupUseCaseValidation then
          raise EApiServer400.Create(E.Message);
      end);
end;

{ TSignupV1ApiServerController.TSignupAndIdParams }

constructor TSignupV1ApiServerController.TSignupAndIdParams.Create(
  const Params: ISignupParams;
  const Id: TGuid);
begin
  FParams := Params;
  FId := Id;
end;

{ TSignupV1ApiServerController.TPublishedParams }

constructor TSignupV1ApiServerController.TPublishedParams.Create(const Id: TGuid; const IsPublished: Boolean);
begin
  FId := Id;
  FIsPublished := IsPublished;
end;

end.
