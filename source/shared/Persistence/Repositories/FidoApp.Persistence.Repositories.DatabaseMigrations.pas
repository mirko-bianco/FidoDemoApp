unit FidoApp.Persistence.Repositories.DatabaseMigrations;

interface

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,

  Spring,
  Spring.Collections,

  Fido.Utilities,
  Fido.Db.Connections.FireDac,
  Fido.Db.Migrations.Repository.Intf;

type
  TDatabaseMigrationsRepository = class(TInterfacedObject, IDatabaseMigrationsRepository)
  private
    FDBConnections: TFireDacConnections;
    FDatabaseName: string;
  public
    constructor Create(const DBConnections: TFireDacConnections; const DatabaseName: string);

    function GetOldDBMigrations: ISet<string>;
    procedure SaveDBMigration(const FileName: string);

    procedure ExecSql(const Sql: string);
  end;

implementation

{ TDatabaseMigrationsRepository }

constructor TDatabaseMigrationsRepository.Create(
  const DBConnections: TFireDacConnections;
  const DatabaseName: string);
begin
  inherited Create;

  FDBConnections := Utilities.CheckNotNullAndSet(DBConnections, 'DBConnections');
  FDatabaseName := DatabaseName;
end;

procedure TDatabaseMigrationsRepository.ExecSql(const Sql: string);
begin
  FDBConnections.GetCurrent.ExecSQL(Sql);
end;

function TDatabaseMigrationsRepository.GetOldDBMigrations: ISet<string>;
var
  Query: IShared<TFDQuery>;
begin
  Result := TCollections.CreateSet<string>;
  Query := Shared.Make(TFDQuery.Create(nil));
  Query.Connection := FDBConnections.GetCurrent;
  Query.SQL.Text := Format('select filename from %s.dbmigrations', [FDatabaseName]);
  Query.Open;
  while not Query.Eof do
  begin
    Result.Add(Query.FieldValues['filename']);
    Query.Next;
  end;
end;

procedure TDatabaseMigrationsRepository.SaveDBMigration(const FileName: string);
begin
  FDBConnections.GetCurrent.ExecSQL(Format('insert into %s.dbmigrations (filename) values("%s")', [FDatabaseName, Filename]));
end;

end.
