unit FidoApp.Domain.UseCases.RefreshToken.Tests;

interface

uses
  System.SysUtils,

  DUnitX.TestFramework,

  Spring,
  Spring.Times,
  Spring.Collections,
  Spring.Mocking,

  Fido.Types,
  Fido.Exceptions,
  Fido.JSON.Marshalling,
  Fido.Testing.Mock.Utils,
  Fido.Api.Client.Exception,

  FidoApp.Types,
  FidoApp.Persistence.ApiClients.Authentication.V1.Intf,
  FidoApp.Persistence.Gateways.Authentication.Intf,
  FidoApp.Persistence.Gateways.Authentication,
  FidoApp.Persistence.Repositories.Authentication,
  FidoApp.Domain.Repositories.Authentication.Intf,
  FidoApp.Domain.UseCases.RefreshToken.Intf,
  FidoApp.Domain.UseCases.RefreshToken;

type
  ERefreshTokenUseCaseIntegrationTests = class(EFidoException);

  [TestFixture]
  TRefreshTokenUseCaseIntegrationTests = class
  public
    [Test]
    procedure RunReturnsTrueWhenRefreshTokenSucceds;

    [Test]
    procedure RunReturnsTrueWhenRefreshTokenFailsTwiceAndThenSucceds;

    [Test]
    procedure RunRaisesAnExceptionWhenTheGatewayRaisesAnException;

  end;

implementation

{ TRefreshTokenUseCaseIntegrationTests }

procedure TRefreshTokenUseCaseIntegrationTests.RunReturnsTrueWhenRefreshTokenSucceds;
var
  Api: Mock<IAuthenticationV1ApiClient>;
  Gateway: IAuthenticationV1ApiClientGateway;
  Repository: IAuthenticationRepository;
  RefreshTokenUseCase: IRefreshTokenUseCase;
begin
  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Executes.When.RefreshToken;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);

  Repository := TAuthenticationRepository.Create(Gateway);
  RefreshTokenUseCase := TRefreshTokenUseCase.Create(Repository);

  Assert.WillNotRaiseAny(
    procedure
    begin
      RefreshTokenUseCase.Run.Value;
    end);

  Api.Received(Times.Once).RefreshToken;
  Api.Received(Times.Never).Signup(Arg.IsAny<TSignupParams>);
  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
end;

procedure TRefreshTokenUseCaseIntegrationTests.RunRaisesAnExceptionWhenTheGatewayRaisesAnException;
var
  Api: Mock<IAuthenticationV1ApiClient>;
  Gateway: IAuthenticationV1ApiClientGateway;
  Repository: IAuthenticationRepository;
  RefreshTokenUseCase: IRefreshTokenUseCase;
begin
  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Raises<ERefreshTokenUseCaseIntegrationTests>.When.RefreshToken;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);
  Repository := TAuthenticationRepository.Create(Gateway);
  RefreshTokenUseCase := TRefreshTokenUseCase.Create(Repository);

  Assert.WillRaise(
    procedure
    begin
      RefreshTokenUseCase.Run.Value;
    end,
    ERefreshTokenUseCaseIntegrationTests);

  Api.Received(Times.Exactly(1)).RefreshToken;
  Api.Received(Times.Never).Signup(Arg.IsAny<TSignupParams>);
  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
end;

procedure TRefreshTokenUseCaseIntegrationTests.RunReturnsTrueWhenRefreshTokenFailsTwiceAndThenSucceds;
var
  Api: Mock<IAuthenticationV1ApiClient>;
  Gateway: IAuthenticationV1ApiClientGateway;
  Repository: IAuthenticationRepository;
  RefreshTokenUseCase: IRefreshTokenUseCase;
  Count: Integer;
begin
  Count := 0;

  Api := Mock<IAuthenticationV1ApiClient>.Create;
  Api.Setup.Executes(
    function(const callInfo: TCallInfo): TValue
    begin
      Inc(Count);

      case Count of
        1: raise EFidoClientApiException.Create(503, 'Error Message');
        2: raise EFidoClientApiException.Create(504, 'Error Message');
        3: ;
      end;
    end).When.RefreshToken;

  Gateway := TAuthenticationV1ApiClientGateway.Create(Api);
  Repository := TAuthenticationRepository.Create(Gateway);
  RefreshTokenUseCase := TRefreshTokenUseCase.Create(Repository);

  Assert.WillNotRaiseAny(
    procedure
    begin
      RefreshTokenUseCase.Run.Value;
    end);

  Api.Received(Times.Exactly(3)).RefreshToken;
  Api.Received(Times.Never).Signup(Arg.IsAny<TSignupParams>);
  Api.Received(Times.Never).Login(Arg.IsAny<TLoginParams>);
end;

initialization
  TDUnitX.RegisterTestFixture(TRefreshTokenUseCaseIntegrationTests);

end.
