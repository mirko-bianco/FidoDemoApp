unit AuthenticationService.Domain.Entities.UserStatus;

interface

type
  TUserStatus = record
  private
    FId: TGuid;
    FActive: Boolean;
  public
    constructor Create(const Id: TGuid; const Active: Boolean);

    property Id: TGuid read FId;
    property Active: Boolean read FActive;
  end;

implementation

{ TUserStatus }

constructor TUserStatus.Create(const Id: TGuid; const Active: Boolean);
begin
  FId := Id;
  FActive := Active;
end;

end.
