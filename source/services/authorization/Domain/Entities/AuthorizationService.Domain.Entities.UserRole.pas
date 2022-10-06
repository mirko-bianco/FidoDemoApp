unit AuthorizationService.Domain.Entities.UserRole;

interface

uses
  System.SysUtils;

type
  TUserRole = record
  private
    FInitialized: string;
    FId: TGuid;
    FRole: string;
  public
    constructor Create(const Id: TGuid; const Role: string);

    function Initialized: Boolean;

    property Id: TGuid read FId;
    property Role: string read FRole;
  end;

implementation

{ TUserRole }

constructor TUserRole.Create(const Id: TGuid; const Role: string);
begin
  FId := Id;
  FRole := Role;
  FInitialized := 'True';
end;

function TUserRole.Initialized: Boolean;
begin
  Result := not FInitialized.IsEmpty;
end;

end.
