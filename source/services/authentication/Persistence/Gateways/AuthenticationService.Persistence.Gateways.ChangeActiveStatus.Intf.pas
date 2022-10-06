unit AuthenticationService.Persistence.Gateways.ChangeActiveStatus.Intf;

interface

uses
  System.SysUtils,

  Fido.Utilities,
  Fido.Functional;

type
  TChangeActiveStatusGatewayCallData = record
  private
    FId: string;
    FStatus: Integer;
  public
    constructor Create(const Id: TGuid; const Active: Boolean);

    property Id: string read FId;
    property Status: Integer read FStatus;
  end;

  IChangeActiveStatusGateway = interface(IInvokable)
    ['{5B1D33C9-A1B4-46E7-A319-2DE55178F089}']

    function Execute(const CallData: TChangeActiveStatusGatewayCallData): Context<Integer>;
  end;

implementation

{ TChangeActiveStatusCallData }

constructor TChangeActiveStatusGatewayCallData.Create(const Id: TGuid; const Active: Boolean);
begin
  Self.FId := Id.ToString;
  Self.FStatus := Utilities.IfThen<Integer>(Active, 1, 0);
end;

end.
