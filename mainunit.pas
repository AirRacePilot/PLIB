unit MainUnit;

{ Teilebibliothek-Prototyp nach der Idee von ISO 13584 (PLIB):
  - Klassenhierarchie (is-a), Eigenschaften werden an Klassen definiert
    und an Unterklassen vererbt
  - Eigenschaften (mit Datentyp und Einheit) werden einmal definiert und
    können in mehreren Klassen verwendet werden
  - Teile (Instanzen) gehören zu einer Klasse und tragen Werte für die
    anwendbaren Eigenschaften
  Speicherung: SQLite (Open Source), Datei plib.sqlite3 neben der EXE. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Types, LCLType, Menus, Buttons, Clipbrd, ImgList, LCLIntf, Zipper, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, CheckLst, Grids, DB, SQLDB, SQLite3Conn, PQConnection, DockUnit, HtmlView, ClassSuggest, PluginHost, PlibTheme, PlibRibbon, PlibViews, PlibWin, PlibUtil, PlibDialogs,
  PlibIcons, Process, PlibDb, PlibSearch, PlibUpdate;

type
  TPropDef = record
    Id: Int64;
    Name, UnitName, DataType, Code: string;
    Direct: Boolean;   // direkt der Klasse zugeordnet (nicht geerbt)
    UseCount: Integer;     // in wie vielen Klassen verwendet (Katalog)
    Bsu: string;           // Lieferant/Code#Version
    Status: string;        // in Arbeit / freigegeben / veraltet
  end;
  TPropDefs = array of TPropDef;

  TSearchField = record
    Text: string;          // normalisiert (klein, ohne Umlaute)
    Weight: Integer;       // Gewicht des Feldes
  end;
  TSearchVal = record
    Code, Name, Value, Quantity: string;   // normalisiert
    Factor, Shift: Double;   // Einheit: Basiswert = Wert * Factor + Shift
  end;
  TSearchItem = record
    Kind: Integer;         // 0 Teil, 1 Klasse, 2 Merkmal
    Id, ClassId: Int64;
    Display: string;
    Fields: array of TSearchField;
    Vals: array of TSearchVal;
  end;
  TSearchItems = array of TSearchItem;

  TMainForm = class(TForm)
  published
    MainMenu1: TMainMenu;
    ToolPanel: TFlowPanel;
    SBar: TStatusBar;
    Work: TPanel;
    miDatei: TMenuItem;
    miMnuDbPath: TMenuItem;
    miMnuPgConnect: TMenuItem;
    miMnuPgImport: TMenuItem;
    miMnuPgExport: TMenuItem;
    miSep: TMenuItem;
    miMnuSampleData: TMenuItem;
    miMnuImportTree: TMenuItem;
    miMnuImportNormparts: TMenuItem;
    miMnuImportImages: TMenuItem;
    miMnuClearDb: TMenuItem;
    miBtnSuggestWeights: TMenuItem;
    miBtnClassTerms: TMenuItem;
    miMnuBackup: TMenuItem;
    miMnuCheckDb: TMenuItem;
    miMnuRestore: TMenuItem;
    miMnuOpenBackupDir: TMenuItem;
    miSep2: TMenuItem;
    miMnuQuit: TMenuItem;
    miSuche: TMenuItem;
    miBtnSearch: TMenuItem;
    miBtnPartSearch: TMenuItem;
    miKlassen: TMenuItem;
    miBtnNewClass: TMenuItem;
    miBtnRenameClass: TMenuItem;
    miBtnClassDesc: TMenuItem;
    miBtnClassTrans: TMenuItem;
    miBtnClassImage: TMenuItem;
    miBtnClassImageDel: TMenuItem;
    miBtnDelClass: TMenuItem;
    miMerkmale: TMenuItem;
    miBtnManageProps: TMenuItem;
    miBtnCatalog: TMenuItem;
    miTeile: TMenuItem;
    miBtnNewPart: TMenuItem;
    miBtnEditValues: TMenuItem;
    miBtnDelPart: TMenuItem;
    miBtnOpenCadLink: TMenuItem;
    miStammdaten: TMenuItem;
    miBtnSuppliers: TMenuItem;
    miMnuDataSources: TMenuItem;
    miBtnUnits: TMenuItem;
    miSolidEdge: TMenuItem;
    miBtnSeOpen: TMenuItem;
    miBtnSeAssign: TMenuItem;
    miBtnSeUnassign: TMenuItem;
    miBtnSeWriteProps: TMenuItem;
    miBtnSeInsert: TMenuItem;
    miBtnSeFind: TMenuItem;
    miSep4: TMenuItem;
    miBtnSeRoot: TMenuItem;
    miBtnSeDlDir: TMenuItem;
    miBtnSolidEdgeTest: TMenuItem;
    miAnsicht: TMenuItem;
    miMnuToggleToolbar: TMenuItem;
    miBereiche: TMenuItem;
    miPane0: TMenuItem;
    miPane1: TMenuItem;
    miPane2: TMenuItem;
    miPane3: TMenuItem;
    miPane4: TMenuItem;
    miMnuRefresh: TMenuItem;
    miMnuTreeExpand: TMenuItem;
    miMnuTreeCollapse: TMenuItem;
    miMnuResetLayout: TMenuItem;
    miMnuResetCols: TMenuItem;
    miBtnLang: TMenuItem;
    miMnuToggleIrdi: TMenuItem;
    miMnuToggleIds: TMenuItem;
    miHilfe: TMenuItem;
    miMnuManual: TMenuItem;
    miMnuManualBrowser: TMenuItem;
    miMnuHelp: TMenuItem;
    miMnuAbout: TMenuItem;
    miMnuUpdate: TMenuItem;
    miMnuShowLog: TMenuItem;
    procedure BtnCatalog(Sender: TObject);
    procedure BtnClassDesc(Sender: TObject);
    procedure BtnClassImage(Sender: TObject);
    procedure BtnClassImageDel(Sender: TObject);
    procedure BtnClassTrans(Sender: TObject);
    procedure BtnDelClass(Sender: TObject);
    procedure BtnDelPart(Sender: TObject);
    procedure BtnOpenCadLink(Sender: TObject);
    procedure BtnEditValues(Sender: TObject);
    procedure BtnLang(Sender: TObject);
    procedure BtnManageProps(Sender: TObject);
    procedure BtnNewClass(Sender: TObject);
    procedure BtnNewPart(Sender: TObject);
    procedure BtnRenameClass(Sender: TObject);
    procedure BtnSeAssign(Sender: TObject);
    procedure BtnSeFind(Sender: TObject);
    procedure BtnSeInsert(Sender: TObject);
    procedure BtnSeOpen(Sender: TObject);
    procedure BtnSeRoot(Sender: TObject);
    procedure BtnSeDlDir(Sender: TObject);
    procedure BtnSeUnassign(Sender: TObject);
    procedure BtnSeWriteProps(Sender: TObject);
    procedure BtnSearch(Sender: TObject);
    procedure BtnPartSearch(Sender: TObject);
    procedure BtnSolidEdgeTest(Sender: TObject);
    procedure BtnPluginRun(Sender: TObject);
    procedure MnuDesign(Sender: TObject);
    procedure BtnSuppliers(Sender: TObject);
    procedure MnuDataSources(Sender: TObject);
    procedure DsSelect(Sender: TObject);
    procedure DsOpen(Sender: TObject);
    procedure BtnUnits(Sender: TObject);
    procedure MnuAbout(Sender: TObject);
    procedure MnuCheckUpdate(Sender: TObject);
    procedure MnuBackup(Sender: TObject);
    procedure MnuCheckDb(Sender: TObject);
    procedure MnuDbPath(Sender: TObject);
    procedure MnuHelp(Sender: TObject);
    procedure MnuImportImages(Sender: TObject);
    procedure MnuImportTree(Sender: TObject);
    procedure MnuImportNormparts(Sender: TObject);
    procedure MnuClearDb(Sender: TObject);
    procedure BtnNewPartInClass(Sender: TObject);
    procedure BtnSuggestWeights(Sender: TObject);
    procedure BtnClassTerms(Sender: TObject);
    procedure NpRun(Sender: TObject);
    procedure NpListSelect(Sender: TObject);
    procedure NpListSel2(Sender: TObject; User: Boolean);
    procedure NpAllChange(Sender: TObject);
    procedure NpNewClass(Sender: TObject);
    procedure NpOkClick(Sender: TObject);
    procedure NpFillAll;
    function AskNewPartClass(out ACls: Int64; out ADesc, AManu: string): Boolean;
    procedure MnuManual(Sender: TObject);
    procedure MnuManualBrowser(Sender: TObject);
    procedure MnuOpenBackupDir(Sender: TObject);
    procedure MnuPgConnect(Sender: TObject);
    procedure MnuPgExport(Sender: TObject);
    procedure MnuPgImport(Sender: TObject);
    procedure MnuQuit(Sender: TObject);
    procedure MnuRefresh(Sender: TObject);
    procedure MnuResetCols(Sender: TObject);
    procedure MnuColumns(Sender: TObject);
    procedure SetPartsHidden(const AName: string; AHide: Boolean);
    procedure HeadHide(Sender: TObject);
    procedure HeadToggle(Sender: TObject);
    procedure HeadShowAll(Sender: TObject);
    procedure HeadReset(Sender: TObject);
    procedure GridPartsContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    function ClassCodeKey(AClass: Int64): string;
    procedure PartsHiddenFor(AClass: Int64; AOut: TStringList);
    procedure LoadColHidden(AIni: TIniFile);
    procedure SaveColHidden(AIni: TIniFile);
    procedure MnuResetLayout(Sender: TObject);
    procedure MnuRestore(Sender: TObject);
    procedure MnuSampleData(Sender: TObject);
    procedure MnuShowLog(Sender: TObject);
    procedure MnuToggleIds(Sender: TObject);
    procedure MnuToggleIrdi(Sender: TObject);
    procedure MnuTogglePane(Sender: TObject);
    procedure MnuToggleToolbar(Sender: TObject);
    procedure MnuTreeCollapse(Sender: TObject);
    procedure MnuTreeExpand(Sender: TObject);
  private
    QParts, QValues: TSQLQuery;
    FLoading: Boolean;
    MnuToolbarItem: TMenuItem;
    DockMgr: TPaneDock;
    PaneItems: array[0..4] of TMenuItem;
    HelpView: THtmlViewer;
    FHelpLoaded: Boolean;
    PHelp: TPanel;           // Bereich 'Bedienungsanleitung': Suchleiste + HelpView
    HelpEdit: TEdit;
    PHelpBar: TPanel;
    HelpLb: TLabel;
    HelpInfo: TLabel;
    FHelpQuery: string;
    Tree: TTreeView;
    GridParts, GridValues: TStringGrid;
    DlgList: TListBox;      // Liste im Dialog 'Merkmale verwalten'
    DlgClass: Int64;
    DlgProps: TPropDefs;
    DrCat: TListBox;        // Katalogliste im Dialog 'Merkmale verwalten' (Drag and Drop)
    DrFilter: TEdit;
    DrIds: array of Int64;
    CatList: TListBox;      // Liste im Dialog 'Merkmalkatalog'
    CatClass: Int64;
    CatProps: TPropDefs;
    CatTree: TTreeView;     // Klassenbaum im Katalog (Ziel fuers Ziehen)
    CatClsList: TListBox;   // Merkmale der gewaehlten Klasse im Katalog
    CatClsProps: TPropDefs;
    CatForm: TForm;
    SupList: TListBox;      // Liste im Dialog 'Lieferanten'
    SupIds: array of Int64;
    SrchItems: TSearchItems;
    SrchHits: array of Integer;
    SrchEdit: TEdit;
    SrchList: TListBox;
    SrchInfo: TLabel;
    SrchForm: TForm;
    SrchPickIdx: Integer;
    FIrdi: Boolean;
    MnuIrdiItem: TMenuItem;
    FShowIds: Boolean;
    PmForm: TForm;
    PmPartNo, PmDesc, PmManu, PmLink: TEdit;
    FPreDesc, FPreManu: string;     // Vorbelegung der Teile-Eingabemaske
    // Dialog "Neues Teil mit Klassenvorschlag"
    NpForm: TForm;
    NpDesc, NpManu: TEdit;
    NpList: TListBox;
    NpWhy: TMemo;
    NpAll: TComboBox;
    NpInfo: TLabel;
    NpOk: TButton;
    NpSug: TSuggestResult;
    NpCls, NpFirstSug: Int64;
    NpAllIds: array of Int64;
    NpBusy, NpCreated: Boolean;
    PmSup: TComboBox;
    PmSupIds: array of Int64;
    PmCtrls: array of TWinControl;
    PmCodes: array of TStringList;
    PmProps: TPropDefs;
    PmPart: Int64;
    FProgBar: TProgressBar;
    FProgLbl: TLabel;
    FProgDone: Integer;
    ImgTree: TImageList;
    ColOrderParts, ColOrderValues: TStringList;
    ColHiddenParts, ColHiddenValues: TStringList;   // Standard der ausgeblendeten Spalten (Namen)
    ColHiddenByClass: TStringList;                  // Klassencode=|Name|Name  (Teileliste je Klasse)
    FApplyingCols: Boolean;
    FSortName: string;
    CadRoot: string;
    DlDir: string;               // Download-Ordner des Browsers (CAD-Kataloge)
    FPlugins: TPluginInfos;      // Plugins aus dem Ordner plugins (siehe pluginhost.pas)
    FRibbon: TPlibRibbon;        // Menueband (plibribbon.pas), nil = alte Knopfleiste
    FDlTimer: TTimer;
    // Performance: verzoegertes Laden beim Blaettern im Klassenbaum
    FTreeTimer: TTimer;
    FTreeKeyTick: QWord;
    FPartsCapped: Boolean;     // Teileliste wurde auf MaxPartRows gekuerzt
    FDlSnap: TStringList;
    FDlPart: Int64;
    FDlStart: TDateTime;
    FDlTicks: Integer;
    FDlLast: string;
    FDlLastSize: Int64;
    FDlBusy: Boolean;
    PgHost, PgPort, PgDb, PgUser, PgPass: string;
    FIdleTick: QWord;
    FSortCol: Integer;
    FSortAsc: Boolean;
    FWasCrash: Boolean;
    FLastClass: Int64;
    FErrCount: Integer;
    FErrTick: QWord;
    FHintNode: TTreeNode;
    ImgView: TImage;
    ImgInfo: TLabel;
    PopImg: TPopupMenu;
    PopTree, PopParts, PopValues, PopHead: TPopupMenu;
    MnuShowIdsItem: TMenuItem;
    UnitList: TListBox;
    UnitIds: array of Int64;
    EnumList: TListBox;
    EnumIds: array of Int64;
    EnumProp: Int64;
    procedure BuildGui;
    procedure SetupMenu;
    procedure DrRefresh;
    procedure DrFilterChange(Sender: TObject);
    procedure DrLink(Sender: TObject);
    procedure DrUnlink(Sender: TObject);
    procedure DrOverOwn(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure DrOverCat(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure DrDropOwn(Sender, Source: TObject; X, Y: Integer);
    procedure DrDropCat(Sender, Source: TObject; X, Y: Integer);
    function PartMask(AClass, APart: Int64): Int64;
    function PmValue(I: Integer): string;
    procedure PmOk(Sender: TObject);
    procedure PmOpenLink(Sender: TObject);
    procedure LoadLayout;
    procedure SaveLayout;
    procedure ShowHelpAt(const AAnchor: string);
    procedure EnsureHelpLoaded;
    procedure HelpDoFind(AReverse: Boolean);
    procedure HelpFindNext(Sender: TObject);
    procedure HelpFindPrev(Sender: TObject);
    procedure HelpEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HelpBarResize(Sender: TObject);
    procedure HelpViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function HelpFileName: string;
    procedure InitDb;
    procedure SeedIfEmpty;
    function CurClass: Int64;
    function AddClass(const ACode, AName: string; AParent: Int64;
      const ADef: string; const ANo: string = ''): Int64;
    function EnsureProp(const ACode, AName, ADataType, AUnit: string): Int64;
    procedure LinkProp(AClass, AProp: Int64);
    function AddPart(AClass: Int64; const APartNo, ADesc: string): Int64;
    function NextPartNo: string;
    function CadFileBase(APart: Int64): string;
    function PartNoTaken(const ANo: string): Boolean;
    procedure MnuRenumber(Sender: TObject);
    procedure SetValue(APart, AProp: Int64; const AValue: string);
    function ApplicableProps(AClass: Int64): TPropDefs;
    function AskValue(const P: TPropDef; var V: string): Boolean;
    procedure EnsureColumn(const ATable, ACol, ADef: string);
    procedure MigrateSchema;
    function DefSupplier: Int64;
    function AskSupplier(const ACaption: string; var ASup: Int64): Boolean;
    procedure UnlinkProp(AClass, AProp: Int64; AKeepProp: Boolean = False);
    procedure DeleteProp(AProp: Int64);
    function AllProps: TPropDefs;
    function AskNewProp(out AExisting: Boolean): Int64;
    function EditPropDlg(const P: TPropDef): Boolean;
    procedure LoadTree(ASelect: Int64 = 0);
    procedure FillGrid(AGrid: TStringGrid; AQuery: TSQLQuery);
    procedure GridAutoSize(AGrid: TStringGrid);
    procedure TreeTimerFire(Sender: TObject);
    procedure TuneSqlite;
    function CurPart: Int64;
    procedure SelectPart(APart: Int64);
    procedure LoadParts;
    procedure LoadValues;
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure PartsSelect(Sender: TObject; aCol, aRow: Integer);
    procedure PartsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DlgRefresh;
    procedure DlgNew(Sender: TObject);
    procedure DlgEdit(Sender: TObject);
    procedure DlgDel(Sender: TObject);
    procedure CatRefresh;
    procedure CatNew(Sender: TObject);
    procedure CatEdit(Sender: TObject);
    procedure CatDel(Sender: TObject);
    procedure CatAssign(Sender: TObject);
    function SelectClass(AId: Int64): Boolean;
    procedure SearchLoad;
    procedure SearchRun(Sender: TObject);
    procedure SearchPick(Sender: TObject);
    procedure SearchGoto(AIdx: Integer);
    procedure SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure SearchKeyPress(Sender: TObject; var Key: Char);
    function AddPopItem(APopup: TPopupMenu; const ACaption: string;
      AClick: TNotifyEvent; ATag: Integer): TMenuItem;
    procedure BuildPopups;
    function ValueRowOk: Boolean;
    function ValueTarget(out APart, AProp: Int64): Boolean;
    procedure PopupOpen(Sender: TObject);
    procedure TreeMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure ListMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure MnuNewRootClass(Sender: TObject);
    procedure MnuCopyPartNo(Sender: TObject);
    procedure MnuCopyRow(Sender: TObject);
    procedure MnuValueEdit(Sender: TObject);
    procedure MnuValueDelete(Sender: TObject);
    procedure MnuValueCopy(Sender: TObject);
    procedure MakeDlgPopup(AList: TListBox);
    procedure MakeCatPopup(AList: TListBox);
    function IdSql(const AAlias: string): string;
    function CadFullPath(const AStored: string): string;
    function CadStoredPath(const AFull: string): string;
    procedure BuildSeProps(APart: Int64; AList: TStrings);
    function SeGetApp(out SE: Variant): Boolean;
    function SeOpenFile(const APath: string; out SE, Doc: Variant): Boolean;
    function SeTemplateFor(const SE: Variant): string;
    procedure GridColMoved(Sender: TObject; IsColumn: Boolean; sIndex, tIndex: Integer);
    procedure ApplyColOrder(AGrid: TStringGrid; AOrder: TStringList);
    function SolidEdgeHint(E: Exception): string;
    procedure SetupPlugins;
    procedure BuildRibbon;
    procedure MnuRibbon(Sender: TObject);
    procedure MnuDpiInfo(Sender: TObject);
    procedure MnuFontSize(Sender: TObject);
    function PluginCollect(APart: Int64; AChain, ACodes, AVals, AUnits: TStrings): string;
    procedure LoadDbSettings;
    procedure SavePgSettings(const AHost, APort, ADb, AUser, APass: string;
      AStorePw: Boolean);
    function DbDescription: string;
    procedure CopyTable(ASrc: TSQLConnection; ASrcTr: TSQLTransaction;
      ADst: TSQLConnection; ADstTr: TSQLTransaction; const ATable, AOrder: string);
    procedure PgSwitchBack;
    procedure AppIdle(Sender: TObject; var Done: Boolean);
    function PgNoFile: Boolean;
    function DefaultDbPath: string;
    function AbsDbPath(const P: string): string;
    function ResolveDbPath: string;
    procedure SaveDbPath(const AFile: string);
    procedure UpdateDbInfo;
    function BackupPrefix: string;
    procedure PrepareDatabase;
    procedure OfferSeed;
    procedure SwitchDatabase(const ANewPath: string);
    procedure UpdateStatus;
    procedure ShowStatus(const AMsg: string);
    procedure ShowPartFromSearch(AClass, APart: Int64);
    procedure StartDlWatch(APart: Int64);
    procedure DlTimerTick(Sender: TObject);
    procedure DlTakeFile(const AFull: string);
    function DlUnzip(const AZip, ADir: string): string;
    function DlFolder: string;
    function SuggestClassName(AParent: Int64): string;
    function SuggestClassCode(AParent: Int64): string;
    procedure TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValuesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PartsCompare(Sender: TObject; ACol, ARow, BCol, BRow: Integer;
      var Result: Integer);
    procedure ApplyPartSort;
    procedure PartsHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
    function SessionFileName: string;
    procedure CreateSessionFile;
    function BackupDir: string;
    procedure BackupList(AList: TStrings);
    function NewestBackup: string;
    procedure MakeAutoBackup;
    procedure RestoreFromBackup(const ABackup: string);
    procedure CheckDatabase(AWasCrash: Boolean);
    function FriendlyError(E: Exception): string;
    function ReadClassImage(AClass: Int64; AStream: TStream; out AExt: string;
      out AOwner: Int64): Boolean;
    function LoadClassPicture(AClass: Int64; APic: TPicture; out AOwner: Int64): Boolean;
    procedure DockChanged(Sender: TObject);
    procedure AsyncBuild(Data: PtrInt);
    procedure UpdateClassImage;
    procedure MainShow(Sender: TObject);
    procedure UpdateAuto(Data: PtrInt);
    procedure StartUpdate(AManual: Boolean);
    procedure UpdateDone(const AInfo: TUpdateInfo; AManual: Boolean);
    procedure InstallUpdate(const AInfo: TUpdateInfo);
    procedure FormWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint; var Handled: Boolean);
    procedure ImgSaveAs(Sender: TObject);
    procedure TreeCustomDraw(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    function TreeHintText(Node: TTreeNode): string;
    procedure TreeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    function CodeTaken(const ATable, ACode: string; AExceptId: Int64): Boolean;
    procedure AppException(Sender: TObject; E: Exception);
    function NextClassNo(AParent: Int64): string;
    function CheckClassNo(const ANo: string; AParent, ASelf: Int64; out AMsg: string): Boolean;
    procedure AssignClassNumbers;
    procedure MigrateSchema3;
    function PartPropColumns(AClass: Int64): string;
    procedure SyncUnitId(AProp: Int64);
    procedure SeedUnits;
    procedure MigrateSchema2;
    procedure DescProp(AProp: Int64);
    procedure EditTranslation(const AKind: string; ARefId: Int64; const ABase: string);
    procedure ImportTreeFile(const AFile: string);
    procedure UnitRefresh;
    procedure UnitNew(Sender: TObject);
    procedure UnitEdit(Sender: TObject);
    procedure UnitDel(Sender: TObject);
    procedure ManageEnum(AProp: Int64);
    procedure EnumRefresh;
    procedure EnumNew(Sender: TObject);
    procedure EnumEdit(Sender: TObject);
    procedure EnumTrans(Sender: TObject);
    procedure EnumDel(Sender: TObject);
    procedure DlgDesc(Sender: TObject);
    procedure DlgTrans(Sender: TObject);
    procedure DlgEnum(Sender: TObject);
    procedure CatDesc(Sender: TObject);
    procedure CatTrans(Sender: TObject);
    procedure CatEnum(Sender: TObject);
    procedure CatBuildTree;
    procedure CatClsRefresh;
    function CatLinkSel(AClass: Int64): Integer;
    procedure CatTreeChange(Sender: TObject; Node: TTreeNode);
    procedure CatOverTree(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure CatDropTree(Sender, Source: TObject; X, Y: Integer);
    procedure CatOverList(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure CatDropList(Sender, Source: TObject; X, Y: Integer);
    procedure CatUnlinkCls(Sender: TObject);
    procedure CatClose(Sender: TObject);
    function DlgToolbar(F: TForm): TPanel;
    procedure DlgTB(P: TPanel; AIcon: Integer; const AHint: string; AClick: TNotifyEvent);
    procedure DlgTBSep(P: TPanel);
    procedure DlgTBClose(P: TPanel);
    procedure DlgCloseClick(Sender: TObject);
    procedure SupRefresh;
    procedure SupNew(Sender: TObject);
    procedure SupEdit(Sender: TObject);
    procedure SupDel(Sender: TObject);
    procedure SupDefault(Sender: TObject);
    procedure HandleFormDestroy(Sender: TObject);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{$IFDEF WINDOWS}
uses
  ComObj, Variants;
{$ENDIF}

const
  MaxPartRows = 2000;     // Teileliste: hoechstens so viele Zeilen anzeigen
  TreeDelayMs = 150;      // Klassenbaum: Verzoegerung beim Blaettern mit Tasten
  AutoSizeRows = 300;     // Spaltenbreite nur an den ersten Zeilen messen
  AppVersion = {$I version.inc};   // die Versionsnummer steht nur in version.inc
  AppAuthor = 'Frank Mergl';
  AppCopyright = '© 2026 Frank Mergl';
  {$IFDEF DARWIN}
  ModKey = ssMeta;      // am Mac: Befehlstaste
  ModTxt = 'Cmd+';
  {$ELSE}
  ModKey = ssCtrl;
  ModTxt = 'Strg+';
  {$ENDIF}

{ ---------- Suchalgorithmus: Hilfsfunktionen ---------- }

procedure AddFld(var It: TSearchItem; const AText: string; AWeight: Integer);
var
  n: Integer;
begin
  if Trim(AText) = '' then Exit;
  n := Length(It.Fields);
  SetLength(It.Fields, n + 1);
  It.Fields[n].Text := Fold(AText);
  It.Fields[n].Weight := AWeight;
end;

function FilterPass(const It: TSearchItem; const F: TSearchFilter): Boolean;
var
  i, UIdx: Integer;
  A, B: Double;
  NumA, NumB, Ok: Boolean;
  RhsUnit: string;
  V: TSearchVal;
begin
  Result := False;
  for i := 0 to High(It.Vals) do
  begin
    V := It.Vals[i];
    if not ((V.Code = F.Key) or (V.Name = F.Key) or
      ((Length(F.Key) >= 3) and (Pos(F.Key, V.Name) = 1))) then Continue;
    Ok := False;
    if F.Op = ':' then
      Ok := Pos(F.Rhs, V.Value) > 0
    else
    begin
      NumA := ParseNum(V.Value, A);
      NumB := ParseNumUnit(F.Rhs, B, RhsUnit);
      if NumA and NumB and (RhsUnit <> '') then
      begin
        // Einheiten umrechnen, wenn das Merkmal eine Einheit gleicher Groessenart hat
        UIdx := FindUnitRec(RhsUnit);
        if (UIdx >= 0) and (V.Quantity <> '') and (GUnits[UIdx].Quantity = V.Quantity) then
        begin
          A := A * V.Factor + V.Shift;
          B := B * GUnits[UIdx].Factor + GUnits[UIdx].Shift;
        end
        else
          NumB := False;
      end;
      if NumA and NumB then
      begin
        if F.Op = '=' then Ok := Abs(A - B) < 1E-9
        else if F.Op = '>' then Ok := A > B
        else if F.Op = '<' then Ok := A < B
        else if F.Op = '>=' then Ok := A >= B
        else if F.Op = '<=' then Ok := A <= B;
      end
      else if (F.Op = '=') and (RhsUnit = '') then
        Ok := V.Value = F.Rhs;
    end;
    if Ok then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

{ ---------- Aufbau ---------- }

constructor TMainForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);   // Hauptfenster, Menue, Statusleiste aus mainunit.lfm
  Caption := 'Teilebibliothek (ISO 13584 / PLIB) - Version ' + AppVersion;
  OnDestroy := @HandleFormDestroy;
  Application.OnException := @AppException;
  Application.OnIdle := @AppIdle;
  OnShow := @MainShow;
  OnMouseWheel := @FormWheel;
  FSortCol := -1;
  FSortAsc := True;
  ColOrderParts := TStringList.Create;
  ColOrderValues := TStringList.Create;
  ColHiddenParts := TStringList.Create;
  ColHiddenValues := TStringList.Create;
  ColHiddenByClass := TStringList.Create;
  ColHiddenParts.Add('Klasse');   // Standard: Klassenname steht schon im Baum
  BuildGui;
  SetupMenu;
  BuildPopups;
  LoadLayout;
  FWasCrash := FileExists(SessionFileName);
  try
    InitDb;
    CreateSessionFile;
    OfferSeed;
    LoadTree(FLastClass);
  except
    on E: Exception do
    begin
      if DbCtx.IsPg then
        ShowMessage('Die Verbindung zum PostgreSQL-Server ist fehlgeschlagen:' + LineEnding +
          LineEnding + FriendlyError(E) + LineEnding + LineEnding +
          'Prüfe: Läuft der Container auf dem NAS? Stimmen Adresse, Port, Benutzer und ' +
          'Passwort? Erlaubt die NAS-Firewall den Port? Liegt libpq.dll neben der plib.exe?' +
          LineEnding + LineEnding +
          'Zurück zu SQLite: in plib.ini unter [Datenbank] den Eintrag Typ=sqlite setzen ' +
          'oder das Programm mit einem Dateipfad als Parameter starten.')
      else
        ShowMessage('Das Programm kann nicht starten:' + LineEnding + E.Message +
          LineEnding + LineEnding +
          'Mögliche Ursachen: sqlite3.dll fehlt oder passt nicht zum Programm ' +
          '(32 oder 64 Bit), die Datei plib.sqlite3 ist gesperrt oder schreibgeschützt, ' +
          'oder der Programmordner ist nicht beschreibbar.');
      Halt(1);
    end;
  end;
  ShowStatus('Bereit.');
end;

procedure TMainForm.HandleFormDestroy(Sender: TObject);
begin
  try
    SaveLayout;
  except
    // Layout nicht speicherbar: unkritisch
  end;
  try
    // SQLite: Statistiken fuer bessere Abfrageplaene aktualisieren (dauert nur ms)
    if Assigned(DbCtx.Conn) and DbCtx.Conn.Connected and not DbCtx.IsPg then
    try
      DbCtx.Conn.ExecuteDirect('PRAGMA optimize');
    except
      // nicht kritisch
    end;
    if Assigned(DbCtx.Trans) and DbCtx.Trans.Active then DbCtx.Trans.Commit;
    if Assigned(DbCtx.Conn) then DbCtx.Conn.Close;
  except
    // Datenbank wird beim naechsten Start geprueft
  end;
  ColOrderParts.Free;
  ColOrderValues.Free;
  ColHiddenParts.Free;
  ColHiddenValues.Free;
  ColHiddenByClass.Free;
  DockMgr.Free;
  DockMgr := nil;
  DeleteFile(SessionFileName);   // sauberes Beenden markieren
end;

procedure TMainForm.BuildGui;
var
  PImg, PBot: TPanel;
  K: Integer;
  TreeBmp: TBitmap;
  TreeIconSize: Integer;
  HelpBt: TButton;

  function AddBtn(AIcon: Integer; const AHint: string;
    AClick: TNotifyEvent): TSpeedButton;
  var
    Bmp: TBitmap;
  begin
    Result := TSpeedButton.Create(Self);
    Result.Parent := ToolPanel;
    Result.Width := 44;
    Result.Height := 44;
    Result.Flat := True;
    Result.Tag := AIcon + 1;       // Symbolnummer fuer das Menueband (scharfe Symbole)
    Result.BorderSpacing.Around := 2;
    Bmp := MakeIconGlyph(AIcon, 32);
    try
      Result.Glyph.Assign(Bmp);
    finally
      Bmp.Free;
    end;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AClick;
  end;

  procedure AddSep;
  var
    Bv: TBevel;
  begin
    Bv := TBevel.Create(Self);
    Bv.Parent := ToolPanel;
    Bv.Shape := bsSpacer;
    Bv.Width := 12;
    Bv.Height := 44;
  end;

  function AddGrid: TStringGrid;
  begin
    Result := TStringGrid.Create(Self);
    Result.FixedCols := 0;
    Result.ColCount := 1;
    Result.RowCount := 1;
    Result.FixedRows := 1;
    Result.Options := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
      goColSizing, goColMoving, goRowSelect, goThumbTracking];
  end;

begin
  // Knopfleiste (ToolPanel), Statusleiste (SBar) und Arbeitsbereich (Work) kommen aus mainunit.lfm
  DockMgr := TPaneDock.Create(Self, Work);
  DockMgr.DefaultLayout := 'H280(V620(tree,image),V620(parts,values))';
  DockMgr.OnChange := @DockChanged;
  DockMgr.AttachToolbar(ToolPanel, SBar);

  AddBtn(0, 'Suche (' + ModTxt + 'F)' + LineEnding +
    'Teile suchen, auch nach Merkmalen', @BtnPartSearch);
  AddBtn(11, 'Datensprache wählen' + LineEnding +
    'Namen und Definitionen in einer anderen Sprache anzeigen', @BtnLang);
  AddSep;
  AddBtn(1, 'Neue Klasse (' + ModTxt + 'N)' + LineEnding +
    'Legt unterhalb der gewählten Klasse eine neue Klasse an', @BtnNewClass);
  AddBtn(2, 'Klasse umbenennen (F2)' + LineEnding +
    'Code, Name, Lieferant und Version der gewählten Klasse ändern', @BtnRenameClass);
  AddBtn(10, 'Beschreibung / Status (' + ModTxt + 'D)' + LineEnding +
    'Kurzname, Synonyme, Definition, Anmerkung und Status der gewählten Klasse', @BtnClassDesc);
  AddBtn(12, 'Klassenbild zuordnen' + LineEnding +
    'Bild der Teilefamilie wählen; es erscheint beim Anwählen der Klasse im Klassenbild-Bereich',
    @BtnClassImage);
  AddBtn(3, 'Klasse löschen' + LineEnding +
    'Entfernt die gewählte Klasse (nur ohne Unterklassen)', @BtnDelClass);
  AddSep;
  AddBtn(4, 'Merkmale verwalten (' + ModTxt + 'M)' + LineEnding +
    'Merkmale der gewählten Klasse anlegen, ändern und entfernen', @BtnManageProps);
  AddBtn(5, 'Merkmalkatalog (' + ModTxt + 'K)' + LineEnding +
    'Alle Merkmale der Bibliothek, unabhängig von Klassen', @BtnCatalog);
  AddBtn(6, 'Lieferanten' + LineEnding +
    'Lieferanten und Standard-Lieferant verwalten', @BtnSuppliers);
  AddSep;
  AddBtn(7, 'Neues Teil (' + ModTxt + 'T)' + LineEnding +
    'Legt ein neues Teil an; PLIB schlägt die Klasse vor', @BtnNewPart);
  AddBtn(8, 'Werte / Teil bearbeiten (' + ModTxt + 'E)' + LineEnding +
    'Merkmalswerte, Teilenummer und Beschreibung des gewählten Teils ändern',
    @BtnEditValues);
  AddBtn(9, 'Teil löschen' + LineEnding +
    'Löscht das gewählte Teil samt seinen Werten', @BtnDelPart);
  AddSep;
{$IFDEF WINDOWS}
  AddBtn(13, 'Solid Edge testen' + LineEnding +
    'Prüft, ob sich Solid Edge von PLIB aus ansprechen lässt', @BtnSolidEdgeTest);
  AddBtn(14, 'Teil in Solid Edge öffnen (' + ModTxt + 'O)' + LineEnding +
    'Öffnet die dem gewählten Teil zugeordnete CAD-Datei in Solid Edge', @BtnSeOpen);
  AddBtn(15, 'Eigenschaften nach Solid Edge schreiben' + LineEnding +
    'Schreibt Teilenummer, Benennung, Klasse, Lieferant, BSU und Merkmalswerte in die CAD-Datei',
    @BtnSeWriteProps);
  AddBtn(16, 'Teil in Baugruppe einfügen' + LineEnding +
    'Fügt die CAD-Datei des gewählten Teils in die aktive Solid-Edge-Baugruppe ein',
    @BtnSeInsert);
  AddBtn(17, 'Aktuelles Solid-Edge-Dokument in PLIB zeigen (' + ModTxt + 'G)' + LineEnding +
    'Wählt in PLIB das Teil, das zum aktiven Solid-Edge-Dokument gehört', @BtnSeFind);
  AddSep;
{$ENDIF}
  AddBtn(20, 'Bedienungsanleitung (F1)' + LineEnding +
    'Zeigt die Anleitung im Programm (springt zum passenden Kapitel)', @MnuManual);

  BuildRibbon;

  // Klassenbaum
  Tree := TTreeView.Create(Self);
  Tree.ReadOnly := True;
  Tree.HideSelection := False;
  Tree.OnChange := @TreeChange;

  // Aussehen: Pfeile zum Auf-/Zuklappen, Symbole nach Status, Zeilenauswahl
  ImgTree := TImageList.Create(Self);
  // Symbolgroesse: etwa doppelt so gross wie frueher (bei 100 % 17, bei 175 % rund 30 Pixel)
  TreeIconSize := (17 * Screen.PixelsPerInch + 48) div 96;
  if TreeIconSize < 16 then TreeIconSize := 16;
  ImgTree.Width := TreeIconSize;
  ImgTree.Height := TreeIconSize;
  for K := 0 to 5 do
  begin
    TreeBmp := MakeTreeIcon(K >= 3, K mod 3, TreeIconSize);
    try
      ImgTree.AddMasked(TreeBmp, clFuchsia);
    finally
      TreeBmp.Free;
    end;
  end;
  Tree.Images := ImgTree;
  Tree.ExpandSignType := tvestArrow;
  Tree.Indent := (22 * Screen.PixelsPerInch + 48) div 96;
  Tree.Options := Tree.Options + [tvoRowSelect, tvoHotTrack, tvoThemedDraw] -
    [tvoShowLines];
  Tree.ShowHint := True;
  Tree.OnMouseMove := @TreeMouseMove;
  Tree.OnCustomDrawItem := @TreeCustomDraw;

  GridParts := AddGrid;
  GridParts.OnSelection := @PartsSelect;
  GridParts.OnKeyDown := @PartsKeyDown;
  GridParts.OnHeaderClick := @PartsHeaderClick;
  GridParts.OnColRowMoved := @GridColMoved;
  GridParts.OnCompareCells := @PartsCompare;
  GridValues := AddGrid;
  GridValues.OnColRowMoved := @GridColMoved;
  GridValues.OnKeyDown := @ValuesKeyDown;
  Tree.OnKeyDown := @TreeKeyDown;
  StyleTree(Tree);
  StyleGrid(GridParts);
  StyleGrid(GridValues);

  // Klassenbild: dauerhaft sichtbarer Bereich
  PImg := TPanel.Create(Self);
  PImg.BevelOuter := bvNone;
  PImg.Caption := '';
  PBot := TPanel.Create(Self);
  PBot.Parent := PImg;
  PBot.Align := alBottom;
  PBot.Height := 24;
  PBot.BevelOuter := bvNone;
  PBot.Caption := '';
  ImgInfo := TLabel.Create(Self);
  ImgInfo.Parent := PBot;
  ImgInfo.Left := 6;
  ImgInfo.Top := 4;
  PopImg := TPopupMenu.Create(Self);
  AddPopItem(PopImg, 'Bild zuordnen ...', @BtnClassImage, 1);
  AddPopItem(PopImg, 'Bild entfernen', @BtnClassImageDel, 1);
  AddPopItem(PopImg, '-', nil, 1);
  AddPopItem(PopImg, 'Bild speichern unter ...', @ImgSaveAs, 1);
  ImgView := TImage.Create(Self);
  ImgView.Parent := PImg;
  ImgView.Align := alClient;
  ImgView.Proportional := True;
  ImgView.Stretch := True;
  ImgView.Center := True;
  ImgView.PopupMenu := PopImg;

  // Bereiche beim Andock-System anmelden
  DockMgr.AddPane('tree', 'Klassen', Tree);
  DockMgr.AddPane('parts', 'Teile der gewählten Klasse (inkl. Unterklassen)', GridParts);
  DockMgr.AddPane('values', 'Merkmalswerte des gewählten Teils', GridValues);
  DockMgr.AddPane('image', 'Klassenbild', PImg);
  // Bedienungsanleitung im Programm (standardmaessig ausgeblendet)
  PHelp := TPanel.Create(Self);
  PHelp.BevelOuter := bvNone;
  PHelp.Caption := '';
  PHelpBar := TPanel.Create(Self);
  PHelpBar.Parent := PHelp;
  PHelpBar.Align := alTop;
  PHelpBar.Height := 42;
  PHelpBar.BevelOuter := bvNone;
  PHelpBar.Caption := '';
  HelpLb := TLabel.Create(Self);
  HelpLb.Parent := PHelpBar;
  HelpLb.Left := 8;
  HelpLb.Top := 9;
  HelpLb.Caption := 'Suchen:';
  HelpEdit := TEdit.Create(Self);
  HelpEdit.Parent := PHelpBar;
  HelpEdit.SetBounds(62, 5, 300, 28);
  HelpEdit.TextHint := 'In der Anleitung suchen';
  HelpEdit.OnKeyDown := @HelpEditKeyDown;
  HelpBt := TButton.Create(Self);
  HelpBt.Parent := PHelpBar;
  HelpBt.SetBounds(370, 4, 90, 30);
  HelpBt.Caption := 'Weiter';
  HelpBt.OnClick := @HelpFindNext;
  HelpBt.Name := 'HelpBtNext';
  HelpBt := TButton.Create(Self);
  HelpBt.Parent := PHelpBar;
  HelpBt.SetBounds(466, 4, 90, 30);
  HelpBt.Caption := 'Zurück';
  HelpBt.OnClick := @HelpFindPrev;
  HelpBt.Name := 'HelpBtPrev';
  PHelpBar.OnResize := @HelpBarResize;
  HelpInfo := TLabel.Create(Self);
  HelpInfo.Parent := PHelpBar;
  HelpInfo.Left := 570;
  HelpInfo.Top := 9;
  HelpInfo.Caption := '';
  HelpView := THtmlViewer.Create(Self);
  HelpView.Parent := PHelp;
  HelpView.Align := alClient;
  HelpView.OnKeyDown := @HelpViewKeyDown;
  {$IFDEF DARWIN}
  HelpView.DefFontName := 'Helvetica Neue';
  HelpView.DefFontSize := 12;
  {$ELSE}
  HelpView.DefFontName := 'Segoe UI';
  {$ENDIF}
  HelpView.DefFontSize := 10;
  DockMgr.AddPane('help', 'Bedienungsanleitung', PHelp);
  DockMgr.DefaultHidden := 'help';
  DockMgr.ResetDefault;
end;

{ ---------- Menue ---------- }

procedure TMainForm.SetupMenu;
{$IFDEF DARWIN}
  procedure FixKeys(AItem: TMenuItem);
  var
    I: Integer;
    Key: Word;
    Shift: TShiftState;
  begin
    if AItem.ShortCut <> 0 then
    begin
      ShortCutToKey(AItem.ShortCut, Key, Shift);
      if ssCtrl in Shift then
      begin
        Shift := Shift - [ssCtrl] + [ssMeta];   // am Mac: Befehlstaste
        AItem.ShortCut := ShortCut(Key, Shift);
      end;
    end;
    for I := 0 to AItem.Count - 1 do FixKeys(AItem[I]);
  end;
{$ENDIF}
begin
  // Das Menue steht in mainunit.lfm (Lazarus-Formular-Designer); hier nur Verknuepfungen
  MnuToolbarItem := miMnuToggleToolbar;
  MnuIrdiItem := miMnuToggleIrdi;
  MnuShowIdsItem := miMnuToggleIds;
  PaneItems[0] := miPane0;
  PaneItems[1] := miPane1;
  PaneItems[2] := miPane2;
  PaneItems[3] := miPane3;
  PaneItems[4] := miPane4;
  FShowIds := True;
  {$IFDEF DARWIN}
  miMnuPgConnect.Visible := False;
  miMnuPgImport.Visible := False;
  miMnuPgExport.Visible := False;
  FixKeys(MainMenu1.Items);
  {$ENDIF}
  {$IFNDEF WINDOWS}
  miSolidEdge.Visible := False;
  {$ENDIF}
end;

procedure TMainForm.MnuQuit(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.MnuToggleToolbar(Sender: TObject);
begin
  DockMgr.ToolbarVisible := MnuToolbarItem.Checked;
  if FRibbon <> nil then FRibbon.Visible := DockMgr.ToolbarVisible;
end;

procedure TMainForm.MnuResetLayout(Sender: TObject);
begin
  if MessageDlg('Alle Bereiche und die Knopfleiste auf die Standardanordnung ' +
    'zurücksetzen?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  DockMgr.ResetDefault;
  DockMgr.Rebuild;
end;

procedure TMainForm.MnuHelp(Sender: TObject);
begin
  ShowMessage(
    'Aufbau' + LineEnding +
    'Links der Klassenbaum. Klasse anklicken: rechts oben erscheinen ihre Teile ' +
    '(inkl. Unterklassen). Teil anklicken: darunter stehen seine Merkmalswerte.' + LineEnding +
    'Die Trennlinien zwischen den Bereichen lassen sich mit der Maus verschieben; ' +
    'die Aufteilung wird beim Beenden gespeichert.' + LineEnding + LineEnding +
    'Rechtsklick auf Klasse, Teil, Merkmalswert oder Merkmal öffnet ein Kontextmenü.' +
    LineEnding + LineEnding +
    'Klassenbaum: Die Pfeile klappen Zweige auf und zu. Ein Ordner ist eine Klasse mit ' +
    'Unterklassen. Orange = in Arbeit, gruen = freigegeben, grau und durchgestrichen = ' +
    'veraltet. Die Zahl in Klammern ist die Anzahl der Teile der Klasse; ein Hinweisfenster ' +
    'zeigt weitere Angaben, wenn du mit der Maus ueber einer Klasse stehst.' +
    LineEnding + LineEnding +
    'Klassenbild: Jeder Klasse kann ein Bild zugeordnet werden (Klassen, Bild zuordnen). ' +
    'Es erscheint beim Anwählen der Klasse in einem kleinen Fenster, das du verschieben ' +
    'und in der Größe ändern kannst. Hat eine Klasse kein eigenes Bild, wird das Bild ' +
    'der nächsten Oberklasse gezeigt. Rechtsklick auf das Bild: zuordnen, entfernen, ' +
    'speichern, Fenster an die Bildgröße anpassen.' +
    LineEnding + LineEnding +
    'Tastatur: Einfg = neu, Entf = löschen, Eingabe = bearbeiten bzw. in die Teileliste ' +
    'wechseln, Esc = zurück zum Baum, F5 = aktualisieren. Ein Doppelklick auf ein Teil ' +
    'oder einen Wert öffnet die Bearbeitung, ein Klick auf eine Spaltenüberschrift ' +
    'sortiert die Teileliste. Zieht man eine Überschrift mit der Maus, wandert die Spalte ' +
    'an eine andere Stelle; die Reihenfolge wird gemerkt.' + LineEnding + LineEnding +
    'Datenbankort: „Datei, Datenbank wechseln" öffnet oder legt eine Datenbank an einem ' +
    'beliebigen Ort an (auch auf einem Netzlaufwerk). Die Einstellung steht in plib.ini ' +
    'unter [Datenbank] Pfad=. Alternativ startest du das Programm mit dem Pfad als ' +
    'Parameter: plib.exe "D:\Daten\teile.sqlite3".' + LineEnding + LineEnding +
    'Solid Edge: Jedem Teil lässt sich eine CAD-Datei zuordnen (Menü Solid Edge oder ' +
    'Rechtsklick auf das Teil). „In Solid Edge öffnen" lädt sie, „Eigenschaften nach ' +
    'Solid Edge schreiben" überträgt Teilenummer, Benennung, Klasse, Lieferant, BSU und ' +
    'die Merkmalswerte als benutzerdefinierte Eigenschaften (PLIB_...) und speichert die Datei. ' +
    '„In Baugruppe einfügen" setzt die CAD-Datei des Teils in die aktive Solid-Edge-Baugruppe, ' +
    '„Aktuelles Dokument in PLIB zeigen" (' + ModTxt + 'G) wählt in PLIB das Teil zum aktiven ' +
    'Solid-Edge-Dokument.' +
    LineEnding + LineEnding +
    'Mehrere Rechner: „Datei, Mit PostgreSQL-Server verbinden" richtet die Verbindung zu ' +
    'einem PostgreSQL-Server ein (z. B. auf dem NAS). Dafür muss die libpq.dll neben der ' +
    'plib.exe liegen. „Daten aus SQLite-Datei nach PostgreSQL übernehmen" überträgt ' +
    'vorhandene Daten.' + LineEnding + LineEnding +
    'Sicherheit: Beim Start wird die Datenbank geprüft und im Ordner backup gesichert ' +
    '(die letzten 20 bleiben erhalten). Fehler stehen in plib_error.log.' +
    LineEnding + LineEnding +
    'Teilesuche (' + ModTxt + 'F)' + LineEnding +
    'Sucht direkt in der Datenbank. Mehrere Wörter müssen alle passen. Merkmale grenzt du ' +
    'mit den Filterzeilen ein, z. B. Länge <= 40mm. Rechtsklick auf einen Treffer: ' +
    'in Solid Edge öffnen oder CAD-Katalog-Link öffnen.' + LineEnding + LineEnding +
    'BSU = Lieferant/Code#Version');
end;

procedure TMainForm.MnuAbout(Sender: TObject);
var
  F: TForm;
  B: TButton;
  Y: Integer;

  procedure Line(const ACaption: string; ASize, AHeight: Integer; ABold, AGray, AWrap: Boolean);
  var
    L: TLabel;
  begin
    L := TLabel.Create(F);
    L.Parent := F;
    L.AutoSize := False;
    L.SetBounds(24, Y, 412, AHeight);
    L.WordWrap := AWrap;
    L.Caption := ACaption;
    if ASize > 0 then L.Font.Size := ASize;
    if ABold then L.Font.Style := [fsBold];
    if AGray then L.Font.Color := clGrayText;
    Inc(Y, AHeight);
  end;

begin
  F := TForm.CreateNew(Self);
  try
    F.Caption := 'Über PLIB';
    F.BorderStyle := bsDialog;
    F.Position := poOwnerFormCenter;
    F.Width := 460;
    Y := 20;
    Line('PLIB Teilebibliothek', 16, 32, True, False, False);
    Line('Teilebibliothek nach ISO 13584 (PLIB)', 0, 22, False, False, False);
    Line('Version ' + AppVersion + '   (Build ' + {$I %DATE%} + ')', 0, 22, False, False, False);
    Inc(Y, 12);
    Line('Entwickelt von ' + AppAuthor, 0, 22, False, False, False);
    Inc(Y, 12);
    Line(AppCopyright + '. Alle Rechte vorbehalten.', 0, 22, False, False, False);
    Line('Das Programm wird ohne Gewähr bereitgestellt. Es verwendet Lazarus / Free Pascal, ' +
      'SQLite und PostgreSQL (Open Source).', 0, 40, False, True, True);
    Inc(Y, 8);
    Line('Datenbank: ' + DbDescription, 0, 40, False, True, True);
    B := TButton.Create(F);
    B.Parent := F;
    B.SetBounds(180, Y + 12, 100, 30);
    B.Caption := 'OK';
    B.Default := True;
    B.ModalResult := mrOk;
    F.ClientHeight := Y + 60;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TMainForm.MnuBackup(Sender: TObject);
var
  Src, Dst: TFileStream;
  DstName: string;
begin
  if PgNoFile then Exit;
  if DbCtx.Trans.Active then DbCtx.Trans.CommitRetaining;
  DstName := ExtractFilePath(DbCtx.Conn.DatabaseName) + BackupPrefix +
    FormatDateTime('yyyymmdd_hhnnss', Now) + '.sqlite3';
  Src := TFileStream.Create(DbCtx.Conn.DatabaseName, fmOpenRead or fmShareDenyNone);
  try
    Dst := TFileStream.Create(DstName, fmCreate);
    try
      Dst.CopyFrom(Src, 0);
    finally
      Dst.Free;
    end;
  finally
    Src.Free;
  end;
  ShowMessage('Sicherung gespeichert:' + LineEnding + DstName);
end;

{ ---------- Fensteraufteilung merken ---------- }

procedure TMainForm.LoadLayout;
var
  Ini: TIniFile;
  W, H, K: Integer;
begin
  Ini := TIniFile.Create(IniName);
  try
    W := Ini.ReadInteger('Layout', 'FormWidth', Width);
    H := Ini.ReadInteger('Layout', 'FormHeight', Height);
    if (W >= 700) and (H >= 400) then
    begin
      Width := W;
      Height := H;
    end;
    DockMgr.LoadFromIni(Ini, 'Dock');
    MnuToolbarItem.Checked := DockMgr.ToolbarVisible;
    if FRibbon <> nil then FRibbon.Visible := DockMgr.ToolbarVisible;
    FIrdi := Ini.ReadBool('Layout', 'Irdi', False);
    DbCtx.Lang := Ini.ReadString('Layout', 'Lang', '');
    MnuIrdiItem.Checked := FIrdi;
    FShowIds := Ini.ReadBool('Layout', 'ShowIds', True);
    FLastClass := StrToInt64Def(Ini.ReadString('Layout', 'LastClass', '0'), 0);
    CadRoot := Ini.ReadString('SolidEdge', 'Basisordner', '');
    DlDir := Ini.ReadString('SolidEdge', 'Downloadordner', '');
    SplitBar(Ini.ReadString('Spalten', 'Teile', ''), ColOrderParts);
    SplitBar(Ini.ReadString('Spalten', 'Werte', ''), ColOrderValues);
    if Ini.ValueExists('Spalten', 'TeileAus') then
      SplitBar(Ini.ReadString('Spalten', 'TeileAus', ''), ColHiddenParts);
    SplitBar(Ini.ReadString('Spalten', 'WerteAus', ''), ColHiddenValues);
    LoadColHidden(Ini);
    for K := 0 to 4 do
      PaneItems[K].Checked := DockMgr.PaneAt(K).State <> dsHidden;
    MnuShowIdsItem.Checked := FShowIds;
    if Ini.ReadBool('Layout', 'Maximized', False) then WindowState := wsMaximized;
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.SaveLayout;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(IniName);
    try
      if WindowState = wsNormal then
      begin
        Ini.WriteInteger('Layout', 'FormWidth', Width);
        Ini.WriteInteger('Layout', 'FormHeight', Height);
      end;
      Ini.WriteBool('Layout', 'Maximized', WindowState = wsMaximized);
      DockMgr.SaveToIni(Ini, 'Dock');
      Ini.WriteBool('Layout', 'Irdi', FIrdi);
      Ini.WriteBool('Layout', 'ShowIds', FShowIds);
      Ini.WriteString('Layout', 'LastClass', IntToStr(CurClass));
      Ini.WriteString('Spalten', 'Teile', JoinBar(ColOrderParts));
      Ini.WriteString('Spalten', 'Werte', JoinBar(ColOrderValues));
      Ini.WriteString('Spalten', 'TeileAus', JoinBar(ColHiddenParts));
      Ini.WriteString('Spalten', 'WerteAus', JoinBar(ColHiddenValues));
      SaveColHidden(Ini);
      Ini.WriteString('Layout', 'Lang', DbCtx.Lang);
    finally
      Ini.Free;
    end;
  except
    // Ordner nicht beschreibbar: Aufteilung wird dann nicht gespeichert
  end;
end;

procedure TMainForm.InitDb;
begin
  LoadDbSettings;
  if DbCtx.IsPg then
    DbCtx.Conn := NewPgConnection(Self, PgHost, PgPort, PgDb, PgUser, PgPass)
  else
  begin
    DbCtx.Conn := TSQLite3Connection.Create(Self);
    DbCtx.Conn.DatabaseName := ResolveDbPath;
  end;
  DbCtx.Trans := TSQLTransaction.Create(Self);
  DbCtx.Conn.Transaction := DbCtx.Trans;
  DbCtx.Trans.DataBase := DbCtx.Conn;
  DbCtx.Conn.Open;
  DbCtx.Trans.StartTransaction;
  CheckDatabase(FWasCrash);
  PrepareDatabase;
  TuneSqlite;

  QParts := TSQLQuery.Create(Self);
  QParts.DataBase := DbCtx.Conn;
  QParts.Transaction := DbCtx.Trans;

  QValues := TSQLQuery.Create(Self);
  QValues.DataBase := DbCtx.Conn;
  QValues.Transaction := DbCtx.Trans;
  UpdateDbInfo;
end;

{ SQLite-Einstellungen fuer mehr Tempo (bei PostgreSQL ohne Wirkung).
  Bewusst kein WAL-Modus: die Sicherungen kopieren die Datenbankdatei,
  im WAL-Modus koennten juengste Aenderungen in der -wal-Datei fehlen. }
procedure TMainForm.TuneSqlite;
begin
  if DbCtx.IsPg then Exit;
  try
    DbCtx.Conn.ExecuteDirect('PRAGMA cache_size=-32000');   // ca. 32 MB Seiten-Cache
    DbCtx.Conn.ExecuteDirect('PRAGMA temp_store=MEMORY');   // Sortieren/Zwischentabellen im RAM
  except
    // nicht kritisch
  end;
end;

procedure TMainForm.SeedIfEmpty;
var
  cNorm, cSchr, cSks, pMat, pDn, pLen, part: Int64;
begin
  if ScalarInt('SELECT COUNT(*) FROM class') > 0 then Exit;
  cNorm := AddClass('NT', 'Normteil', 0, 'Oberklasse fuer Normteile');
  cSchr := AddClass('SCHR', 'Schraube', cNorm, '');
  cSks := AddClass('SKS', 'Sechskantschraube', cSchr, '');
  pMat := EnsureProp('WERKSTOFF', 'Werkstoff', 'string', '');
  pDn := EnsureProp('DN', 'Nenndurchmesser', 'real', 'mm');
  pLen := EnsureProp('L', 'Laenge', 'real', 'mm');
  LinkProp(cNorm, pMat);   // wird an Schraube und Sechskantschraube vererbt
  LinkProp(cSchr, pDn);
  LinkProp(cSks, pLen);
  part := AddPart(cSks, 'SKS-M8x40', 'Sechskantschraube M8x40');
  SetValue(part, pMat, 'Stahl 8.8');
  SetValue(part, pDn, '8');
  SetValue(part, pLen, '40');
end;

{ ---------- Datenbank-Helfer ---------- }

function TMainForm.CurClass: Int64;
begin
  if Assigned(Tree.Selected) then
    Result := PtrInt(Tree.Selected.Data{%H-})
  else
    Result := 0;
end;

function TMainForm.AddClass(const ACode, AName: string; AParent: Int64;
  const ADef: string; const ANo: string): Int64;
var
  P, No: string;
begin
  if AParent = 0 then P := 'NULL' else P := IntToStr(AParent);
  No := ANo;
  if No = '' then No := NextClassNo(AParent);
  if No = '' then
    raise Exception.Create('Für die Klasse "' + AName + '" ist keine Klassennummer frei ' +
      '(höchstens 4 Ebenen AA.BB.CC.DD und je Ebene 99 Klassen).');
  Exec(Format('INSERT INTO class(code,name,parent_id,definition,supplier_id,class_no) ' +
    'VALUES(%s,%s,%s,%s,%d,%s)',
    [QuotedStr(ACode), QuotedStr(AName), P, QuotedStr(ADef), DefSupplier,
     QuotedStr(No)]));
  Result := ScalarInt(LastIdSql);
  Exec(Format('UPDATE class SET created=' + DateSql + ', modified=' + DateSql + ' WHERE id=%d',
    [Result]));
end;

function TMainForm.EnsureProp(const ACode, AName, ADataType, AUnit: string): Int64;
begin
  Result := ScalarInt('SELECT id FROM property WHERE code=' + QuotedStr(ACode));
  if Result = 0 then
  begin
    Exec(Format('INSERT INTO property(code,name,datatype,unit,supplier_id) VALUES(%s,%s,%s,%s,%d)',
      [QuotedStr(ACode), QuotedStr(AName), QuotedStr(ADataType), QuotedStr(AUnit),
       DefSupplier]));
    Result := ScalarInt(LastIdSql);
    Exec(Format('UPDATE property SET created=' + DateSql + ', modified=' + DateSql + ' WHERE id=%d',
      [Result]));
    SyncUnitId(Result);
  end;
end;

procedure TMainForm.LinkProp(AClass, AProp: Int64);
begin
  Exec(InsIgnoreSql('class_property', 'class_id,property_id',
    Format('%d,%d', [AClass, AProp])));
end;

{ Naechste freie Teilenummer: 7 Stellen, fortlaufend ab 1000001 (reine Hausnummer, keine
  sprechende Nummer; die Bedeutung steckt in der Klasse) }
function TMainForm.NextPartNo: string;
var
  M: Int64;
begin
  if DbCtx.IsPg then
    M := ScalarInt('SELECT COALESCE(MAX(CAST(part_number AS BIGINT)),0) FROM part ' +
      'WHERE part_number ~ ''^[0-9]{7}$''')
  else
    M := ScalarInt('SELECT COALESCE(MAX(CAST(part_number AS INTEGER)),0) FROM part ' +
      'WHERE length(part_number)=7 AND part_number NOT GLOB ''*[^0-9]*''');
  if M < 1000000 then M := 1000000;
  Inc(M);
  if M > 9999999 then
    raise Exception.Create('Der siebenstellige Nummernbereich ist aufgebraucht.');
  Result := IntToStr(M);
end;

{ Gibt es die Nummer schon, als Teilenummer oder als fruehere Nummer? }
function TMainForm.PartNoTaken(const ANo: string): Boolean;
begin
  Result := ScalarInt('SELECT COUNT(*) FROM part WHERE part_number=' + QuotedStr(ANo) +
    ' OR alt_nr=' + QuotedStr(ANo)) > 0;
end;

{ Dateiname (ohne Endung) fuer erzeugte oder heruntergeladene CAD-Dateien:
  "Beschreibung #Teilenummer", z. B. "Sechskantschraube ISO 4017 M3x10 8.8 #1000001" }
function TMainForm.CadFileBase(APart: Int64): string;
var
  Desc, No: string;
begin
  No := Trim(RowStr('part', 'part_number', APart));
  Desc := Trim(RowStr('part', 'description', APart));
  if Length(Desc) > 120 then Desc := Trim(Copy(Desc, 1, 120));   // Windows-Pfadlaenge
  if Desc = '' then
    Result := SafeFileName(No)
  else
    Result := SafeFileName(Desc + ' #' + No);
end;

{ Legt ein Teil an. Die Teilenummer vergibt PLIB selbst; eine uebergebene Nummer
  (Import, Musterdaten) wird nur als fruehere Nummer gemerkt. }
function TMainForm.AddPart(AClass: Int64; const APartNo, ADesc: string): Int64;
var
  Alt: string;
begin
  Alt := Trim(APartNo);
  Exec(Format('INSERT INTO part(class_id,part_number,alt_nr,description,supplier_id) ' +
    'VALUES(%d,%s,%s,%s,%d)',
    [AClass, QuotedStr(NextPartNo), QuotedStr(Alt), QuotedStr(ADesc), DefSupplier]));
  Result := ScalarInt(LastIdSql);
end;

{ Stellt alte (nicht siebenstellige) Teilenummern auf das neue Schema um }
procedure TMainForm.MnuRenumber(Sender: TObject);
var
  Q: TSQLQuery;
  Ids: array of Int64;
  I, N: Integer;
  Legacy: string;
  M: Int64;
  OldBatch: Boolean;
begin
  if DbCtx.IsPg then
    Legacy := 'part_number !~ ''^[0-9]{7}$'''
  else
    Legacy := '(length(part_number)<>7 OR part_number GLOB ''*[^0-9]*'')';
  N := Integer(ScalarInt('SELECT COUNT(*) FROM part WHERE ' + Legacy));
  if N = 0 then
  begin
    ShowMessage('Alle Teile haben schon siebenstellige Nummern.');
    Exit;
  end;
  if MessageDlg('Teilenummern umstellen',
    IntToStr(N) + ' Teil(e) haben noch eine alte Teilenummer. Sie bekommen jetzt fortlaufende ' +
    'siebenstellige Nummern. Die alte Nummer bleibt nur intern erhalten (für die Doppelprüfung ' +
    'beim Import) und wird nicht mehr angezeigt.' + LineEnding + LineEnding +
    'Bereits zugeordnete CAD-Dateien bleiben zugeordnet; neu erzeugte Dateien heißen nach der ' +
    'neuen Nummer.' + LineEnding + LineEnding +
    'Bitte vorher eine Sicherung der Datenbank anlegen (Datei, Datenbank sichern). Jetzt umstellen?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Ids := nil;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT id FROM part WHERE ' + Legacy + ' ORDER BY id';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(Ids, Length(Ids) + 1);
      Ids[High(Ids)] := Q.Fields[0].AsLargeInt;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  OldBatch := DbCtx.Batch;
  DbCtx.Batch := True;
  try
    try
      M := StrToInt64(NextPartNo);
      for I := 0 to High(Ids) do
      begin
        if M > 9999999 then
          raise Exception.Create('Der siebenstellige Nummernbereich ist aufgebraucht.');
        Exec(Format('UPDATE part SET alt_nr=CASE WHEN COALESCE(alt_nr,%s)=%s THEN part_number ' +
          'ELSE alt_nr END, part_number=%s WHERE id=%d',
          [QuotedStr(''), QuotedStr(''), QuotedStr(IntToStr(M)), Ids[I]]));
        Inc(M);
      end;
      DbCtx.Trans.CommitRetaining;
    except
      DbCtx.Trans.RollbackRetaining;
      raise;
    end;
  finally
    DbCtx.Batch := OldBatch;
  end;
  LoadParts;
  ShowStatus(IntToStr(Length(Ids)) + ' Teilenummer(n) umgestellt.');
  ShowMessage(IntToStr(Length(Ids)) + ' Teilenummer(n) wurden umgestellt.');
end;

procedure TMainForm.SetValue(APart, AProp: Int64; const AValue: string);
begin
  if DbCtx.IsPg then
    Exec(Format('INSERT INTO part_value(part_id,property_id,value) VALUES(%d,%d,%s) ' +
      'ON CONFLICT (part_id,property_id) DO UPDATE SET value=EXCLUDED.value',
      [APart, AProp, QuotedStr(AValue)]))
  else
    Exec(Format('INSERT OR REPLACE INTO part_value(part_id,property_id,value) ' +
      'VALUES(%d,%d,%s)', [APart, AProp, QuotedStr(AValue)]));
end;

{ Eigenschaften der Klasse selbst und aller Oberklassen (Vererbung) }
function TMainForm.ApplicableProps(AClass: Int64): TPropDefs;
var
  Q: TSQLQuery;
  n: Integer;
begin
  Result := nil;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text :=
      'WITH RECURSIVE anc(id) AS (' +
      ' SELECT id FROM class WHERE id=' + IntToStr(AClass) +
      ' UNION ALL SELECT c.parent_id FROM class c JOIN anc a ON c.id=a.id' +
      ' WHERE c.parent_id IS NOT NULL) ' +
      'SELECT DISTINCT p.id, ' + NameSql('property', 'p.id', 'p.name') +
      ', p.unit, p.datatype, p.code, ' +
      '(SELECT COUNT(*) FROM class_property x WHERE x.class_id=' + IntToStr(AClass) +
      ' AND x.property_id=p.id), ' + IdSql('p') + ', p.status ' +
      'FROM property p LEFT JOIN supplier s ON s.id=p.supplier_id ' +
      'JOIN class_property cp ON cp.property_id=p.id ' +
      'WHERE cp.class_id IN (SELECT id FROM anc) ORDER BY 2';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(Result, n + 1);
      Result[n].Id := Q.Fields[0].AsLargeInt;
      Result[n].Name := FieldText(Q.Fields[1]);
      Result[n].UnitName := FieldText(Q.Fields[2]);
      Result[n].DataType := FieldText(Q.Fields[3]);
      Result[n].Code := FieldText(Q.Fields[4]);
      Result[n].Direct := Q.Fields[5].AsInteger > 0;
      Result[n].Bsu := FieldText(Q.Fields[6]);
      Result[n].Status := FieldText(Q.Fields[7]);
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TMainForm.AskValue(const P: TPropDef; var V: string): Boolean;
var
  Prompt: string;
  OK: Boolean;
  I: Int64;
  D: Double;
  Items, Codes: TStringList;
  Qe: TSQLQuery;
  Idx, Def: Integer;
begin
  Prompt := P.Name;
  if P.UnitName <> '' then Prompt := Prompt + ' [' + P.UnitName + ']';
  Prompt := Prompt + ' (' + P.DataType + ')';
  if P.DataType = 'enum' then
  begin
    Items := TStringList.Create;
    Codes := TStringList.Create;
    Qe := TSQLQuery.Create(nil);
    try
      Qe.DataBase := DbCtx.Conn;
      Qe.Transaction := DbCtx.Trans;
      Qe.SQL.Text := 'SELECT e.code, ' + NameSql('enum', 'e.id', 'e.name') +
        ' FROM enum_value e WHERE e.property_id=' + IntToStr(P.Id) + ' ORDER BY e.code';
      Qe.Open;
      Items.Add('(kein Wert)');
      Codes.Add('');
      while not Qe.EOF do
      begin
        Codes.Add(FieldText(Qe.Fields[0]));
        Items.Add(Codes[Codes.Count - 1] + ' - ' + FieldText(Qe.Fields[1]));
        Qe.Next;
      end;
      Qe.Close;
      if Codes.Count = 1 then
      begin
        ShowMessage('Fuer dieses Merkmal sind noch keine Aufzaehlungswerte angelegt ' +
          '(Merkmale verwalten, Button Aufzaehlung).');
        Result := False;
        Exit;
      end;
      Def := Codes.IndexOf(V);
      if Def < 0 then Def := 0;
      Idx := PickIndex('Wert waehlen', Prompt, Items, Def);
      Result := Idx >= 0;
      if Result then V := Codes[Idx];
    finally
      Qe.Free;
      Items.Free;
      Codes.Free;
    end;
    Exit;
  end;
  repeat
    Result := InputQuery('Wert eingeben', Prompt, V);
    if not Result then Exit;
    V := Trim(V);
    OK := True;
    if V <> '' then
    begin
      if P.DataType = 'integer' then
        OK := TryStrToInt64(V, I)
      else if P.DataType = 'real' then
        OK := TryStrToFloat(V, D)
      else if P.DataType = 'boolean' then
        OK := Pos('|' + LowerCase(V) + '|', '|0|1|ja|nein|true|false|') > 0;
    end;
    if not OK then ShowMessage('Ungueltiger Wert fuer Datentyp ' + P.DataType);
  until OK;
end;

procedure TMainForm.UnlinkProp(AClass, AProp: Int64; AKeepProp: Boolean);
var
  Q: TSQLQuery;
  PartIds, ClassIds: array of Int64;
  n, i, j: Integer;
  Props: TPropDefs;
  Found: Boolean;
begin
  Exec(Format('DELETE FROM class_property WHERE class_id=%d AND property_id=%d',
    [AClass, AProp]));

  // Werte entfernen, die nach dem Entfernen nicht mehr anwendbar sind
  PartIds := nil;
  ClassIds := nil;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT pv.part_id, pt.class_id FROM part_value pv ' +
      'JOIN part pt ON pt.id=pv.part_id WHERE pv.property_id=' + IntToStr(AProp);
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(PartIds, n + 1);
      SetLength(ClassIds, n + 1);
      PartIds[n] := Q.Fields[0].AsLargeInt;
      ClassIds[n] := Q.Fields[1].AsLargeInt;
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  for i := 0 to n - 1 do
  begin
    Props := ApplicableProps(ClassIds[i]);
    Found := False;
    for j := 0 to High(Props) do
      if Props[j].Id = AProp then Found := True;
    if not Found then
      Exec(Format('DELETE FROM part_value WHERE part_id=%d AND property_id=%d',
        [PartIds[i], AProp]));
  end;

  // Merkmal selbst loeschen, wenn keine Klasse es mehr verwendet
  if (not AKeepProp) and (ScalarInt('SELECT COUNT(*) FROM class_property WHERE property_id=' +
    IntToStr(AProp)) = 0) then
    Exec('DELETE FROM property WHERE id=' + IntToStr(AProp));
end;

procedure TMainForm.DeleteProp(AProp: Int64);
begin
  Exec('DELETE FROM part_value WHERE property_id=' + IntToStr(AProp));
  Exec('DELETE FROM class_property WHERE property_id=' + IntToStr(AProp));
  Exec('DELETE FROM property WHERE id=' + IntToStr(AProp));
end;

{ Alle Merkmale des Katalogs, unabhaengig von Klassen }
function TMainForm.AllProps: TPropDefs;
var
  Q: TSQLQuery;
  n: Integer;
begin
  Result := nil;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text :=
      'SELECT p.id, ' + NameSql('property', 'p.id', 'p.name') +
      ', p.unit, p.datatype, p.code, ' +
      '(SELECT COUNT(*) FROM class_property x WHERE x.property_id=p.id), ' +
      IdSql('p') + ', p.status ' +
      'FROM property p LEFT JOIN supplier s ON s.id=p.supplier_id ORDER BY p.name';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(Result, n + 1);
      Result[n].Id := Q.Fields[0].AsLargeInt;
      Result[n].Name := FieldText(Q.Fields[1]);
      Result[n].UnitName := FieldText(Q.Fields[2]);
      Result[n].DataType := FieldText(Q.Fields[3]);
      Result[n].Code := FieldText(Q.Fields[4]);
      Result[n].UseCount := Q.Fields[5].AsInteger;
      Result[n].Bsu := FieldText(Q.Fields[6]);
      Result[n].Status := FieldText(Q.Fields[7]);
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

{ Fragt ein neues Merkmal ab. Ergebnis: Id des neuen (oder schon vorhandenen)
  Merkmals, 0 bei Abbruch. }
function TMainForm.AskNewProp(out AExisting: Boolean): Int64;
var
  Code, Nm, Dt, Un: string;
begin
  Result := 0;
  AExisting := False;
  Code := '';
  Nm := '';
  Dt := 'string';
  Un := '';
  if not InputQuery('Neues Merkmal', 'Code (z. B. DN):', Code) then Exit;
  Code := Trim(Code);
  if not ValidCode(Code) then
  begin
    ShowMessage('Ungueltiger Code (erlaubt: Buchstaben, Ziffern, - _ . ; maximal 40 Zeichen).');
    Exit;
  end;
  Result := ScalarInt('SELECT id FROM property WHERE code=' + QuotedStr(Code));
  if Result <> 0 then
  begin
    AExisting := True;
    Exit;
  end;
  if not InputQuery('Neues Merkmal', 'Name:', Nm) then Exit;
  Nm := Trim(Nm);
  if Nm = '' then Exit;
  if not InputQuery('Neues Merkmal',
    'Datentyp (string, integer, real, boolean, enum):', Dt) then Exit;
  Dt := LowerCase(Trim(Dt));
  if Pos('|' + Dt + '|', '|string|integer|real|boolean|enum|') = 0 then
  begin
    ShowMessage('Unbekannter Datentyp.');
    Exit;
  end;
  if not InputQuery('Neues Merkmal', 'Einheit (Code aus dem Einheitenverzeichnis, optional):', Un) then Exit;
  Result := EnsureProp(Code, Nm, Dt, Trim(Un));
  if Dt = 'enum' then ManageEnum(Result);
end;

{ Aendert Code, Name, Einheit (und Datentyp, solange keine Werte existieren) }
function TMainForm.EditPropDlg(const P: TPropDef): Boolean;
var
  Code, Nm, Un, Dt: string;
  Sup: Int64;
  Ver: Integer;
begin
  Result := False;
  Code := P.Code;
  Nm := RowStr('property', 'name', P.Id);
  Un := P.UnitName;
  Dt := P.DataType;
  if not InputQuery('Merkmal aendern', 'Code:', Code) then Exit;
  if not InputQuery('Merkmal aendern', 'Name:', Nm) then Exit;
  if not InputQuery('Merkmal aendern', 'Einheit (Code aus dem Einheitenverzeichnis):', Un) then Exit;
  if ScalarInt('SELECT COUNT(*) FROM part_value WHERE property_id=' +
    IntToStr(P.Id)) = 0 then
  begin
    if not InputQuery('Merkmal aendern',
      'Datentyp (string, integer, real, boolean, enum):', Dt) then Exit;
    Dt := LowerCase(Trim(Dt));
    if Pos('|' + Dt + '|', '|string|integer|real|boolean|enum|') = 0 then
    begin
      ShowMessage('Unbekannter Datentyp.');
      Exit;
    end;
  end;
  Code := Trim(Code);
  Nm := Trim(Nm);
  if (not ValidCode(Code)) or (Nm = '') then
  begin
    ShowMessage('Ungueltiger Code (erlaubt: Buchstaben, Ziffern, - _ . ; maximal 40 Zeichen) oder leerer Name.');
    Exit;
  end;
  if CodeTaken('property', Code, P.Id) then
  begin
    ShowMessage('Der Code "' + Code + '" ist schon vergeben.');
    Exit;
  end;
  Sup := ScalarInt('SELECT COALESCE(supplier_id,0) FROM property WHERE id=' + IntToStr(P.Id));
  if not AskSupplier('Merkmal aendern', Sup) then Exit;
  Ver := 0;
  if RowStr('property', 'status', P.Id) = 'freigegeben' then
  begin
    Ver := 1;
    ShowMessage('Das Merkmal ist freigegeben. Seine Version wird automatisch erhoeht.');
  end
  else if MessageDlg('Versionsnummer des Merkmals um 1 erhoehen?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then Ver := 1;
  Exec(Format('UPDATE property SET code=%s, name=%s, unit=%s, datatype=%s, ' +
    'supplier_id=%d, version=version+%d, modified=' + DateSql + ' WHERE id=%d',
    [QuotedStr(Code), QuotedStr(Nm), QuotedStr(Trim(Un)), QuotedStr(Dt), Sup, Ver, P.Id]));
  SyncUnitId(P.Id);
  Result := True;
end;

{ ---------- Anzeige ---------- }

procedure TMainForm.LoadTree(ASelect: Int64);
type
  TRow = record
    Id, Parent: Int64;
    Txt, Status: string;
    Kids: Integer;
    FirstChild, LastChild, Next: Integer;   // Verkettung der Kinder (Index, -1 = keins)
  end;
var
  Q: TSQLQuery;
  Rows: array of TRow;
  n, i, Pi, RootFirst, RootLast: Integer;
  SelId: Int64;
  SelNode: TTreeNode;
  IdPart: string;
  IdIdx: TStringList;

  procedure AddKids(ParentNode: TTreeNode; First: Integer);
  var
    i, Ic: Integer;
    N: TTreeNode;
  begin
    i := First;
    while i >= 0 do
    begin
      N := Tree.Items.AddChildObject(ParentNode, Rows[i].Txt,
        Pointer(PtrInt(Rows[i].Id)){%H-});
      Ic := StatusIndex(Rows[i].Status) + 3 * Ord(Rows[i].Kids > 0);
      N.ImageIndex := Ic;
      N.SelectedIndex := Ic;
      if Rows[i].Id = SelId then SelNode := N;
      AddKids(N, Rows[i].FirstChild);
      i := Rows[i].Next;
    end;
  end;

begin
  ClassCacheClear;   // Klassen koennen sich geaendert haben
  if ASelect <> 0 then SelId := ASelect else SelId := CurClass;
  SelNode := nil;
  Rows := nil;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    if FShowIds then
      IdPart := ' || ''   <'' || ' + IdSql('c') + ' || ''>'' '
    else
      IdPart := ' ';
    // Teile- und Unterklassen-Anzahl einmal gruppiert zaehlen statt je Klasse
    Q.SQL.Text := 'SELECT c.id, COALESCE(c.parent_id,0), COALESCE(c.class_no,'''') || ''  '' || ' +
      'c.code || '' - '' || ' +
      NameSql('class', 'c.id', 'c.name') +
      ' || CASE WHEN c.status=''veraltet'' THEN '' (veraltet)'' ELSE '''' END' +
      ' || CASE WHEN COALESCE(pc.n,0)>0 THEN ''  ('' || CAST(pc.n AS TEXT) || '')'' ELSE '''' END' +
      IdPart + ', c.status, COALESCE(kc.n,0) ' +
      'FROM class c LEFT JOIN supplier s ON s.id=c.supplier_id ' +
      'LEFT JOIN (SELECT class_id, COUNT(*) AS n FROM part GROUP BY class_id) pc ON pc.class_id=c.id ' +
      'LEFT JOIN (SELECT parent_id, COUNT(*) AS n FROM class WHERE parent_id IS NOT NULL ' +
      'GROUP BY parent_id) kc ON kc.parent_id=c.id ' +
      'ORDER BY c.class_no, c.name';
    Q.PacketRecords := -1;
    Q.Open;
    SetLength(Rows, 256);
    while not Q.EOF do
    begin
      if n > High(Rows) then SetLength(Rows, 2 * Length(Rows));
      Rows[n].Id := Q.Fields[0].AsLargeInt;
      Rows[n].Parent := Q.Fields[1].AsLargeInt;
      Rows[n].Txt := FieldText(Q.Fields[2]);
      Rows[n].Status := FieldText(Q.Fields[3]);
      Rows[n].Kids := Q.Fields[4].AsInteger;
      Rows[n].FirstChild := -1;
      Rows[n].LastChild := -1;
      Rows[n].Next := -1;
      Inc(n);
      Q.Next;
    end;
    SetLength(Rows, n);
    Q.Close;
  finally
    Q.Free;
  end;

  // Kinder einmal vorab zuordnen (Reihenfolge der Abfrage bleibt erhalten)
  RootFirst := -1;
  RootLast := -1;
  IdIdx := TStringList.Create;
  try
    for i := 0 to n - 1 do
      IdIdx.AddObject(IntToStr(Rows[i].Id), TObject(PtrInt(i)));
    IdIdx.Sorted := True;
    for i := 0 to n - 1 do
    begin
      if Rows[i].Parent = 0 then
      begin
        if RootLast < 0 then RootFirst := i else Rows[RootLast].Next := i;
        RootLast := i;
      end
      else if IdIdx.Find(IntToStr(Rows[i].Parent), Pi) then
      begin
        Pi := Integer(PtrInt(IdIdx.Objects[Pi]));
        if Rows[Pi].LastChild < 0 then Rows[Pi].FirstChild := i
        else Rows[Rows[Pi].LastChild].Next := i;
        Rows[Pi].LastChild := i;
      end;
      // Klassen mit unbekannter Oberklasse werden wie bisher nicht angezeigt
    end;
  finally
    IdIdx.Free;
  end;

  Tree.Items.BeginUpdate;
  try
    FHintNode := nil;
    Tree.Items.Clear;
    AddKids(nil, RootFirst);
    Tree.FullExpand;
  finally
    Tree.Items.EndUpdate;
  end;
  if (SelNode = nil) and (Tree.Items.Count > 0) then SelNode := Tree.Items[0];
  if Assigned(FTreeTimer) then FTreeTimer.Enabled := False;
  Tree.Selected := SelNode;
  LoadParts;
end;

procedure TMainForm.FillGrid(AGrid: TStringGrid; AQuery: TSQLQuery);
var
  c, r, Cap, Fc: Integer;
  Memo: array of Boolean;
begin
  AGrid.BeginUpdate;
  try
    Fc := AQuery.FieldCount;
    AGrid.RowCount := 1;
    AGrid.ColCount := Fc;
    SetLength(Memo, Fc);
    for c := 0 to Fc - 1 do
    begin
      AGrid.Cells[c, 0] := AQuery.Fields[c].FieldName;
      Memo[c] := AQuery.Fields[c].DataType in [ftMemo, ftWideMemo, ftFmtMemo, ftBlob];
    end;
    // Zeilen blockweise anlegen statt fuer jedes Teil einzeln
    Cap := 64;
    AGrid.RowCount := Cap + 1;
    r := 1;
    while not AQuery.EOF do
    begin
      if r > Cap then
      begin
        Cap := 2 * Cap;
        AGrid.RowCount := Cap + 1;
      end;
      for c := 0 to Fc - 1 do
        if Memo[c] then
          AGrid.Cells[c, r] := FieldText(AQuery.Fields[c])
        else if AQuery.Fields[c].IsNull then
          AGrid.Cells[c, r] := ''
        else
          AGrid.Cells[c, r] := AQuery.Fields[c].AsString;
      Inc(r);
      AQuery.Next;
    end;
    AGrid.RowCount := r;
    GridAutoSize(AGrid);
  finally
    AGrid.EndUpdate;
  end;
end;

{ Schnelle Spaltenbreite: misst nur Kopf und die ersten AutoSizeRows Zeilen
  (AutoSizeColumns misst jede Zelle und ist bei grossen Listen langsam) }
procedure TMainForm.GridAutoSize(AGrid: TStringGrid);
var
  c, r, W, Mx, Last: Integer;
  H: TStringList;
begin
  if not AGrid.HandleAllocated then
  begin
    AGrid.AutoSizeColumns;
    Exit;
  end;
  AGrid.Canvas.Font := AGrid.Font;
  Last := AGrid.RowCount - 1;
  if Last > AutoSizeRows then Last := AutoSizeRows;
  for c := 0 to AGrid.ColCount - 1 do
  begin
    Mx := 0;
    for r := 0 to Last do
    begin
      W := AGrid.Canvas.TextWidth(AGrid.Cells[c, r]);
      if W > Mx then Mx := W;
    end;
    Mx := Mx + (20 * Screen.PixelsPerInch) div 96;     // Rand links/rechts (eigene Zeichnung)
    if Mx < (30 * Screen.PixelsPerInch) div 96 then Mx := (30 * Screen.PixelsPerInch) div 96;
    if Mx > (600 * Screen.PixelsPerInch) div 96 then Mx := (600 * Screen.PixelsPerInch) div 96;
    AGrid.ColWidths[c] := Mx;
  end;
  // Die interne Nummer ("Nr") braucht PLIB zum Auffinden des Teils; der Benutzer sieht sie nicht
  if AGrid = GridParts then
  begin
    c := ColIdx(AGrid, 'Nr');
    if c >= 0 then AGrid.ColWidths[c] := 0;
    H := TStringList.Create;
    try
      PartsHiddenFor(CurClass, H);
      HideColsByName(AGrid, H);
    finally
      H.Free;
    end;
  end
  else if AGrid = GridValues then
    HideColsByName(AGrid, ColHiddenValues);
end;

function TMainForm.CurPart: Int64;
begin
  Result := 0;
  if (GridParts.RowCount > 1) and (GridParts.Row >= 1) then
    Result := StrToInt64Def(CellBy(GridParts, 'Nr', GridParts.Row), 0);
end;

procedure TMainForm.SelectPart(APart: Int64);
var
  r: Integer;
begin
  for r := 1 to GridParts.RowCount - 1 do
    if StrToInt64Def(CellBy(GridParts, 'Nr', r), 0) = APart then
    begin
      GridParts.Row := r;
      Break;
    end;
  LoadValues;
end;

{ Baut die Zusatzspalten der Teileliste: je ein Merkmal der gewaehlten Klasse
  (inkl. geerbter Merkmale und der Merkmale ihrer Unterklassen) }
function TMainForm.PartPropColumns(AClass: Int64): string;
var
  Q: TSQLQuery;
  Names: TStringList;
  Id, Title, Sub, Expr: string;
begin
  Result := '';
  Names := TStringList.Create;
  Q := TSQLQuery.Create(nil);
  try
    Names.Add('nr');
    Names.Add('teilenummer');
    Names.Add('beschreibung');
    Names.Add('klasse');
    Names.Add('klassennr');
    Names.Add('cad-datei');
    Names.Add('bsu');
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text :=
      // Spalten: nur Merkmale der gewaehlten Klasse und ihrer Oberklassen (nicht der Unterklassen)
      'WITH RECURSIVE anc(id) AS (SELECT id FROM class WHERE id=' + IntToStr(AClass) +
      ' UNION ALL SELECT c.parent_id FROM class c JOIN anc a ON c.id=a.id' +
      ' WHERE c.parent_id IS NOT NULL) ' +
      'SELECT DISTINCT p.id, ' + NameSql('property', 'p.id', 'p.name') +
      ', p.unit, p.datatype, p.code ' +
      'FROM property p JOIN class_property cp ON cp.property_id=p.id ' +
      'WHERE cp.class_id IN (SELECT id FROM anc) ' +
      'ORDER BY 2';
    Q.Open;
    while not Q.EOF do
    begin
      Id := IntToStr(Q.Fields[0].AsLargeInt);
      Title := FieldText(Q.Fields[1]);
      if FieldText(Q.Fields[2]) <> '' then
        Title := Title + ' [' + FieldText(Q.Fields[2]) + ']';
      Title := StringReplace(Title, '"', '''', [rfReplaceAll]);
      Title := StringReplace(Title, ':', ' ', [rfReplaceAll]);
      Title := StringReplace(Title, '?', ' ', [rfReplaceAll]);
      if Names.IndexOf(LowerCase(Title)) >= 0 then
        Title := Title + ' (' + FieldText(Q.Fields[4]) + ')';
      Names.Add(LowerCase(Title));
      Sub := '(SELECT pv.value FROM part_value pv WHERE pv.part_id=pt.id ' +
        'AND pv.property_id=' + Id + ')';
      if FieldText(Q.Fields[3]) = 'enum' then
        Expr := 'COALESCE((SELECT ' + NameSql('enum', 'e.id', 'e.name') +
          ' FROM enum_value e WHERE e.property_id=' + Id + ' AND e.code=' + Sub +
          '), ' + Sub + ')'
      else
        Expr := Sub;
      Result := Result + ', ' + Expr + ' AS "' + Title + '"';
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
    Names.Free;
  end;
end;

procedure TMainForm.LoadParts;
var
  r, Cnt: Integer;
begin
  FLoading := True;
  try
    if QParts.Active then QParts.Close;
    FPartsCapped := False;
    if CurClass = 0 then
    begin
      GridParts.RowCount := 1;
      Exit;
    end;
    QParts.SQL.Text :=
      'WITH RECURSIVE sub(id) AS (' +
      ' SELECT id FROM class WHERE id=:c' +
      ' UNION ALL SELECT c.id FROM class c JOIN sub s ON c.parent_id=s.id) ' +
      'SELECT pt.id AS "Nr", pt.part_number AS "Teilenummer", ' +
      'pt.description AS "Beschreibung", COALESCE(pt.manufacturer,'''') AS "Hersteller", ' +
      NameSql('class', 'c.id', 'c.name') +
      ' AS "Klasse", COALESCE(c.class_no,'''') AS "Klassennr", ' +
      'COALESCE(s.code,''?'') || ''/'' || pt.part_number AS "BSU", ' +
      'COALESCE(pt.cad_path,'''') AS "CAD-Datei" ' +
      PartPropColumns(CurClass) + ' ' +
      'FROM part pt JOIN class c ON c.id=pt.class_id ' +
      'LEFT JOIN supplier s ON s.id=pt.supplier_id ' +
      'WHERE pt.class_id IN (SELECT id FROM sub) ORDER BY pt.part_number ' +
      'LIMIT ' + IntToStr(MaxPartRows + 1);
    QParts.ParamByName('c').AsLargeInt := CurClass;
    QParts.Open;
    FillGrid(GridParts, QParts);
    QParts.Close;
    // Mehr als MaxPartRows: letzte (Pruef-)Zeile entfernen und Hinweis geben
    FPartsCapped := GridParts.RowCount - 1 > MaxPartRows;
    if FPartsCapped then
    begin
      GridParts.RowCount := MaxPartRows + 1;
      ShowStatus(Format('Nur die ersten %d Teile angezeigt - Unterklasse wählen ' +
        'oder Teilesuche benutzen.', [MaxPartRows]));
    end;
    // CAD-Spalte: nur den Dateinamen zeigen
    r := ColIdx(GridParts, 'CAD-Datei');
    if r >= 0 then
    begin
      for Cnt := 1 to GridParts.RowCount - 1 do
        GridParts.Cells[r, Cnt] := ExtractFileName(GridParts.Cells[r, Cnt]);
      GridAutoSize(GridParts);
    end;
    ApplyColOrder(GridParts, ColOrderParts);
    ApplyPartSort;
    if GridParts.RowCount > 1 then GridParts.Row := 1;
  finally
    FLoading := False;
    LoadValues;
    UpdateStatus;
  end;
end;

procedure TMainForm.LoadValues;
var
  Pid: Int64;
begin
  if QValues.Active then QValues.Close;
  Pid := CurPart;
  if Pid = 0 then
  begin
    GridValues.RowCount := 1;
    Exit;
  end;
  QValues.SQL.Text :=
    'SELECT ' + NameSql('property', 'p.id', 'p.name') + ' AS "Eigenschaft", p.code AS "Code", ' +
    'CASE WHEN p.datatype=''enum'' THEN COALESCE((SELECT ' +
    NameSql('enum', 'e.id', 'e.name') +
    ' FROM enum_value e WHERE e.property_id=p.id AND e.code=pv.value), pv.value) ' +
    'ELSE pv.value END AS "Wert", ' +
    'p.unit AS "Einheit" FROM part_value pv ' +
    'JOIN property p ON p.id=pv.property_id WHERE pv.part_id=:pid ' +
    'ORDER BY p.name';
  QValues.ParamByName('pid').AsLargeInt := Pid;
  QValues.Open;
  FillGrid(GridValues, QValues);
  QValues.Close;
  ApplyColOrder(GridValues, ColOrderValues);
end;

procedure TMainForm.TreeChange(Sender: TObject; Node: TTreeNode);
begin
  // Beim Blaettern mit Pfeiltasten erst laden, wenn man kurz stehen bleibt
  if GetTickCount64 - FTreeKeyTick < 100 then
  begin
    if FTreeTimer = nil then
    begin
      FTreeTimer := TTimer.Create(Self);
      FTreeTimer.Enabled := False;
      FTreeTimer.Interval := TreeDelayMs;
      FTreeTimer.OnTimer := @TreeTimerFire;
    end;
    FTreeTimer.Enabled := False;   // neu starten
    FTreeTimer.Enabled := True;
    Exit;
  end;
  if Assigned(FTreeTimer) then FTreeTimer.Enabled := False;
  LoadParts;
  UpdateClassImage;
end;

procedure TMainForm.TreeTimerFire(Sender: TObject);
begin
  FTreeTimer.Enabled := False;
  LoadParts;
  UpdateClassImage;
end;

procedure TMainForm.PartsSelect(Sender: TObject; aCol, aRow: Integer);
begin
  if not FLoading then
  begin
    LoadValues;
    UpdateStatus;
  end;
end;

{ ---------- Aktionen ---------- }

procedure TMainForm.BtnNewClass(Sender: TObject);
var
  Cap: string;
  V: TStrArr;
  NewId: Int64;
begin
  if Assigned(Tree.Selected) then
    Cap := 'Neue Unterklasse von ' + Tree.Selected.Text
  else
    Cap := 'Neue Hauptklasse';
  SetLength(V, 3);
  V[0] := SuggestClassCode(CurClass);
  V[1] := SuggestClassName(CurClass);
  V[2] := NextClassNo(CurClass);
  if V[2] = '' then
  begin
    if (CurClass <> 0) and (ClassNoLevel(RowStr('class', 'class_no', CurClass)) >= 4) then
      ShowMessage('Die gewählte Klasse liegt schon auf der 4. Ebene (Detailklasse). ' +
        'Darunter sind keine weiteren Unterklassen möglich.')
    else
      ShowMessage('Unter dieser Klasse ist keine Klassennummer mehr frei (je Ebene 99).');
    Exit;
  end;
  if not EditFieldsEx(Cap,
    ['Code (Vorschlag, änderbar):', 'Name (Vorschlag, änderbar):',
     'Klassennummer AA.BB.CC.DD (Vorschlag):'],
    ['text', 'text', 'text'], V, 1) then Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  V[2] := Trim(V[2]);
  if (not ValidCode(V[0])) or (V[1] = '') then
  begin
    ShowMessage('Ungueltiger Code (erlaubt: Buchstaben, Ziffern, - _ . ; maximal 40 Zeichen) oder leerer Name.');
    Exit;
  end;
  if not CheckClassNo(V[2], CurClass, 0, Cap) then
  begin
    ShowMessage(Cap);
    Exit;
  end;
  if CodeTaken('class', V[0], 0) then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist schon vergeben.');
    Exit;
  end;
  NewId := AddClass(V[0], V[1], CurClass, '', V[2]);
  LoadTree(NewId);
  ShowStatus('Klasse "' + V[1] + '" angelegt.');
end;

procedure TMainForm.BtnRenameClass(Sender: TObject);
var
  Cid, Sup: Int64;
  Ver, Lv: Integer;
  Code, Nm, CNo, OldNo, Msg: string;
  V: TStrArr;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  Code := ScalarStr('SELECT code FROM class WHERE id=' + IntToStr(Cid));
  Nm := ScalarStr('SELECT name FROM class WHERE id=' + IntToStr(Cid));
  SetLength(V, 3);
  V[0] := Code;
  V[1] := Nm;
  V[2] := RowStr('class', 'class_no', Cid);
  if not EditFields('Klasse umbenennen',
    ['Code:', 'Name:', 'Klassennummer AA.BB.CC.DD:'],
    ['text', 'text', 'text'], V) then Exit;
  Code := V[0];
  Nm := V[1];
  CNo := Trim(V[2]);
  Code := Trim(Code);
  Nm := Trim(Nm);
  if (not ValidCode(Code)) or (Nm = '') then
  begin
    ShowMessage('Ungueltiger Code (erlaubt: Buchstaben, Ziffern, - _ . ; maximal 40 Zeichen) oder leerer Name.');
    Exit;
  end;
  OldNo := RowStr('class', 'class_no', Cid);
  if (CNo <> OldNo) and not CheckClassNo(CNo,
    ScalarInt('SELECT COALESCE(parent_id,0) FROM class WHERE id=' + IntToStr(Cid)), Cid, Msg) then
  begin
    ShowMessage(Msg);
    Exit;
  end;
  if CodeTaken('class', Code, Cid) then
  begin
    ShowMessage('Der Code "' + Code + '" ist schon vergeben.');
    Exit;
  end;
  Sup := ScalarInt('SELECT COALESCE(supplier_id,0) FROM class WHERE id=' + IntToStr(Cid));
  if not AskSupplier('Klasse umbenennen', Sup) then Exit;
  Ver := 0;
  if RowStr('class', 'status', Cid) = 'freigegeben' then
  begin
    Ver := 1;
    ShowMessage('Die Klasse ist freigegeben. Ihre Version wird automatisch erhoeht.');
  end
  else if MessageDlg('Versionsnummer der Klasse um 1 erhoehen?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then Ver := 1;
  Exec(Format('UPDATE class SET code=%s, name=%s, class_no=%s, supplier_id=%d, ' +
    'version=version+%d, modified=' + DateSql + ' WHERE id=%d',
    [QuotedStr(Code), QuotedStr(Nm), QuotedStr(CNo), Sup, Ver, Cid]));
  // Unterklassen bekommen den neuen Nummernanfang
  if (CNo <> OldNo) and ValidClassNo(OldNo) then
  begin
    Lv := ClassNoLevel(CNo);
    Exec('WITH RECURSIVE sub(id) AS (SELECT id FROM class WHERE parent_id=' + IntToStr(Cid) +
      ' UNION ALL SELECT c.id FROM class c JOIN sub s ON c.parent_id=s.id) ' +
      'UPDATE class SET class_no=' + QuotedStr(Copy(CNo, 1, Lv * 3 - 1)) +
      ' || SUBSTR(class_no, ' + IntToStr(Lv * 3) + ') WHERE id IN (SELECT id FROM sub)');
  end;
  LoadTree(Cid);
end;

{ ---------- Dialog: Merkmale verwalten ---------- }

procedure TMainForm.BtnManageProps(Sender: TObject);
var
  F: TForm;
  PB, PRight, PFilter: TPanel;
  InfoLbl: TLabel;
  LblF: TLabel;
  Spl: TSplitter;

begin
  DlgClass := CurClass;
  if DlgClass = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  F := TForm.CreateNew(Self);
  try
    F.Caption := 'Merkmale von ' + Tree.Selected.Text;
    F.Position := poScreenCenter;
    F.Width := 1180;
    F.Height := 520;
    RememberDialog(F, 'MerkmaleKlasse');

    PB := DlgToolbar(F);
    DlgTB(PB, 21, 'Neues Merkmal' + LineEnding + 'Legt ein neues Merkmal an und ordnet es dieser Klasse zu', @DlgNew);
    DlgTB(PB, 22, 'Merkmal ändern' + LineEnding + 'Wirkt in allen Klassen, die das Merkmal nutzen', @DlgEdit);
    DlgTB(PB, 23, 'Merkmal ganz löschen' + LineEnding + 'Nur wenn es sonst nirgends benutzt wird', @DlgDel);
    DlgTBSep(PB);
    DlgTB(PB, 24, 'Ausgewählte Katalog-Merkmale dieser Klasse zuordnen' + LineEnding +
      'Alternativ aus dem Katalog nach links ziehen', @DrLink);
    DlgTB(PB, 25, 'Ausgewählte Merkmale aus dieser Klasse entfernen' + LineEnding +
      'Das Merkmal bleibt im Katalog erhalten; alternativ nach rechts ziehen', @DrUnlink);
    DlgTBSep(PB);
    DlgTB(PB, 10, 'Beschreibung / Status', @DlgDesc);
    DlgTB(PB, 11, 'Übersetzung', @DlgTrans);
    DlgTB(PB, 26, 'Aufzählungswerte', @DlgEnum);
    DlgTBClose(PB);

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 60;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.Caption := 'Zuordnen: Merkmale aus dem Katalog (rechts) in die linke Liste ziehen, ' +
      'Doppelklick oder Symbolleiste. Entfernen: nach rechts ziehen (nur direkt zugeordnete, ' +
      'nicht geerbte Merkmale). Mehrere mit Strg oder Umschalt wählen. ' +
      'Ändern wirkt in allen Klassen, die das Merkmal nutzen.';
    InfoLbl.WordWrap := True;

    DlgList := TListBox.Create(F);
    DlgList.Parent := F;
    DlgList.Align := alLeft;
    DlgList.Width := 500;
    DlgList.MultiSelect := True;
    DlgList.ExtendedSelect := True;
    DlgList.DragMode := dmAutomatic;
    DlgList.OnDragOver := @DrOverOwn;
    DlgList.OnDragDrop := @DrDropOwn;
    MakeDlgPopup(DlgList);

    Spl := TSplitter.Create(F);
    Spl.Parent := F;
    Spl.Align := alLeft;
    Spl.Left := 505;

    PRight := TPanel.Create(F);
    PRight.Parent := F;
    PRight.Align := alClient;
    PRight.BevelOuter := bvNone;
    PRight.Caption := '';
    PFilter := TPanel.Create(F);
    PFilter.Parent := PRight;
    PFilter.Align := alTop;
    PFilter.Height := 58;
    PFilter.BevelOuter := bvNone;
    PFilter.Caption := '';
    LblF := TLabel.Create(F);
    LblF.Parent := PFilter;
    LblF.SetBounds(4, 4, 380, 20);
    LblF.AutoSize := False;
    LblF.Caption := 'Merkmalkatalog (noch nicht zugeordnet) - Filter:';
    LblF.Font.Style := [fsBold];
    DrFilter := TEdit.Create(F);
    DrFilter.Parent := PFilter;
    DrFilter.SetBounds(4, 26, 300, 26);
    DrFilter.OnChange := @DrFilterChange;
    DrCat := TListBox.Create(F);
    DrCat.Parent := PRight;
    DrCat.Align := alClient;
    DrCat.MultiSelect := True;
    DrCat.ExtendedSelect := True;
    DrCat.DragMode := dmAutomatic;
    DrCat.OnDragOver := @DrOverCat;
    DrCat.OnDragDrop := @DrDropCat;
    DrCat.OnDblClick := @DrLink;
    DlgRefresh;
    F.ShowModal;
  finally
    DlgList := nil;
    DrCat := nil;
    DrFilter := nil;
    F.Free;
  end;
  LoadParts;   // Spalten der Teileliste neu aufbauen (Merkmale koennen sich geaendert haben)
end;

{ ---------- Merkmale per Drag and Drop einer Klasse zuordnen ---------- }

{ Fuellt die Katalogliste rechts: alle Merkmale, die der Klasse noch nicht zugeordnet sind }
procedure TMainForm.DrRefresh;
var
  Q: TSQLQuery;
  Used, Flt, S: string;
  I, N: Integer;
begin
  if DrCat = nil then Exit;
  Used := '0';
  for I := 0 to High(DlgProps) do Used := Used + ',' + IntToStr(DlgProps[I].Id);
  Flt := LowerCase(Trim(DrFilter.Text));
  DrIds := nil;
  Q := TSQLQuery.Create(nil);
  DrCat.Items.BeginUpdate;
  try
    DrCat.Items.Clear;
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT p.id, ' + NameSql('property', 'p.id', 'p.name') +
      ', p.unit, p.datatype, p.code FROM property p WHERE p.id NOT IN (' + Used +
      ') ORDER BY 2';
    Q.Open;
    while not Q.EOF do
    begin
      S := FieldText(Q.Fields[1]);
      if FieldText(Q.Fields[2]) <> '' then S := S + ' [' + FieldText(Q.Fields[2]) + ']';
      S := S + ' - ' + FieldText(Q.Fields[3]) + ' <' + FieldText(Q.Fields[4]) + '>';
      if (Flt = '') or (Pos(Flt, LowerCase(S)) > 0) then
      begin
        N := Length(DrIds);
        SetLength(DrIds, N + 1);
        DrIds[N] := Q.Fields[0].AsLargeInt;
        DrCat.Items.Add(S);
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
    DrCat.Items.EndUpdate;
  end;
end;

procedure TMainForm.DrFilterChange(Sender: TObject);
begin
  DrRefresh;
end;

{ Ausgewaehlte Katalog-Merkmale der Klasse zuordnen }
procedure TMainForm.DrLink(Sender: TObject);
var
  I, N: Integer;
  Ids: array of Int64;
begin
  if DrCat = nil then Exit;
  Ids := nil;
  N := 0;
  for I := 0 to DrCat.Items.Count - 1 do
    if DrCat.Selected[I] then
    begin
      SetLength(Ids, N + 1);
      Ids[N] := DrIds[I];
      Inc(N);
    end;
  if N = 0 then
  begin
    ShowMessage('Bitte rechts im Katalog ein oder mehrere Merkmale auswählen ' +
      '(Strg oder Umschalt für mehrere) und nach links ziehen.');
    Exit;
  end;
  for I := 0 to N - 1 do LinkProp(DlgClass, Ids[I]);
  DlgRefresh;
  ShowStatus(IntToStr(N) + ' Merkmal(e) zugeordnet.');
end;

{ Ausgewaehlte Merkmale aus der Klasse entfernen (bleiben im Katalog erhalten) }
procedure TMainForm.DrUnlink(Sender: TObject);
var
  I, N, Skipped: Integer;
  Ids: array of Int64;
begin
  Ids := nil;
  N := 0;
  Skipped := 0;
  for I := 0 to DlgList.Items.Count - 1 do
    if DlgList.Selected[I] and (I <= High(DlgProps)) then
    begin
      if DlgProps[I].Direct then
      begin
        SetLength(Ids, N + 1);
        Ids[N] := DlgProps[I].Id;
        Inc(N);
      end
      else
        Inc(Skipped);
    end;
  if N = 0 then
  begin
    if Skipped > 0 then
      ShowMessage('Die gewählten Merkmale werden von einer Oberklasse geerbt. ' +
        'Bitte dort entfernen.')
    else
      ShowMessage('Bitte links ein oder mehrere Merkmale auswählen und nach rechts ziehen.');
    Exit;
  end;
  if MessageDlg(IntToStr(N) + ' Merkmal(e) aus dieser Klasse entfernen?' + LineEnding + LineEnding +
    'Die Werte dieser Merkmale bei den Teilen der Klasse gehen verloren. ' +
    'Die Merkmale bleiben im Merkmalkatalog erhalten.' +
    LineEnding + LineEnding + 'Zum Rückgängig machen die Merkmale wieder nach links ' +
    'ziehen; die Werte müssen dann neu eingegeben werden.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  for I := 0 to N - 1 do UnlinkProp(DlgClass, Ids[I], True);
  DlgRefresh;
  if Skipped > 0 then
    ShowStatus(IntToStr(N) + ' Merkmal(e) entfernt, ' + IntToStr(Skipped) + ' geerbte übersprungen.')
  else
    ShowStatus(IntToStr(N) + ' Merkmal(e) entfernt.');
end;

procedure TMainForm.DrOverOwn(Sender, Source: TObject; X, Y: Integer; State: TDragState;
  var Accept: Boolean);
begin
  Accept := Source = DrCat;
end;

procedure TMainForm.DrOverCat(Sender, Source: TObject; X, Y: Integer; State: TDragState;
  var Accept: Boolean);
begin
  Accept := Source = DlgList;
end;

procedure TMainForm.DrDropOwn(Sender, Source: TObject; X, Y: Integer);
begin
  if Source = DrCat then DrLink(nil);
end;

procedure TMainForm.DrDropCat(Sender, Source: TObject; X, Y: Integer);
begin
  if Source = DlgList then DrUnlink(nil);
end;

procedure TMainForm.DlgRefresh;
var
  i, Sel: Integer;
  S: string;
begin
  if DlgList = nil then Exit;
  Sel := DlgList.ItemIndex;
  DlgProps := ApplicableProps(DlgClass);
  DlgList.Items.BeginUpdate;
  try
    DlgList.Items.Clear;
    for i := 0 to High(DlgProps) do
    begin
      S := DlgProps[i].Name;
      if DlgProps[i].UnitName <> '' then S := S + ' [' + DlgProps[i].UnitName + ']';
      S := S + ' - ' + DlgProps[i].DataType + ' <' + DlgProps[i].Bsu + '>';
      if DlgProps[i].Status = 'veraltet' then S := S + ' (veraltet)';
      if not DlgProps[i].Direct then S := S + ' - geerbt';
      DlgList.Items.Add(S);
    end;
  finally
    DlgList.Items.EndUpdate;
  end;
  if Sel >= DlgList.Items.Count then Sel := DlgList.Items.Count - 1;
  if (Sel < 0) and (DlgList.Items.Count > 0) then Sel := 0;
  DlgList.ItemIndex := Sel;
  DrRefresh;
end;

procedure TMainForm.DlgNew(Sender: TObject);
var
  Pid: Int64;
  Existing: Boolean;
begin
  Pid := AskNewProp(Existing);
  if Pid = 0 then Exit;
  LinkProp(DlgClass, Pid);
  if Existing then
    ShowMessage('Merkmal existiert bereits und wurde dieser Klasse zugeordnet.');
  DlgRefresh;
end;

procedure TMainForm.DlgEdit(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := DlgList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  if EditPropDlg(DlgProps[Idx]) then DlgRefresh;
end;

procedure TMainForm.DlgDel(Sender: TObject);
var
  Idx, Cnt: Integer;
  PId: Int64;
  PName, Msg: string;
  Q: TSQLQuery;
begin
  Idx := DlgList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  if not DlgProps[Idx].Direct then
  begin
    ShowMessage('Dieses Merkmal wird von einer Oberklasse geerbt. ' +
      'Bitte dort entfernen.');
    Exit;
  end;
  if MessageDlg('Merkmal "' + DlgProps[Idx].Name + '" aus dieser Klasse entfernen? ' +
    'Die zugehoerigen Werte der Teile gehen verloren.', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  PId := DlgProps[Idx].Id;
  PName := DlgProps[Idx].Name;
  UnlinkProp(DlgClass, PId);
  DlgRefresh;
  // Bleibt das Merkmal ueber eine Ober- oder Unterklasse sichtbar? Dann kurz erklaeren, warum.
  Msg := '';
  Cnt := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text :=
      'WITH RECURSIVE sub(id) AS (SELECT id FROM class WHERE id=' + IntToStr(DlgClass) +
      ' UNION ALL SELECT c.id FROM class c JOIN sub s ON c.parent_id=s.id), ' +
      'anc(id) AS (SELECT id FROM class WHERE id=' + IntToStr(DlgClass) +
      ' UNION ALL SELECT c.parent_id FROM class c JOIN anc a ON c.id=a.id' +
      ' WHERE c.parent_id IS NOT NULL) ' +
      'SELECT c.code, c.name, COALESCE(c.class_no,'''') FROM class_property cp ' +
      'JOIN class c ON c.id=cp.class_id WHERE cp.property_id=' + IntToStr(PId) +
      ' AND cp.class_id IN (SELECT id FROM sub UNION SELECT id FROM anc) ORDER BY c.class_no';
    Q.Open;
    while not Q.EOF do
    begin
      Inc(Cnt);
      if Cnt <= 8 then
        Msg := Msg + LineEnding + '  ' + FieldText(Q.Fields[2]) + '  ' + FieldText(Q.Fields[0]) +
          ' - ' + FieldText(Q.Fields[1]);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  if Cnt > 0 then
    ShowMessage('Das Merkmal "' + PName + '" wurde aus dieser Klasse entfernt.' + LineEnding +
      LineEnding + 'Es ist aber noch diesen verwandten Klassen zugeordnet und bleibt deshalb ' +
      'in der Teileliste sichtbar:' + Msg + LineEnding + LineEnding +
      'Zum vollständigen Entfernen dort ebenfalls entfernen.');
end;

procedure TMainForm.BtnDelPart(Sender: TObject);
var
  Pid: Int64;
  PartNo: string;
  RowNo: Integer;
begin
  Pid := CurPart;
  if Pid = 0 then
  begin
    ShowMessage('Bitte zuerst in der Teileliste ein Teil anklicken.' + LineEnding +
      'Ist die Liste leer, waehle links eine Klasse mit Teilen.');
    Exit;
  end;
  RowNo := GridParts.Row;
  PartNo := CellBy(GridParts, 'Teilenummer', RowNo);
  if MessageDlg('Teil "' + PartNo + '" wirklich loeschen?' + LineEnding +
    'Seine Merkmalswerte werden ebenfalls geloescht.', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Exec('DELETE FROM part_value WHERE part_id=' + IntToStr(Pid));
  Exec('DELETE FROM part WHERE id=' + IntToStr(Pid));
  LoadParts;
  ShowStatus('Teil ' + PartNo + ' gelöscht.');
  if GridParts.RowCount > 1 then
  begin
    if RowNo >= GridParts.RowCount then RowNo := GridParts.RowCount - 1;
    GridParts.Row := RowNo;
    LoadValues;
  end;
end;

procedure TMainForm.PartsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_DELETE:
      begin
        Key := 0;
        BtnDelPart(nil);
      end;
    VK_INSERT:
      begin
        Key := 0;
        BtnNewPart(nil);
      end;
    VK_RETURN:
      begin
        Key := 0;
        BtnEditValues(nil);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        if Tree.CanFocus then Tree.SetFocus;
      end;
  end;
end;

{ ---------- Dialog: Merkmalkatalog ---------- }

{ ---------- gemeinsame Symbolleiste fuer alle Verwaltungsdialoge ---------- }
function TMainForm.DlgToolbar(F: TForm): TPanel;
begin
  Result := TPanel.Create(F);
  Result.Parent := F;
  Result.Align := alTop;
  Result.Top := 0;
  Result.Height := 56;
  Result.BevelOuter := bvNone;
  Result.Caption := '';
  Result.Tag := 6;      // naechste Knopfposition
  F.ShowHint := True;
end;

procedure TMainForm.DlgTB(P: TPanel; AIcon: Integer; const AHint: string;
  AClick: TNotifyEvent);
var
  B: TSpeedButton;
  Bmp: TBitmap;
begin
  B := TSpeedButton.Create(P.Owner);
  B.Parent := P;
  B.SetBounds(P.Tag, 4, 48, 48);
  B.Flat := True;
  Bmp := MakeIconGlyph(AIcon, 32);
  try
    B.Glyph.Assign(Bmp);
  finally
    Bmp.Free;
  end;
  B.Hint := AHint;
  B.ShowHint := True;
  B.OnClick := AClick;
  P.Tag := P.Tag + 52;
end;

procedure TMainForm.DlgTBSep(P: TPanel);
begin
  P.Tag := P.Tag + 14;
end;

procedure TMainForm.DlgCloseClick(Sender: TObject);
begin
  if (Sender is TComponent) and (TComponent(Sender).Owner is TForm) then
    TForm(TComponent(Sender).Owner).ModalResult := mrClose;
end;

procedure TMainForm.DlgTBClose(P: TPanel);
begin
  DlgTBSep(P);
  DlgTB(P, 27, 'Schließen', @DlgCloseClick);
end;

procedure TMainForm.BtnCatalog(Sender: TObject);
var
  F: TForm;
  PT, PRight, PInfo: TPanel;
  InfoLbl, ClsLbl: TLabel;
  Spl, SplR: TSplitter;
  X: Integer;

  procedure AddTB(AIcon: Integer; const AHint: string; AClick: TNotifyEvent);
  var
    B: TSpeedButton;
    Bmp: TBitmap;
  begin
    B := TSpeedButton.Create(F);
    B.Parent := PT;
    B.SetBounds(X, 4, 48, 48);
    B.Flat := True;
    Bmp := MakeIconGlyph(AIcon, 32);
    try
      B.Glyph.Assign(Bmp);
    finally
      Bmp.Free;
    end;
    B.Hint := AHint;
    B.ShowHint := True;
    B.OnClick := AClick;
    Inc(X, 52);
  end;

  procedure AddTSep;
  begin
    Inc(X, 14);
  end;

begin
  CatClass := CurClass;
  F := TForm.CreateNew(Self);
  CatForm := F;
  try
    F.Caption := 'Merkmalkatalog';
    F.Position := poScreenCenter;
    F.Width := 1240;
    F.Height := 640;
    RememberDialog(F, 'Merkmalkatalog');
    F.ShowHint := True;

    PT := TPanel.Create(F);
    PT.Parent := F;
    PT.Align := alTop;
    PT.Top := 0;
    PT.Height := 56;
    PT.BevelOuter := bvNone;
    PT.Caption := '';
    X := 6;
    AddTB(21, 'Neues Merkmal' + LineEnding + 'Legt ein neues Merkmal im Katalog an', @CatNew);
    AddTB(22, 'Merkmal ändern' + LineEnding + 'Name, Einheit und Datentyp des gewählten Merkmals bearbeiten', @CatEdit);
    AddTB(23, 'Aus dem Katalog löschen' + LineEnding +
      'Entfernt das Merkmal aus allen Klassen samt Werten', @CatDel);
    AddTSep;
    AddTB(24, 'Der gewählten Klasse zuordnen' + LineEnding +
      'Alternativ die Merkmale mit der Maus auf eine Klasse rechts ziehen', @CatAssign);
    AddTB(25, 'Aus der gewählten Klasse entfernen' + LineEnding +
      'Das Merkmal bleibt im Katalog erhalten', @CatUnlinkCls);
    AddTSep;
    AddTB(10, 'Beschreibung / Status' + LineEnding + 'Definition und Status des Merkmals', @CatDesc);
    AddTB(11, 'Übersetzung' + LineEnding + 'Name und Definition in weiteren Sprachen', @CatTrans);
    AddTB(26, 'Aufzählungswerte' + LineEnding + 'Erlaubte Werte eines Aufzählungs-Merkmals', @CatEnum);
    AddTSep;
    AddTB(27, 'Schließen', @CatClose);

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 60;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.Caption := 'Links: alle Merkmale der Bibliothek (mehrere mit Strg/Umschalt wählbar). ' +
      'Zum Zuordnen die Merkmale mit der Maus auf eine Klasse rechts ziehen. ' +
      'Zum Entfernen Merkmale aus der Liste unten rechts zurück nach links ziehen.';
    InfoLbl.WordWrap := True;

    CatList := TListBox.Create(F);
    CatList.Parent := F;
    CatList.Align := alLeft;
    CatList.Width := 620;
    CatList.MultiSelect := True;
    CatList.DragMode := dmAutomatic;
    CatList.OnDragOver := @CatOverList;
    CatList.OnDragDrop := @CatDropList;
    MakeCatPopup(CatList);

    Spl := TSplitter.Create(F);
    Spl.Parent := F;
    Spl.Align := alLeft;
    Spl.Left := 625;

    PRight := TPanel.Create(F);
    PRight.Parent := F;
    PRight.Align := alClient;
    PRight.BevelOuter := bvNone;
    PRight.Caption := '';

    PInfo := TPanel.Create(F);
    PInfo.Parent := PRight;
    PInfo.Align := alBottom;
    PInfo.Height := 210;
    PInfo.Constraints.MinHeight := 80;
    PInfo.BevelOuter := bvNone;
    PInfo.Caption := '';

    // Waagerechter Teiler zwischen Klassenbaum (oben) und zugeordneten Merkmalen (unten)
    SplR := TSplitter.Create(F);
    SplR.Parent := PRight;
    SplR.Align := alBottom;
    SplR.Top := PInfo.Top - 1;
    SplR.Height := 6;
    SplR.ResizeAnchor := akBottom;

    ClsLbl := TLabel.Create(F);
    ClsLbl.Parent := PInfo;
    ClsLbl.Align := alTop;
    ClsLbl.BorderSpacing.Around := 4;
    ClsLbl.Caption := 'Merkmale der gewählten Klasse (geerbte sind gekennzeichnet):';

    CatClsList := TListBox.Create(F);
    CatClsList.Parent := PInfo;
    CatClsList.Align := alClient;
    CatClsList.MultiSelect := True;
    CatClsList.DragMode := dmAutomatic;

    CatTree := TTreeView.Create(F);
    CatTree.Parent := PRight;
    CatTree.Align := alClient;
    CatTree.Constraints.MinHeight := 80;
    CatTree.ReadOnly := True;
    CatTree.Images := ImgTree;
    // gleiches Aussehen wie der Hauptbaum: Dreiecke zum Auf-/Zuklappen, keine Linien
    CatTree.ExpandSignType := tvestArrow;
    CatTree.Indent := (22 * Screen.PixelsPerInch + 48) div 96;
    CatTree.Options := CatTree.Options + [tvoRowSelect, tvoHotTrack, tvoThemedDraw] -
      [tvoShowLines];
    StyleTree(CatTree);
    CatTree.HideSelection := False;
    CatTree.OnChange := @CatTreeChange;
    CatTree.OnDragOver := @CatOverTree;
    CatTree.OnDragDrop := @CatDropTree;

    CatRefresh;
    CatBuildTree;
    F.ShowModal;
  finally
    CatList := nil;
    CatTree := nil;
    CatClsList := nil;
    CatForm := nil;
    F.Free;
  end;
  LoadParts;
end;

{ Klassenbaum im Katalog aufbauen und die im Hauptfenster gewaehlte Klasse markieren }
procedure TMainForm.CatBuildTree;
type
  TCRow = record
    Id, Parent: Int64;
    Txt, Status: string;
    Kids: Integer;
  end;
var
  Q: TSQLQuery;
  Rows: array of TCRow;
  n: Integer;
  SelNode: TTreeNode;
  SelId: Int64;

  procedure AddKids(ParentNode: TTreeNode; ParentId: Int64);
  var
    i, Ic: Integer;
    Nd: TTreeNode;
  begin
    for i := 0 to High(Rows) do
      if Rows[i].Parent = ParentId then
      begin
        Nd := CatTree.Items.AddChildObject(ParentNode, Rows[i].Txt,
          Pointer(PtrInt(Rows[i].Id)){%H-});
        Ic := StatusIndex(Rows[i].Status) + 3 * Ord(Rows[i].Kids > 0);
        Nd.ImageIndex := Ic;
        Nd.SelectedIndex := Ic;
        if Rows[i].Id = SelId then SelNode := Nd;
        AddKids(Nd, Rows[i].Id);
      end;
  end;

begin
  if CatTree = nil then Exit;
  SelId := CatClass;
  SelNode := nil;
  Rows := nil;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT c.id, COALESCE(c.parent_id,0), COALESCE(c.class_no,'''') || ''  '' || ' +
      'c.code || '' - '' || ' + NameSql('class', 'c.id', 'c.name') +
      ', c.status, (SELECT COUNT(*) FROM class k WHERE k.parent_id=c.id)' +
      ' FROM class c ORDER BY c.class_no, c.name';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(Rows, n + 1);
      Rows[n].Id := Q.Fields[0].AsLargeInt;
      Rows[n].Parent := Q.Fields[1].AsLargeInt;
      Rows[n].Txt := FieldText(Q.Fields[2]);
      Rows[n].Status := FieldText(Q.Fields[3]);
      Rows[n].Kids := Q.Fields[4].AsInteger;
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  CatTree.Items.BeginUpdate;
  try
    CatTree.Items.Clear;
    AddKids(nil, 0);
  finally
    CatTree.Items.EndUpdate;
  end;
  if (SelNode = nil) and (CatTree.Items.Count > 0) then SelNode := CatTree.Items[0];
  if SelNode <> nil then
  begin
    SelNode.Selected := True;
    SelNode.MakeVisible;
  end
  else
    CatClass := 0;
  CatClsRefresh;
end;

procedure TMainForm.CatClsRefresh;
var
  i: Integer;
  S: string;
begin
  if CatClsList = nil then Exit;
  CatClsProps := nil;
  if CatClass <> 0 then CatClsProps := ApplicableProps(CatClass);
  CatClsList.Items.BeginUpdate;
  try
    CatClsList.Items.Clear;
    for i := 0 to High(CatClsProps) do
    begin
      S := CatClsProps[i].Name;
      if CatClsProps[i].UnitName <> '' then S := S + ' [' + CatClsProps[i].UnitName + ']';
      S := S + ' - ' + CatClsProps[i].DataType;
      if not CatClsProps[i].Direct then S := S + '   (geerbt)';
      CatClsList.Items.Add(S);
    end;
  finally
    CatClsList.Items.EndUpdate;
  end;
  if CatForm <> nil then
  begin
    CatForm.Caption := 'Merkmalkatalog';
    if (CatTree <> nil) and (CatTree.Selected <> nil) then
      CatForm.Caption := CatForm.Caption + ' - Klasse: ' + CatTree.Selected.Text;
  end;
end;

procedure TMainForm.CatTreeChange(Sender: TObject; Node: TTreeNode);
begin
  if Node = nil then
    CatClass := 0
  else
    CatClass := PtrInt(Node.Data);
  CatClsRefresh;
end;

{ Alle in der Katalogliste gewaehlten Merkmale der Klasse zuordnen; liefert die Anzahl }
function TMainForm.CatLinkSel(AClass: Int64): Integer;
var
  i, k: Integer;
  App: TPropDefs;
  Have: Boolean;
begin
  Result := 0;
  if (CatList = nil) or (AClass = 0) then Exit;
  App := ApplicableProps(AClass);
  for i := 0 to CatList.Items.Count - 1 do
    if CatList.Selected[i] and (i <= High(CatProps)) then
    begin
      Have := False;
      for k := 0 to High(App) do
        if App[k].Id = CatProps[i].Id then Have := True;
      if not Have then
      begin
        LinkProp(AClass, CatProps[i].Id);
        Inc(Result);
      end;
    end;
end;

procedure TMainForm.CatOverTree(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var
  Nd: TTreeNode;
begin
  Nd := CatTree.GetNodeAt(X, Y);
  Accept := (Source = CatList) and (Nd <> nil);
  if Accept then CatTree.DropTarget := Nd;
end;

procedure TMainForm.CatDropTree(Sender, Source: TObject; X, Y: Integer);
var
  Nd: TTreeNode;
  N: Integer;
begin
  CatTree.DropTarget := nil;
  Nd := CatTree.GetNodeAt(X, Y);
  if (Source <> CatList) or (Nd = nil) then Exit;
  CatTree.Selected := Nd;
  CatClass := PtrInt(Nd.Data);
  N := CatLinkSel(CatClass);
  CatRefresh;
  CatClsRefresh;
  ShowStatus(IntToStr(N) + ' Merkmal(e) der Klasse zugeordnet.');
end;

procedure TMainForm.CatOverList(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Source = CatClsList;
end;

procedure TMainForm.CatDropList(Sender, Source: TObject; X, Y: Integer);
begin
  if Source = CatClsList then CatUnlinkCls(nil);
end;

{ Gewaehlte Merkmale aus der Klasse entfernen (bleiben im Katalog) }
procedure TMainForm.CatUnlinkCls(Sender: TObject);
var
  I, N, Skipped: Integer;
  Ids: array of Int64;
begin
  Ids := nil;
  N := 0;
  Skipped := 0;
  if CatClass = 0 then
  begin
    ShowMessage('Bitte rechts zuerst eine Klasse wählen.');
    Exit;
  end;
  for I := 0 to CatClsList.Items.Count - 1 do
    if CatClsList.Selected[I] and (I <= High(CatClsProps)) then
    begin
      if CatClsProps[I].Direct then
      begin
        SetLength(Ids, N + 1);
        Ids[N] := CatClsProps[I].Id;
        Inc(N);
      end
      else
        Inc(Skipped);
    end;
  if N = 0 then
  begin
    if Skipped > 0 then
      ShowMessage('Die gewählten Merkmale werden von einer Oberklasse geerbt. ' +
        'Bitte dort entfernen.')
    else
      ShowMessage('Bitte rechts unten ein oder mehrere Merkmale der Klasse wählen.');
    Exit;
  end;
  if MessageDlg(IntToStr(N) + ' Merkmal(e) aus dieser Klasse entfernen?' + LineEnding + LineEnding +
    'Die Werte dieser Merkmale bei den Teilen der Klasse gehen verloren. ' +
    'Die Merkmale bleiben im Merkmalkatalog erhalten.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  for I := 0 to N - 1 do UnlinkProp(CatClass, Ids[I], True);
  CatRefresh;
  CatClsRefresh;
  ShowStatus(IntToStr(N) + ' Merkmal(e) aus der Klasse entfernt.');
end;

procedure TMainForm.CatClose(Sender: TObject);
begin
  if CatForm <> nil then CatForm.ModalResult := mrClose;
end;

procedure TMainForm.CatRefresh;
var
  i, Sel: Integer;
  S: string;
begin
  if CatList = nil then Exit;
  Sel := CatList.ItemIndex;
  CatProps := AllProps;
  CatList.Items.BeginUpdate;
  try
    CatList.Items.Clear;
    for i := 0 to High(CatProps) do
    begin
      S := CatProps[i].Name;
      if CatProps[i].UnitName <> '' then S := S + ' [' + CatProps[i].UnitName + ']';
      S := S + ' - ' + CatProps[i].DataType + ' <' + CatProps[i].Bsu + '>';
      if CatProps[i].Status = 'veraltet' then S := S + ' (veraltet)';
      S := S + ' - in ' + IntToStr(CatProps[i].UseCount) + ' Klasse(n)';
      CatList.Items.Add(S);
    end;
  finally
    CatList.Items.EndUpdate;
  end;
  if Sel >= CatList.Items.Count then Sel := CatList.Items.Count - 1;
  if (Sel < 0) and (CatList.Items.Count > 0) then Sel := 0;
  CatList.ItemIndex := Sel;
end;

procedure TMainForm.CatNew(Sender: TObject);
var
  Pid: Int64;
  Existing: Boolean;
begin
  Pid := AskNewProp(Existing);
  if Pid = 0 then Exit;
  if Existing then
    ShowMessage('Ein Merkmal mit diesem Code existiert bereits im Katalog.');
  CatRefresh;
end;

procedure TMainForm.CatEdit(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CatList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  if EditPropDlg(CatProps[Idx]) then CatRefresh;
end;

procedure TMainForm.CatDel(Sender: TObject);
var
  Idx: Integer;
  Msg: string;
begin
  Idx := CatList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  Msg := 'Merkmal "' + CatProps[Idx].Name + '" aus dem Katalog loeschen?';
  if CatProps[Idx].UseCount > 0 then
    Msg := Msg + ' Es wird in ' + IntToStr(CatProps[Idx].UseCount) +
      ' Klasse(n) verwendet und dort entfernt; alle zugehoerigen Werte ' +
      'der Teile gehen verloren.';
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  DeleteProp(CatProps[Idx].Id);
  CatRefresh;
end;

procedure TMainForm.CatAssign(Sender: TObject);
var
  N: Integer;
begin
  if CatClass = 0 then
  begin
    ShowMessage('Bitte rechts zuerst eine Klasse wählen.');
    Exit;
  end;
  if CatList.SelCount = 0 then
  begin
    ShowMessage('Bitte links ein oder mehrere Merkmale wählen.');
    Exit;
  end;
  N := CatLinkSel(CatClass);
  CatRefresh;
  CatClsRefresh;
  ShowStatus(IntToStr(N) + ' Merkmal(e) der Klasse zugeordnet.');
end;

{ ---------- Klasse loeschen ---------- }

procedure TMainForm.BtnDelClass(Sender: TObject);
var
  Cid, ParentId, NParts: Int64;
  Msg: string;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  if ScalarInt('SELECT COUNT(*) FROM class WHERE parent_id=' + IntToStr(Cid)) > 0 then
  begin
    ShowMessage('Die Klasse hat Unterklassen. Bitte zuerst diese loeschen.');
    Exit;
  end;
  NParts := ScalarInt('SELECT COUNT(*) FROM part WHERE class_id=' + IntToStr(Cid));
  Msg := 'Klasse "' + Tree.Selected.Text + '" wirklich loeschen?';
  if NParts > 0 then
    Msg := Msg + ' Ihre ' + IntToStr(NParts) +
      ' Teil(e) werden samt Werten ebenfalls geloescht.';
  Msg := Msg + ' Die Merkmale bleiben im Katalog erhalten.';
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  ParentId := ScalarInt('SELECT COALESCE(parent_id,0) FROM class WHERE id=' +
    IntToStr(Cid));
  Exec('DELETE FROM part_value WHERE part_id IN (SELECT id FROM part WHERE class_id=' +
    IntToStr(Cid) + ')');
  Exec('DELETE FROM part WHERE class_id=' + IntToStr(Cid));
  Exec('DELETE FROM class_property WHERE class_id=' + IntToStr(Cid));
  Exec('DELETE FROM class_image WHERE class_id=' + IntToStr(Cid));
  Exec('DELETE FROM search_term WHERE class_id=' + IntToStr(Cid));
  Exec('DELETE FROM class WHERE id=' + IntToStr(Cid));
  LoadTree(ParentId);
end;

{ ---------- Dialog: Werte eines Teils bearbeiten ---------- }

{ ---------- Eingabemaske fuer Teile: Teilenummer, Beschreibung, Lieferant und alle Merkmale ---------- }

{ Wert des Merkmals Nr. I aus der Maske (leer = kein Wert; Aufzaehlung: Code) }
function TMainForm.PmValue(I: Integer): string;
var
  Ix: Integer;
begin
  if PmCtrls[I] is TComboBox then
  begin
    Ix := TComboBox(PmCtrls[I]).ItemIndex;
    if (Ix <= 0) or (PmCodes[I] = nil) or (Ix >= PmCodes[I].Count) then Result := ''
    else Result := PmCodes[I][Ix];
  end
  else
    Result := Trim(TEdit(PmCtrls[I]).Text);
end;

procedure TMainForm.PmOpenLink(Sender: TObject);
var
  U: string;
begin
  U := CadLinkUrl(PmLink.Text);
  if U = '' then
  begin
    ShowMessage('Bitte zuerst einen Link eintragen (z. B. von 3DfindIT oder PARTcommunity).');
    Exit;
  end;
  OpenURL(U);
end;

procedure TMainForm.BtnOpenCadLink(Sender: TObject);
var
  Pid: Int64;
  U: string;
begin
  Pid := CurPart;
  if Pid = 0 then
  begin
    ShowMessage('Bitte zuerst in der Teileliste ein Teil anklicken.');
    Exit;
  end;
  U := CadLinkUrl(RowStr('part', 'cad_link', Pid));
  if U = '' then
  begin
    ShowMessage('Zu diesem Teil ist noch kein CAD-Katalog-Link hinterlegt.' + LineEnding +
      'Du kannst ihn unter "Werte / Teil bearbeiten" im Feld "CAD-Link" eintragen.');
    Exit;
  end;
  OpenURL(U);
  StartDlWatch(Pid);
end;

procedure TMainForm.PmOk(Sender: TObject);
var
  I: Integer;
  V: string;
  I64: Int64;
  D: Double;
begin
  for I := 0 to High(PmProps) do
  begin
    V := PmValue(I);
    if V = '' then Continue;
    if (PmProps[I].DataType = 'integer') and (not TryStrToInt64(V, I64)) then
    begin
      ShowMessage('Der Wert von "' + PmProps[I].Name + '" muss eine ganze Zahl sein.');
      PmCtrls[I].SetFocus;
      Exit;
    end;
    if (PmProps[I].DataType = 'real') and (not ParseNum(V, D)) then
    begin
      ShowMessage('Der Wert von "' + PmProps[I].Name + '" muss eine Zahl sein ' +
        '(Dezimalkomma oder Dezimalpunkt).');
      PmCtrls[I].SetFocus;
      Exit;
    end;
  end;
  PmForm.ModalResult := mrOK;
end;

{ APart = 0: neues Teil in AClass anlegen; sonst Teil APart bearbeiten.
  Ergibt die Teile-Id oder 0 bei Abbruch. }
function TMainForm.PartMask(AClass, APart: Int64): Int64;
var
  F: TForm;
  PTop, PBot: TPanel;
  SB: TScrollBox;
  L: TLabel;
  E: TEdit;
  Cb: TComboBox;
  Bt: TButton;
  Q: TSQLQuery;
  Vals, EnumCodes: TStringList;
  Props: TPropDefs;
  I, Y, Ix, N: Integer;
  V, UHint: string;
  Sup: Int64;
  OldBatch: Boolean;

  function NewLabel(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer): TLabel;
  begin
    Result := TLabel.Create(F);
    Result.Parent := AParent;
    Result.SetBounds(ALeft, ATop, AWidth, 20);
    Result.AutoSize := False;
    Result.Caption := ACaption;
  end;

begin
  Result := 0;
  Props := ApplicableProps(AClass);
  PmProps := Props;
  PmPart := APart;
  PmSupIds := nil;
  SetLength(PmCtrls, Length(Props));
  SetLength(PmCodes, Length(Props));
  for I := 0 to High(Props) do PmCodes[I] := nil;
  Vals := TStringList.Create;
  F := TForm.CreateNew(Self);
  try
    PmForm := F;
    // vorhandene Werte (beim Bearbeiten)
    if APart > 0 then
    begin
      Q := TSQLQuery.Create(nil);
      try
        Q.DataBase := DbCtx.Conn;
        Q.Transaction := DbCtx.Trans;
        Q.SQL.Text := 'SELECT property_id, value FROM part_value WHERE part_id=' + IntToStr(APart);
        Q.Open;
        while not Q.EOF do
        begin
          Vals.Values[IntToStr(Q.Fields[0].AsLargeInt)] := FieldText(Q.Fields[1]);
          Q.Next;
        end;
        Q.Close;
      finally
        Q.Free;
      end;
    end;

    if APart = 0 then
      F.Caption := 'Neues Teil in Klasse ' + RowStr('class', 'code', AClass) + ' - ' +
        RowStr('class', 'name', AClass)
    else
      F.Caption := 'Teil bearbeiten: ' + RowStr('part', 'part_number', APart);
    F.BorderStyle := bsDialog;
    F.Position := poOwnerFormCenter;
    F.Width := 660;
    N := Length(Props);
    F.Height := 254 + 56 + N * 32 + 20;
    if F.Height > Screen.WorkAreaHeight - 80 then F.Height := Screen.WorkAreaHeight - 80;
    if F.Height < 380 then F.Height := 380;

    // oben: Teilenummer, Beschreibung, Lieferant
    PTop := TPanel.Create(F);
    PTop.Parent := F;
    PTop.Align := alTop;
    PTop.Height := 214;
    PTop.BevelOuter := bvNone;
    PTop.Caption := '';
    NewLabel(PTop, 'Teilenummer:', 12, 14, 120);
    PmPartNo := TEdit.Create(F);
    PmPartNo.Parent := PTop;
    PmPartNo.SetBounds(140, 10, 490, 26);
    PmPartNo.ReadOnly := True;     // wird automatisch vergeben
    PmPartNo.TabStop := False;
    NewLabel(PTop, 'Beschreibung:', 12, 46, 120);
    PmDesc := TEdit.Create(F);
    PmDesc.Parent := PTop;
    PmDesc.SetBounds(140, 42, 490, 26);
    NewLabel(PTop, 'Hersteller:', 12, 78, 120);
    PmManu := TEdit.Create(F);
    PmManu.Parent := PTop;
    PmManu.SetBounds(140, 74, 490, 26);
    NewLabel(PTop, 'Lieferant:', 12, 110, 120);
    PmSup := TComboBox.Create(F);
    PmSup.Parent := PTop;
    PmSup.Style := csDropDownList;
    PmSup.SetBounds(140, 106, 490, 26);
    NewLabel(PTop, 'CAD-Link:', 12, 142, 120);
    PmLink := TEdit.Create(F);
    PmLink.Parent := PTop;
    PmLink.SetBounds(140, 138, 380, 26);
    PmLink.TextHint := 'Link aus 3DfindIT / PARTcommunity (optional)';
    Bt := TButton.Create(F);
    Bt.Parent := PTop;
    Bt.SetBounds(528, 137, 102, 28);
    Bt.Caption := 'Öffnen';
    Bt.OnClick := @PmOpenLink;
    Sup := DefSupplier;
    if APart > 0 then
    begin
      PmPartNo.Text := RowStr('part', 'part_number', APart);
      PmDesc.Text := RowStr('part', 'description', APart);
      PmManu.Text := RowStr('part', 'manufacturer', APart);
      PmLink.Text := RowStr('part', 'cad_link', APart);
      Sup := ScalarInt('SELECT COALESCE(supplier_id,0) FROM part WHERE id=' + IntToStr(APart));
    end
    else
    begin
      PmPartNo.Text := NextPartNo + '  (wird automatisch vergeben)';
      PmDesc.Text := FPreDesc;
      PmManu.Text := FPreManu;
      FPreDesc := '';
      FPreManu := '';
    end;
    Q := TSQLQuery.Create(nil);
    try
      Q.DataBase := DbCtx.Conn;
      Q.Transaction := DbCtx.Trans;
      Q.SQL.Text := 'SELECT id, code, name FROM supplier ORDER BY code';
      Q.Open;
      while not Q.EOF do
      begin
        SetLength(PmSupIds, Length(PmSupIds) + 1);
        PmSupIds[High(PmSupIds)] := Q.Fields[0].AsLargeInt;
        PmSup.Items.Add(FieldText(Q.Fields[1]) + ' - ' + FieldText(Q.Fields[2]));
        if Q.Fields[0].AsLargeInt = Sup then PmSup.ItemIndex := PmSup.Items.Count - 1;
        Q.Next;
      end;
      Q.Close;
    finally
      Q.Free;
    end;
    if (PmSup.ItemIndex < 0) and (PmSup.Items.Count > 0) then PmSup.ItemIndex := 0;
    L := NewLabel(PTop, 'Merkmale (leer lassen, wenn nicht bekannt):', 12, 182, 600);
    L.Font.Style := [fsBold];

    // unten: Knoepfe
    PBot := TPanel.Create(F);
    PBot.Parent := F;
    PBot.Align := alBottom;
    PBot.Height := 48;
    PBot.BevelOuter := bvNone;
    PBot.Caption := '';
    Bt := TButton.Create(F);
    Bt.Parent := PBot;
    Bt.SetBounds(400, 10, 110, 30);
    Bt.Caption := 'Speichern';
    Bt.Default := True;   // Enter speichert, Tab wechselt das Feld
    Bt.OnClick := @PmOk;
    Bt := TButton.Create(F);
    Bt.Parent := PBot;
    Bt.SetBounds(520, 10, 110, 30);
    Bt.Caption := 'Abbrechen';
    Bt.ModalResult := mrCancel;
    Bt.Cancel := True;

    // Mitte: ein Feld je Merkmal, passend zum Datentyp
    SB := TScrollBox.Create(F);
    SB.Parent := F;
    SB.Align := alClient;
    SB.BorderStyle := bsNone;
    SB.HorzScrollBar.Visible := False;
    Y := 8;
    for I := 0 to High(Props) do
    begin
      NewLabel(SB, Props[I].Name + ':', 12, Y + 4, 210);
      V := Vals.Values[IntToStr(Props[I].Id)];
      UHint := Props[I].UnitName;
      if (Props[I].DataType = 'enum') or (Props[I].DataType = 'boolean') then
      begin
        Cb := TComboBox.Create(F);
        Cb.Parent := SB;
        Cb.Style := csDropDownList;
        Cb.SetBounds(228, Y, 300, 26);
        EnumCodes := TStringList.Create;
        EnumCodes.Add('');
        Cb.Items.Add('(kein Wert)');
        if Props[I].DataType = 'boolean' then
        begin
          EnumCodes.Add('ja');
          Cb.Items.Add('ja');
          EnumCodes.Add('nein');
          Cb.Items.Add('nein');
          if SameText(V, '1') or SameText(V, 'true') then V := 'ja';
          if SameText(V, '0') or SameText(V, 'false') then V := 'nein';
        end
        else
        begin
          Q := TSQLQuery.Create(nil);
          try
            Q.DataBase := DbCtx.Conn;
            Q.Transaction := DbCtx.Trans;
            Q.SQL.Text := 'SELECT e.code, ' + NameSql('enum', 'e.id', 'e.name') +
              ' FROM enum_value e WHERE e.property_id=' + IntToStr(Props[I].Id) +
              ' ORDER BY e.code';
            Q.Open;
            while not Q.EOF do
            begin
              EnumCodes.Add(FieldText(Q.Fields[0]));
              Cb.Items.Add(FieldText(Q.Fields[0]) + ' - ' + FieldText(Q.Fields[1]));
              Q.Next;
            end;
            Q.Close;
          finally
            Q.Free;
          end;
          if EnumCodes.Count = 1 then UHint := 'keine Auswahlwerte angelegt';
        end;
        PmCodes[I] := EnumCodes;
        Ix := EnumCodes.IndexOf(V);
        if Ix < 0 then Ix := 0;
        Cb.ItemIndex := Ix;
        PmCtrls[I] := Cb;
      end
      else
      begin
        E := TEdit.Create(F);
        E.Parent := SB;
        E.SetBounds(228, Y, 300, 26);
        E.Text := V;
        PmCtrls[I] := E;
        if (UHint = '') and (Props[I].DataType = 'integer') then UHint := 'ganze Zahl';
        if (UHint = '') and (Props[I].DataType = 'real') then UHint := 'Zahl';
      end;
      if UHint <> '' then
      begin
        L := NewLabel(SB, UHint, 540, Y + 4, 100);
        L.Font.Color := clGrayText;
      end;
      Inc(Y, 32);
    end;
    if Length(Props) = 0 then
    begin
      L := NewLabel(SB, 'Dieser Klasse sind noch keine Merkmale zugeordnet ' +
        '(Merkmale, Merkmale der gewählten Klasse verwalten).', 12, 12, 620);
      L.WordWrap := True;
      L.Height := 40;
    end;
    // Tab-Reihenfolge: Kopfbereich, Merkmalsfelder, dann die Knoepfe
    PTop.TabOrder := 0;
    SB.TabOrder := 1;
    PBot.TabOrder := 2;
    F.ActiveControl := PmDesc;

    if F.ShowModal <> mrOK then Exit;

    // speichern: alles in einer Transaktion
    OldBatch := DbCtx.Batch;
    DbCtx.Batch := True;
    try
      try
        if APart = 0 then
        begin
          Result := AddPart(AClass, '', Trim(PmDesc.Text));
        end
        else
          Result := APart;
        Sup := 0;
        if PmSup.ItemIndex >= 0 then Sup := PmSupIds[PmSup.ItemIndex];
        Exec(Format('UPDATE part SET description=%s, manufacturer=%s, ' +
          'cad_link=%s, supplier_id=%d WHERE id=%d',
          [QuotedStr(Trim(PmDesc.Text)),
           QuotedStr(Trim(PmManu.Text)), QuotedStr(Trim(PmLink.Text)), Sup, Result]));
        for I := 0 to High(Props) do
        begin
          V := PmValue(I);
          if V = '' then
          begin
            if APart > 0 then
              Exec(Format('DELETE FROM part_value WHERE part_id=%d AND property_id=%d',
                [Result, Props[I].Id]));
          end
          else
            SetValue(Result, Props[I].Id, V);
        end;
        DbCtx.Trans.CommitRetaining;
      except
        DbCtx.Trans.RollbackRetaining;
        Result := 0;
        raise;
      end;
    finally
      DbCtx.Batch := OldBatch;
    end;
  finally
    for I := 0 to High(PmCodes) do PmCodes[I].Free;
    PmCodes := nil;
    PmCtrls := nil;
      PmForm := nil;
    Vals.Free;
    F.Free;
  end;
end;

procedure TMainForm.BtnNewPartInClass(Sender: TObject);
var
  Cid, Pid: Int64;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  Pid := PartMask(Cid, 0);
  if Pid = 0 then Exit;
  LoadParts;
  SelectPart(Pid);
  ShowStatus('Teil ' + RowStr('part', 'part_number', Pid) + ' angelegt.');
end;

{ Neues Teil mit Klassenvorschlag: erst Bezeichnung und Hersteller, dann waehlt der
  Benutzer die Klasse (Vorschlag, andere Klasse oder neue Klasse), dann die Eingabemaske }
procedure TMainForm.BtnNewPart(Sender: TObject);
var
  Cid, Pid: Int64;
  Desc, Manu, Sug: string;
begin
  if not AskNewPartClass(Cid, Desc, Manu) then Exit;
  if not SelectClass(Cid) then LoadTree(Cid);
  FPreDesc := Desc;
  FPreManu := Manu;
  Pid := PartMask(Cid, 0);
  FPreDesc := '';
  FPreManu := '';
  if Pid = 0 then
  begin
    if NpCreated then LoadTree(Cid);
    Exit;
  end;
  // die Entscheidung des Benutzers fuer spaetere Vorschlaege merken
  if NpFirstSug > 0 then Sug := IntToStr(NpFirstSug) else Sug := 'NULL';
  Exec(Format('INSERT INTO suggest_history(article_text,suggested_class_id,chosen_class_id,created) ' +
    'VALUES(%s,%s,%d,' + DateSql + ')',
    [QuotedStr(Trim(Desc + ' ' + Manu)), Sug, Cid]));
  LoadParts;
  SelectPart(Pid);
  ShowStatus('Teil ' + RowStr('part', 'part_number', Pid) + ' angelegt.');
end;

procedure TMainForm.NpFillAll;
var
  Q: TSQLQuery;
  Lv: Integer;
  No: string;
begin
  NpAll.Items.Clear;
  NpAll.Items.Add('(keine Auswahl)');
  NpAllIds := nil;
  SetLength(NpAllIds, 1);
  NpAllIds[0] := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT id, COALESCE(class_no,''''), name FROM class ORDER BY class_no, name';
    Q.Open;
    while not Q.EOF do
    begin
      No := FieldText(Q.Fields[1]);
      Lv := ClassNoLevelOf(No);
      if Lv < 1 then Lv := 1;
      NpAll.Items.Add(StringOfChar(' ', (Lv - 1) * 3) + No + '  ' + FieldText(Q.Fields[2]));
      SetLength(NpAllIds, Length(NpAllIds) + 1);
      NpAllIds[High(NpAllIds)] := Q.Fields[0].AsLargeInt;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

procedure TMainForm.NpRun(Sender: TObject);
var
  Sg: TPointsSuggester;
  Inp: TSuggestInput;
  i: Integer;
begin
  Inp.Description := Trim(NpDesc.Text);
  Inp.Manufacturer := Trim(NpManu.Text);
  Inp.Supplier := '';
  Inp.Extra := '';
  if Inp.Description = '' then
  begin
    ShowMessage('Bitte zuerst eine Bezeichnung oder Beschreibung eingeben, ' +
      'z. B. „M6x20 DIN933 Edelstahl".');
    if NpDesc.CanFocus then NpDesc.SetFocus;
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    Sg := TPointsSuggester.Create(DbCtx.Conn, DbCtx.Trans);
    try
      NpSug := Sg.Suggest(Inp);
    finally
      Sg.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  NpList.Items.Clear;
  for i := 0 to High(NpSug.Items) do
    NpList.Items.Add(Format('%s   %s   (%d Punkte)',
      [NpSug.Items[i].ClassNo, NpSug.Items[i].ClassName, NpSug.Items[i].Points]));
  if NpSug.Tokens <> '' then
    NpInfo.Caption := 'Erkannte Begriffe: ' + NpSug.Tokens
  else
    NpInfo.Caption := '';
  NpFirstSug := 0;
  if Length(NpSug.Items) > 0 then NpFirstSug := NpSug.Items[0].ClassId;
  if NpSug.HasMatch then
  begin
    NpList.ItemIndex := 0;
    NpListSelect(nil);
  end
  else
  begin
    NpList.ItemIndex := -1;
    NpBusy := True;
    NpAll.ItemIndex := 0;
    NpBusy := False;
    NpCls := 0;
    NpOk.Enabled := False;
    if Length(NpSug.Items) > 0 then
      NpWhy.Text := 'Keine eindeutige Klasse gefunden. Die Liste zeigt schwache Treffer.' +
        LineEnding + 'Wähle eine Klasse aus der Liste oder aus „Andere Klasse", ' +
        'oder lege mit „Neue Klasse anlegen ..." eine neue an.'
    else
      NpWhy.Text := 'Keine passende Klasse gefunden.' + LineEnding +
        'Wähle eine Klasse aus „Andere Klasse" oder lege mit „Neue Klasse anlegen ..." ' +
        'eine neue an.';
  end;
end;

procedure TMainForm.NpListSelect(Sender: TObject);
var
  Idx, k: Integer;
begin
  Idx := NpList.ItemIndex;
  if (Idx < 0) or (Idx > High(NpSug.Items)) then Exit;
  NpCls := NpSug.Items[Idx].ClassId;
  NpWhy.Text := 'Empfohlene Klasse: ' + NpSug.Items[Idx].ClassNo + '  ' +
    NpSug.Items[Idx].ClassName + LineEnding + LineEnding + 'Begründung:' + LineEnding +
    NpSug.Items[Idx].Reasons;
  NpBusy := True;
  try
    NpAll.ItemIndex := 0;
    for k := 0 to High(NpAllIds) do
      if NpAllIds[k] = NpCls then NpAll.ItemIndex := k;
  finally
    NpBusy := False;
  end;
  NpOk.Enabled := True;
end;

procedure TMainForm.NpListSel2(Sender: TObject; User: Boolean);
begin
  if User then NpListSelect(Sender);
end;

procedure TMainForm.NpAllChange(Sender: TObject);
var
  Idx: Integer;
begin
  if NpBusy then Exit;
  Idx := NpAll.ItemIndex;
  if (Idx <= 0) or (Idx > High(NpAllIds)) then Exit;
  NpCls := NpAllIds[Idx];
  NpList.ItemIndex := -1;
  NpWhy.Text := 'Von dir gewählte Klasse: ' + RowStr('class', 'class_no', NpCls) + '  ' +
    RowStr('class', 'name', NpCls);
  NpOk.Enabled := True;
end;

{ Neue Klasse anlegen: unter der gewaehlten Klasse, sonst unter der Oberklasse des Vorschlags }
procedure TMainForm.NpNewClass(Sender: TObject);
var
  Par, NewId: Int64;
  Ix: Integer;
  V: TStrArr;
  Cap, Msg, No: string;
begin
  if NpCls <> 0 then Par := NpCls else Par := NpSug.NewParentId;
  No := NextClassNo(Par);
  if No = '' then
  begin
    ShowMessage('Unter dieser Klasse ist keine Unterklasse mehr möglich ' +
      '(höchstens 4 Ebenen, je Ebene 99 Klassen). Wähle eine andere Oberklasse.');
    Exit;
  end;
  if Par = 0 then
    Cap := 'Neue Hauptklasse'
  else
    Cap := 'Neue Unterklasse von ' + RowStr('class', 'class_no', Par) + '  ' +
      RowStr('class', 'name', Par);
  SetLength(V, 3);
  V[0] := SuggestClassCode(Par);
  V[1] := SuggestClassName(Par);
  V[2] := No;
  if not EditFieldsEx(Cap,
    ['Code (Vorschlag, änderbar):', 'Name (Vorschlag, änderbar):',
     'Klassennummer AA.BB.CC.DD (Vorschlag):'],
    ['text', 'text', 'text'], V, 1) then Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  V[2] := Trim(V[2]);
  if (not ValidCode(V[0])) or (V[1] = '') then
  begin
    ShowMessage('Ungültiger Code (erlaubt: Buchstaben, Ziffern, - _ . ; maximal 40 Zeichen) ' +
      'oder leerer Name.');
    Exit;
  end;
  if not CheckClassNo(V[2], Par, 0, Msg) then
  begin
    ShowMessage(Msg);
    Exit;
  end;
  if CodeTaken('class', V[0], 0) then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist schon vergeben.');
    Exit;
  end;
  NewId := AddClass(V[0], V[1], Par, '', V[2]);
  NpCreated := True;
  NpCls := NewId;
  NpFillAll;
  NpBusy := True;
  try
    NpList.ItemIndex := -1;
    NpAll.ItemIndex := 0;
    for Ix := 0 to High(NpAllIds) do
      if NpAllIds[Ix] = NewId then NpAll.ItemIndex := Ix;
  finally
    NpBusy := False;
  end;
  NpWhy.Text := 'Neue Klasse angelegt: ' + V[2] + '  ' + V[1] + LineEnding +
    'Die Merkmale kannst du danach über „Merkmale, Merkmale der gewählten Klasse ' +
    'verwalten" festlegen.';
  NpOk.Enabled := True;
end;

procedure TMainForm.NpOkClick(Sender: TObject);
begin
  if NpCls = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse wählen.');
    Exit;
  end;
  NpForm.ModalResult := mrOK;
end;

function TMainForm.AskNewPartClass(out ACls: Int64; out ADesc, AManu: string): Boolean;
var
  F: TForm;
  L: TLabel;
  B: TButton;
begin
  Result := False;
  ACls := 0;
  ADesc := '';
  AManu := '';
  NpSug.Items := nil;
  NpSug.HasMatch := False;
  NpSug.NewParentId := 0;
  NpSug.Tokens := '';
  NpCls := 0;
  NpFirstSug := 0;
  NpCreated := False;
  NpBusy := False;
  F := TForm.CreateNew(Self);
  NpForm := F;
  try
    F.Caption := 'Neues Teil - Klasse vorschlagen';
    F.Position := poScreenCenter;
    F.BorderStyle := bsDialog;
    F.ClientWidth := 760;
    F.ClientHeight := 600;

    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(12, 10, 736, 18);
    L.Caption := 'Bezeichnung / Beschreibung des Teils (z. B. „M6x20 DIN933 Edelstahl"):';
    NpDesc := TEdit.Create(F);
    NpDesc.Parent := F;
    NpDesc.SetBounds(12, 32, 736, 26);

    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(12, 68, 340, 18);
    L.Caption := 'Hersteller (optional):';
    NpManu := TEdit.Create(F);
    NpManu.Parent := F;
    NpManu.SetBounds(12, 90, 360, 26);
    B := TButton.Create(F);
    B.Parent := F;
    B.SetBounds(388, 88, 200, 30);
    B.Caption := 'Klasse vorschlagen';
    B.Default := True;   // Enter loest den Vorschlag aus
    B.OnClick := @NpRun;

    NpInfo := TLabel.Create(F);
    NpInfo.Parent := F;
    NpInfo.SetBounds(12, 128, 736, 18);
    NpInfo.Font.Color := clGrayText;
    NpInfo.Caption := '';

    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(12, 152, 736, 18);
    L.Font.Style := [fsBold];
    L.Caption := 'Vorschläge (nach Punkten sortiert):';
    NpList := TListBox.Create(F);
    NpList.Parent := F;
    NpList.SetBounds(12, 174, 736, 140);
    NpList.OnClick := @NpListSelect;
    NpList.OnSelectionChange := @NpListSel2;

    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(12, 322, 736, 18);
    L.Font.Style := [fsBold];
    L.Caption := 'Begründung:';
    NpWhy := TMemo.Create(F);
    NpWhy.Parent := F;
    NpWhy.SetBounds(12, 344, 736, 112);
    NpWhy.ReadOnly := True;
    NpWhy.ScrollBars := ssAutoVertical;
    NpWhy.TabStop := False;
    NpWhy.Text := 'Gib oben die Bezeichnung ein und wähle „Klasse vorschlagen". ' +
      'Der Vorschlag ist unverbindlich: Du kannst ihn übernehmen, eine andere Klasse wählen ' +
      'oder eine neue Klasse anlegen.';

    L := TLabel.Create(F);
    L.Parent := F;
    L.SetBounds(12, 466, 736, 18);
    L.Caption := 'Oder eine andere Klasse wählen:';
    NpAll := TComboBox.Create(F);
    NpAll.Parent := F;
    NpAll.Style := csDropDownList;
    NpAll.SetBounds(12, 488, 736, 26);
    NpAll.DropDownCount := 24;
    NpFillAll;
    NpAll.ItemIndex := 0;
    NpAll.OnChange := @NpAllChange;

    B := TButton.Create(F);
    B.Parent := F;
    B.SetBounds(12, 556, 190, 30);
    B.Caption := 'Neue Klasse anlegen ...';
    B.OnClick := @NpNewClass;
    NpOk := TButton.Create(F);
    NpOk.Parent := F;
    NpOk.SetBounds(468, 556, 190, 30);
    NpOk.Caption := 'Weiter zur Eingabe';
    NpOk.Enabled := False;
    NpOk.OnClick := @NpOkClick;
    B := TButton.Create(F);
    B.Parent := F;
    B.SetBounds(668, 556, 80, 30);
    B.Caption := 'Abbrechen';
    B.ModalResult := mrCancel;
    B.Cancel := True;

    F.ActiveControl := NpDesc;
    if F.ShowModal = mrOK then
    begin
      ACls := NpCls;
      ADesc := Trim(NpDesc.Text);
      AManu := Trim(NpManu.Text);
      Result := ACls <> 0;
    end;
  finally
    NpForm := nil;
    F.Free;
  end;
end;

procedure TMainForm.BtnEditValues(Sender: TObject);
var
  Keep, ValPart, ValClass: Int64;
begin
  if CurPart = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil waehlen.');
    Exit;
  end;
  ValPart := CurPart;
  ValClass := ScalarInt('SELECT class_id FROM part WHERE id=' + IntToStr(ValPart));
  Keep := PartMask(ValClass, ValPart);
  if Keep = 0 then Exit;
  LoadParts;
  SelectPart(Keep);
  ShowStatus('Teil gespeichert.');
end;

{ ---------- Lieferanten / Schema-Migration ---------- }

procedure TMainForm.EnsureColumn(const ATable, ACol, ADef: string);
begin
  if DbCtx.IsPg then
    Exec('ALTER TABLE ' + ATable + ' ADD COLUMN IF NOT EXISTS ' + ACol + ' ' + ADef)
  else if ScalarInt(Format('SELECT COUNT(*) FROM pragma_table_info(%s) WHERE name=%s',
    [QuotedStr(ATable), QuotedStr(ACol)])) = 0 then
    Exec('ALTER TABLE ' + ATable + ' ADD COLUMN ' + ACol + ' ' + ADef);
end;

{ Ergaenzt aeltere Datenbanken um Lieferanten- und Versionsspalten }
procedure TMainForm.MigrateSchema;
var
  Def: Int64;
begin
  Exec('CREATE TABLE IF NOT EXISTS supplier(' +
    'id ' + PkType + ', code TEXT NOT NULL UNIQUE, ' +
    'name TEXT NOT NULL, is_default INTEGER NOT NULL DEFAULT 0)');
  if ScalarInt('SELECT COUNT(*) FROM supplier') = 0 then
    Exec('INSERT INTO supplier(code,name,is_default) VALUES(''EIGEN'',''Eigener Lieferant'',1)');
  EnsureColumn('class', 'supplier_id', 'INTEGER');
  EnsureColumn('class', 'version', 'INTEGER NOT NULL DEFAULT 1');
  EnsureColumn('property', 'supplier_id', 'INTEGER');
  EnsureColumn('property', 'version', 'INTEGER NOT NULL DEFAULT 1');
  EnsureColumn('part', 'supplier_id', 'INTEGER');
  Def := DefSupplier;
  Exec(Format('UPDATE class SET supplier_id=%d WHERE supplier_id IS NULL', [Def]));
  Exec(Format('UPDATE property SET supplier_id=%d WHERE supplier_id IS NULL', [Def]));
  Exec(Format('UPDATE part SET supplier_id=%d WHERE supplier_id IS NULL', [Def]));
end;

function TMainForm.DefSupplier: Int64;
begin
  Result := ScalarInt('SELECT id FROM supplier ORDER BY is_default DESC, id LIMIT 1');
end;

function TMainForm.AskSupplier(const ACaption: string; var ASup: Int64): Boolean;
var
  Code: string;
  Id: Int64;
begin
  Result := False;
  if ASup = 0 then ASup := DefSupplier;
  Code := ScalarStr('SELECT code FROM supplier WHERE id=' + IntToStr(ASup));
  if not InputQuery(ACaption, 'Lieferant (Code, siehe Button "Lieferanten"):', Code) then Exit;
  Code := Trim(Code);
  Id := ScalarInt('SELECT id FROM supplier WHERE code=' + QuotedStr(Code));
  if Id = 0 then
  begin
    ShowMessage('Lieferant "' + Code + '" existiert nicht.');
    Exit;
  end;
  ASup := Id;
  Result := True;
end;

{ ---------- Datenquellen im Internet (ETIM) ---------- }
type
  TDataSrc = record
    Title, Url, Text: string;
  end;

const
  DataSrcs: array[0..5] of TDataSrc = (
    (Title: 'ETIM International - Klassen und Merkmale (Release)';
     Url: 'https://etim-international.com/?p=754';
     Text: 'Der ETIM-Klassenkatalog selbst: Klassen, Merkmale, Einheiten und ' +
       'Aufzaehlungswerte im XML-Format ETIM IXF. Laut ETIM frei erhaeltlich fuer ' +
       'die offenen Sprachversionen (u. a. Englisch); nicht alle Sprachversionen ' +
       'sind kostenlos. Aktuell: ETIM 10.0 (Dezember 2024). Geeignet als Quelle fuer ' +
       'fertige Klassen und Merkmale.'),
    (Title: 'ABB - Artikelstammdaten (BMEcat, ETIM 9)';
     Url: 'https://new.abb.com/low-voltage/de/produkte/innovative-kabelmanagement-systeme/artikelstammdaten';
     Text: 'Elektro/Kabelmanagement. Elektronischer Katalog im Format BMEcat 2005 ' +
       'mit ETIM-9-Klassifikation, Artikeln, Merkmalswerten und Bildverweisen sowie ' +
       'eine Excel-Preisliste. Als direkter Download angeboten; eine Anmeldung wird ' +
       'auf der Seite nicht erwaehnt.'),
    (Title: 'ASSMANN / DIGITUS - Artikelstammdaten (BMEcat, ETIM 10)';
     Url: 'https://www.assmann.com/en/services-tools/article-master-data/';
     Text: 'IT-Verkabelung und Zubehoer. BMEcat-XML (ca. 13 MB) mit Artikeln, ' +
       'nach ETIM 10 klassifiziert, dazu Datenblatt- und Bildpakete (ca. 8 GB) und ' +
       'eine Excel-Uebersicht. Direkte Download-Links; Kosten oder Anmeldung werden ' +
       'auf der Seite nicht genannt.'),
    (Title: 'Weidmueller - Engineering-Daten (eCAD, CAD)';
     Url: 'https://www.weidmueller.de/de/service/engineering_daten.jsp';
     Text: 'Reihenklemmen und Elektrik. Die Seite nennt eCAD-Daten, STEP/DXF/DWG ' +
       'und ECLASS Advanced; ETIM/BMEcat werden dort nicht erwaehnt. Daher eher ' +
       'Quelle fuer CAD-Modelle als fuer ETIM-Daten. Teilweise Drittportale.'),
    (Title: 'Siemens - SiePortal Stammdaten-Download (nicht geprueft)';
     Url: 'https://assets.new.siemens.com/siemens/assets/api/uuid:150b578d-43f3-4e74-be27-e8b6d7d0a269/SiePortal-Stammdatendownload.pdf';
     Text: 'Anleitung zum Stammdaten-Download im SiePortal. Ich habe Inhalt, ' +
       'Formate und Zugangsbedingungen nicht geprueft; vermutlich ist eine ' +
       'Anmeldung erforderlich.'),
    (Title: 'Busch-Jaeger - Stammdaten (nicht geprueft)';
     Url: 'https://www.busch-jaeger.de/at/fuer-profis/service-tools/stammdaten';
     Text: 'Installationstechnik. Die Seite liess sich beim Test nicht abrufen; ' +
       'Formate und Bedingungen sind ungeprueft.')
  );

var
  DsList: TListBox;
  DsMemo: TMemo;

procedure TMainForm.DsSelect(Sender: TObject);
begin
  if (DsList = nil) or (DsMemo = nil) then Exit;
  if DsList.ItemIndex < 0 then
    DsMemo.Text := ''
  else
    DsMemo.Text := DataSrcs[DsList.ItemIndex].Text + LineEnding + LineEnding +
      DataSrcs[DsList.ItemIndex].Url;
end;

procedure TMainForm.DsOpen(Sender: TObject);
begin
  if (DsList = nil) or (DsList.ItemIndex < 0) then
  begin
    ShowMessage('Bitte eine Quelle in der Liste waehlen.');
    Exit;
  end;
  OpenURL(DataSrcs[DsList.ItemIndex].Url);
end;

procedure TMainForm.MnuDataSources(Sender: TObject);
var
  F: TForm;
  PB: TPanel;
  InfoLbl: TLabel;
  I: Integer;
begin
  F := TForm.CreateNew(Self);
  try
    F.Caption := 'Datenquellen im Internet (ETIM)';
    F.Position := poScreenCenter;
    F.Width := 860;
    F.Height := 560;
    RememberDialog(F, 'Datenquellen');

    PB := DlgToolbar(F);
    DlgTB(PB, 38, 'Seite im Browser öffnen' + LineEnding +
      'Öffnet die Seite der gewählten Quelle (Doppelklick geht auch)', @DsOpen);
    DlgTBClose(PB);

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 60;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.WordWrap := True;
    InfoLbl.Caption := 'Quellen mit frei abrufbaren ETIM-Daten (Stand der Recherche ' +
      'Oktober 2026). ETIM deckt vor allem Elektro, Haustechnik und Bau ab; ' +
      'Modellbau-Mechanik ist dort kaum enthalten. Die Nutzungsbedingungen bitte auf ' +
      'der jeweiligen Seite pruefen. Ein Import der heruntergeladenen Dateien ' +
      '(ETIM IXF, BMEcat) ist noch nicht eingebaut.';

    DsMemo := TMemo.Create(F);
    DsMemo.Parent := F;
    DsMemo.Align := alBottom;
    DsMemo.Height := 190;
    DsMemo.ReadOnly := True;
    DsMemo.WordWrap := True;
    DsMemo.ScrollBars := ssAutoVertical;

    DsList := TListBox.Create(F);
    DsList.Parent := F;
    DsList.Align := alClient;
    for I := 0 to High(DataSrcs) do DsList.Items.Add(DataSrcs[I].Title);
    DsList.OnClick := @DsSelect;
    DsList.OnDblClick := @DsOpen;
    DsList.ItemIndex := 0;
    DsSelect(nil);
    F.ShowModal;
  finally
    DsList := nil;
    DsMemo := nil;
    F.Free;
  end;
end;

procedure TMainForm.BtnSuppliers(Sender: TObject);
var
  F: TForm;
  PB: TPanel;
  InfoLbl: TLabel;

begin
  F := TForm.CreateNew(Self);
  try
    F.Caption := 'Lieferanten';
    F.Position := poScreenCenter;
    F.Width := 700;
    F.Height := 420;
    RememberDialog(F, 'Lieferanten');

    PB := DlgToolbar(F);
    DlgTB(PB, 28, 'Neuer Lieferant', @SupNew);
    DlgTB(PB, 29, 'Lieferant ändern', @SupEdit);
    DlgTB(PB, 30, 'Lieferant löschen', @SupDel);
    DlgTBSep(PB);
    DlgTB(PB, 31, 'Als Standard-Lieferant festlegen' + LineEnding +
      'Wird für neue Klassen, Merkmale und Teile verwendet', @SupDefault);
    DlgTBClose(PB);

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 60;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.Caption := 'Der Standard-Lieferant wird fuer neu angelegte Klassen, ' +
      'Merkmale und Teile verwendet. BSU = Lieferant/Code#Version.';
    InfoLbl.WordWrap := True;

    SupList := TListBox.Create(F);
    SupList.Parent := F;
    SupList.Align := alClient;
    SupRefresh;
    F.ShowModal;
  finally
    SupList := nil;
    F.Free;
  end;
  LoadTree(0);
end;

procedure TMainForm.SupRefresh;
var
  Q: TSQLQuery;
  n, Sel: Integer;
  S: string;
begin
  if SupList = nil then Exit;
  Sel := SupList.ItemIndex;
  SupIds := nil;
  n := 0;
  SupList.Items.BeginUpdate;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT id, code, name, is_default FROM supplier ORDER BY code';
    Q.Open;
    SupList.Items.Clear;
    while not Q.EOF do
    begin
      SetLength(SupIds, n + 1);
      SupIds[n] := Q.Fields[0].AsLargeInt;
      S := FieldText(Q.Fields[1]) + ' - ' + FieldText(Q.Fields[2]);
      if Q.Fields[3].AsInteger <> 0 then S := S + '   [Standard]';
      SupList.Items.Add(S);
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
    SupList.Items.EndUpdate;
  end;
  if Sel >= SupList.Items.Count then Sel := SupList.Items.Count - 1;
  if (Sel < 0) and (SupList.Items.Count > 0) then Sel := 0;
  SupList.ItemIndex := Sel;
end;

procedure TMainForm.SupNew(Sender: TObject);
var
  V: TStrArr;
  i: Integer;
begin
  SetLength(V, 6);
  if not EditFields('Neuer Lieferant',
    ['Code (eindeutig, z. B. DE-4711):', 'Name:',
     'ICD nach ISO/IEC 6523 (4 Ziffern, optional):', 'Organisations-ID (OI, optional):',
     'Organisationsteil (OPI, optional):', 'Woerterbuch-Kennung (DI, optional):'],
    ['text', 'text', 'text', 'text', 'text', 'text'], V) then Exit;
  for i := 0 to 5 do V[i] := Trim(V[i]);
  if (V[0] = '') or (V[1] = '') then
  begin
    ShowMessage('Code und Name muessen ausgefuellt sein.');
    Exit;
  end;
  if not ValidIcd(V[2]) then
  begin
    ShowMessage('Der ICD besteht aus genau 4 Ziffern.');
    Exit;
  end;
  if CodeTaken('supplier', V[0], 0) then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist schon vergeben.');
    Exit;
  end;
  Exec(Format('INSERT INTO supplier(code,name,icd,org_id,opi,dict_id) VALUES(%s,%s,%s,%s,%s,%s)',
    [QuotedStr(V[0]), QuotedStr(V[1]), QuotedStr(V[2]), QuotedStr(V[3]),
     QuotedStr(V[4]), QuotedStr(V[5])]));
  SupRefresh;
end;

procedure TMainForm.SupEdit(Sender: TObject);
var
  Idx, i: Integer;
  Id: Int64;
  V: TStrArr;
begin
  Idx := SupList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte einen Lieferanten in der Liste waehlen.');
    Exit;
  end;
  Id := SupIds[Idx];
  SetLength(V, 6);
  V[0] := RowStr('supplier', 'code', Id);
  V[1] := RowStr('supplier', 'name', Id);
  V[2] := RowStr('supplier', 'icd', Id);
  V[3] := RowStr('supplier', 'org_id', Id);
  V[4] := RowStr('supplier', 'opi', Id);
  V[5] := RowStr('supplier', 'dict_id', Id);
  if not EditFields('Lieferant aendern',
    ['Code:', 'Name:', 'ICD nach ISO/IEC 6523 (4 Ziffern, optional):',
     'Organisations-ID (OI, optional):', 'Organisationsteil (OPI, optional):',
     'Woerterbuch-Kennung (DI, optional):'],
    ['text', 'text', 'text', 'text', 'text', 'text'], V) then Exit;
  for i := 0 to 5 do V[i] := Trim(V[i]);
  if (V[0] = '') or (V[1] = '') then Exit;
  if not ValidIcd(V[2]) then
  begin
    ShowMessage('Der ICD besteht aus genau 4 Ziffern.');
    Exit;
  end;
  if CodeTaken('supplier', V[0], Id) then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist schon vergeben.');
    Exit;
  end;
  Exec(Format('UPDATE supplier SET code=%s, name=%s, icd=%s, org_id=%s, opi=%s, dict_id=%s ' +
    'WHERE id=%d',
    [QuotedStr(V[0]), QuotedStr(V[1]), QuotedStr(V[2]), QuotedStr(V[3]),
     QuotedStr(V[4]), QuotedStr(V[5]), Id]));
  SupRefresh;
end;

procedure TMainForm.SupDel(Sender: TObject);
var
  Idx: Integer;
  Id, InUse: Int64;
begin
  Idx := SupList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte einen Lieferanten in der Liste waehlen.');
    Exit;
  end;
  Id := SupIds[Idx];
  if ScalarInt('SELECT COUNT(*) FROM supplier') <= 1 then
  begin
    ShowMessage('Der letzte Lieferant kann nicht geloescht werden.');
    Exit;
  end;
  InUse := ScalarInt('SELECT (SELECT COUNT(*) FROM class WHERE supplier_id=' + IntToStr(Id) +
    ') + (SELECT COUNT(*) FROM property WHERE supplier_id=' + IntToStr(Id) +
    ') + (SELECT COUNT(*) FROM part WHERE supplier_id=' + IntToStr(Id) + ')');
  if InUse > 0 then
  begin
    ShowMessage('Dieser Lieferant wird noch von ' + IntToStr(InUse) +
      ' Klasse(n), Merkmal(en) oder Teil(en) verwendet. ' +
      'Ordne diese zuerst einem anderen Lieferanten zu.');
    Exit;
  end;
  if MessageDlg('Lieferant wirklich loeschen?', mtConfirmation,
    [mbYes, mbNo], 0) <> mrYes then Exit;
  Exec('DELETE FROM supplier WHERE id=' + IntToStr(Id));
  SupRefresh;
end;

procedure TMainForm.SupDefault(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := SupList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte einen Lieferanten in der Liste waehlen.');
    Exit;
  end;
  Exec('UPDATE supplier SET is_default=0');
  Exec('UPDATE supplier SET is_default=1 WHERE id=' + IntToStr(SupIds[Idx]));
  SupRefresh;
end;

{ ---------- Suche ---------- }

function TMainForm.SelectClass(AId: Int64): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Tree.Items.Count - 1 do
    if Int64(PtrUInt(Tree.Items[i].Data{%H-})) = AId then
    begin
      Tree.Selected := Tree.Items[i];
      Result := True;
      Exit;
    end;
end;

{ Laedt alle durchsuchbaren Daten (Teile, Klassen, Merkmale) in den Speicher }
procedure TMainForm.SearchLoad;
var
  Q: TSQLQuery;
  n, NParts, NClsEnd, PIdx, m, k, Kd, uc: Integer;
  PartNo, Desc, CName, CCode, SCode, Nm, Code, Un, Df: string;
  PId, Rid: Int64;
begin
  SrchItems := nil;
  n := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;

    // Teile werden nicht mehr geladen: dafuer gibt es die Teilesuche (BtnPartSearch)
    NParts := 0;

    // Klassen
    Q.SQL.Text := 'SELECT c.id, c.code, c.name, COALESCE(c.definition,''''), ' +
      'COALESCE(s.code,''?''), c.version, ' + IdSql('c') + ', ' +
      'COALESCE(c.short_name,''''), COALESCE(c.synonyms,''''), ' +
      'COALESCE(c.class_no,'''') FROM class c ' +
      'LEFT JOIN supplier s ON s.id=c.supplier_id ORDER BY c.id';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(SrchItems, n + 1);
      Code := FieldText(Q.Fields[1]);
      Nm := FieldText(Q.Fields[2]);
      Df := FieldText(Q.Fields[3]);
      SCode := FieldText(Q.Fields[4]);
      SrchItems[n].Kind := 1;
      SrchItems[n].Id := Q.Fields[0].AsLargeInt;
      SrchItems[n].Display := '[Klasse] ' + FieldText(Q.Fields[9]) + '  ' + Code +
        ' - ' + Nm + '   <' + FieldText(Q.Fields[6]) + '>';
      AddFld(SrchItems[n], FieldText(Q.Fields[9]), 30);
      AddFld(SrchItems[n], Code, 30);
      AddFld(SrchItems[n], Nm, 25);
      AddFld(SrchItems[n], SCode + '/' + Code, 20);
      AddFld(SrchItems[n], Df, 10);
      AddFld(SrchItems[n], FieldText(Q.Fields[7]), 25);
      AddFld(SrchItems[n], FieldText(Q.Fields[8]), 20);
      Inc(n);
      Q.Next;
    end;
    Q.Close;
    NClsEnd := n;

    // Suchbegriffe des Klassenvorschlags finden auch die Klasse
    Q.SQL.Text := 'SELECT class_id, term FROM search_term';
    Q.Open;
    while not Q.EOF do
    begin
      Rid := Q.Fields[0].AsLargeInt;
      for k := NParts to NClsEnd - 1 do
        if SrchItems[k].Id = Rid then
        begin
          AddFld(SrchItems[k], FieldText(Q.Fields[1]), 20);
          Break;
        end;
      Q.Next;
    end;
    Q.Close;

    // Merkmale
    Q.SQL.Text := 'SELECT p.id, p.code, p.name, COALESCE(p.unit,''''), ' +
      'COALESCE(s.code,''?''), p.version, ' + IdSql('p') + ', ' +
      'COALESCE(p.short_name,''''), COALESCE(p.synonyms,'''') FROM property p ' +
      'LEFT JOIN supplier s ON s.id=p.supplier_id ORDER BY p.id';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(SrchItems, n + 1);
      Code := FieldText(Q.Fields[1]);
      Nm := FieldText(Q.Fields[2]);
      Un := FieldText(Q.Fields[3]);
      SCode := FieldText(Q.Fields[4]);
      SrchItems[n].Kind := 2;
      SrchItems[n].Id := Q.Fields[0].AsLargeInt;
      SrchItems[n].Display := '[Merkmal] ' + Nm;
      if Un <> '' then SrchItems[n].Display := SrchItems[n].Display + ' [' + Un + ']';
      SrchItems[n].Display := SrchItems[n].Display + ' (' + Code + ')   <' +
        FieldText(Q.Fields[6]) + '>';
      AddFld(SrchItems[n], Code, 30);
      AddFld(SrchItems[n], Nm, 25);
      AddFld(SrchItems[n], SCode + '/' + Code, 20);
      AddFld(SrchItems[n], Un, 5);
      AddFld(SrchItems[n], FieldText(Q.Fields[7]), 25);
      AddFld(SrchItems[n], FieldText(Q.Fields[8]), 20);
      Inc(n);
      Q.Next;
    end;
    Q.Close;

    // Uebersetzungen als zusaetzliche Suchfelder
    Q.SQL.Text := 'SELECT kind, ref_id, COALESCE(name,''''), COALESCE(definition,'''') ' +
      'FROM translation';
    Q.Open;
    while not Q.EOF do
    begin
      if FieldText(Q.Fields[0]) = 'class' then Kd := 1
      else if FieldText(Q.Fields[0]) = 'property' then Kd := 2
      else Kd := -1;
      Rid := Q.Fields[1].AsLargeInt;
      if Kd > 0 then
        for k := NParts to n - 1 do
          if (SrchItems[k].Kind = Kd) and (SrchItems[k].Id = Rid) then
          begin
            AddFld(SrchItems[k], FieldText(Q.Fields[2]), 25);
            AddFld(SrchItems[k], FieldText(Q.Fields[3]), 8);
            Break;
          end;
      Q.Next;
    end;
    Q.Close;

    // Einheiten fuer Filter mit Umrechnung (laenge>=0,04m)
    GUnits := nil;
    uc := 0;
    Q.SQL.Text := 'SELECT code, quantity, factor, shift FROM unit';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(GUnits, uc + 1);
      GUnits[uc].Code := FieldText(Q.Fields[0]);
      GUnits[uc].Quantity := FieldText(Q.Fields[1]);
      GUnits[uc].Factor := Q.Fields[2].AsFloat;
      GUnits[uc].Shift := Q.Fields[3].AsFloat;
      Inc(uc);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

{ Fuehrt die Suche aus: alle Woerter muessen passen (UND), Treffer werden nach
  Trefferguete und Feldgewicht sortiert, Filter wirken auf Merkmalswerte von Teilen }
procedure TMainForm.SearchRun(Sender: TObject);
var
  Terms: TStrArr;
  Filt: TFilterArr;
  Q: string;
  i, j, k, Total, Best, Sc, Lim: Integer;
  Ok: Boolean;
  Keys: TStringList;
begin
  if SrchList = nil then Exit;
  Q := Fold(Trim(SrchEdit.Text));
  SrchList.Items.BeginUpdate;
  try
    SrchList.Items.Clear;
    SrchHits := nil;
    if Q = '' then
    begin
      SrchInfo.Caption := 'Suchbegriff eingeben ...';
      Exit;
    end;
    ParseQuery(Q, Terms, Filt);
    Keys := TStringList.Create;
    try
      for i := 0 to High(SrchItems) do
      begin
        if (Length(Filt) > 0) and (SrchItems[i].Kind <> 0) then Continue;
        Total := 0;
        Ok := True;
        for j := 0 to High(Terms) do
        begin
          Best := 0;
          for k := 0 to High(SrchItems[i].Fields) do
          begin
            Sc := TokenScore(Terms[j], SrchItems[i].Fields[k].Text) *
              SrchItems[i].Fields[k].Weight;
            if Sc > Best then Best := Sc;
          end;
          if Best = 0 then
          begin
            Ok := False;
            Break;
          end;
          Inc(Total, Best);
        end;
        if not Ok then Continue;
        for j := 0 to High(Filt) do
          if not FilterPass(SrchItems[i], Filt[j]) then
          begin
            Ok := False;
            Break;
          end;
        if not Ok then Continue;
        if Length(Terms) = 0 then Total := 1000;
        Keys.Add(Format('%.9d|%s|%d', [999999999 - Total, SrchItems[i].Display, i]));
      end;
      Keys.Sort;
      Lim := Keys.Count;
      if Lim > 300 then Lim := 300;
      SetLength(SrchHits, Lim);
      for i := 0 to Lim - 1 do
      begin
        j := StrToInt(Copy(Keys[i], LastDelimiter('|', Keys[i]) + 1, 12));
        SrchHits[i] := j;
        SrchList.Items.Add(SrchItems[j].Display);
      end;
      if Keys.Count = 0 then
        SrchInfo.Caption := 'Keine Treffer'
      else if Keys.Count > Lim then
        SrchInfo.Caption := IntToStr(Keys.Count) + ' Treffer (die ersten ' +
          IntToStr(Lim) + ' werden gezeigt)'
      else
        SrchInfo.Caption := IntToStr(Keys.Count) + ' Treffer';
    finally
      Keys.Free;
    end;
  finally
    SrchList.Items.EndUpdate;
  end;
  if SrchList.Items.Count > 0 then SrchList.ItemIndex := 0;
end;

procedure TMainForm.SearchPick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := SrchList.ItemIndex;
  if (Idx < 0) or (Idx > High(SrchHits)) then Exit;
  SrchPickIdx := SrchHits[Idx];
  SrchForm.ModalResult := mrOk;
end;

procedure TMainForm.SearchKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if SrchList.Items.Count = 0 then Exit;
  if Key = VK_DOWN then
  begin
    if SrchList.ItemIndex < SrchList.Items.Count - 1 then
      SrchList.ItemIndex := SrchList.ItemIndex + 1;
    Key := 0;
  end
  else if Key = VK_UP then
  begin
    if SrchList.ItemIndex > 0 then SrchList.ItemIndex := SrchList.ItemIndex - 1;
    Key := 0;
  end;
end;

procedure TMainForm.SearchKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    SearchPick(nil);
  end;
end;

procedure TMainForm.SearchGoto(AIdx: Integer);
var
  It: TSearchItem;
  Cid: Int64;
begin
  It := SrchItems[AIdx];
  case It.Kind of
    0: begin
         SelectClass(It.ClassId);
         LoadParts;
         SelectPart(It.Id);
       end;
    1: SelectClass(It.Id);
    2: begin
         Cid := ScalarInt('SELECT class_id FROM class_property WHERE property_id=' +
           IntToStr(It.Id) + ' ORDER BY class_id LIMIT 1');
         if (Cid = 0) or (not SelectClass(Cid)) then
           ShowMessage('Das Merkmal ist keiner Klasse zugeordnet (nur im Katalog).')
         else
           ShowMessage('Das Merkmal wird verwendet in Klasse: ' + Tree.Selected.Text);
       end;
  end;
end;

procedure TMainForm.BtnSearch(Sender: TObject);
var
  F: TForm;
  PT, PB: TPanel;
  InfoLbl: TLabel;
  Res: Integer;
begin
  SearchLoad;
  SrchPickIdx := -1;
  Res := mrCancel;
  F := TForm.CreateNew(Self);
  SrchForm := F;
  try
    F.Caption := 'Suche';
    F.Position := poScreenCenter;
    F.Width := 900;
    F.Height := 560;
    RememberDialog(F, 'Suche');

    PB := DlgToolbar(F);
    DlgTB(PB, 38, 'Treffer im Hauptfenster anzeigen' + LineEnding +
      'Alternativ Enter oder Doppelklick', @SearchPick);
    DlgTBClose(PB);

    SrchInfo := TLabel.Create(F);
    SrchInfo.Parent := PB;
    SrchInfo.Left := PB.Tag + 16;
    SrchInfo.Top := 20;
    SrchInfo.Caption := 'Suchbegriff eingeben ...';

    PT := TPanel.Create(F);
    PT.Parent := F;
    PT.Align := alTop;
    PT.Top := 60;
    PT.Height := 36;
    PT.BevelOuter := bvNone;
    PT.Caption := '';

    SrchEdit := TEdit.Create(F);
    SrchEdit.Parent := PT;
    SrchEdit.Align := alClient;
    SrchEdit.BorderSpacing.Around := 4;
    SrchEdit.OnChange := @SearchRun;
    SrchEdit.OnKeyDown := @SearchKeyDown;
    SrchEdit.OnKeyPress := @SearchKeyPress;

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 100;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.WordWrap := True;
    InfoLbl.Caption := 'Sucht in Klassen und Merkmalen (Teile findest du mit der ' +
      'Teilesuche, Strg+F). Mehrere Woerter muessen alle passen. Umlaute und ' +
      'Gross-/Kleinschreibung sind egal, kleine Tippfehler werden toleriert. ' +
      'Enter oder Doppelklick zeigt den Treffer im Hauptfenster.';

    SrchList := TListBox.Create(F);
    SrchList.Parent := F;
    SrchList.Align := alClient;
    SrchList.OnDblClick := @SearchPick;

    F.ActiveControl := SrchEdit;
    Res := F.ShowModal;
  finally
    SrchEdit := nil;
    SrchList := nil;
    SrchInfo := nil;
    SrchForm := nil;
    F.Free;
  end;
  if (Res = mrOk) and (SrchPickIdx >= 0) then SearchGoto(SrchPickIdx);
end;

{ ---------- Stufe 1: Kennungen, Namen, Einheiten, Aufzaehlungen ---------- }

{ SQL-Ausdruck fuer die Kennung eines Elements (Alias ihrer Tabelle, Lieferant = s):
  kurz = Lieferant/Code#Version, IRDI = ICD/OI/OPI//DI#Code#Version }
function TMainForm.IdSql(const AAlias: string): string;
begin
  if FIrdi then
    Result := 'COALESCE(s.icd,'''') || ''/'' || COALESCE(s.org_id,'''') || ''/'' || ' +
      'COALESCE(s.opi,'''') || ''//'' || COALESCE(s.dict_id,'''') || ''#'' || ' +
      AAlias + '.code || ''#'' || ' + Pad3Sql(AAlias + '.version')
  else
    Result := 'COALESCE(s.code,''?'') || ''/'' || ' + AAlias + '.code || ''#'' || ' +
      AAlias + '.version';
end;

{ Verknuepft die Einheit eines Merkmals mit dem Einheitenverzeichnis }
procedure TMainForm.SyncUnitId(AProp: Int64);
begin
  Exec(Format('UPDATE property SET unit_id=(SELECT id FROM unit WHERE unit.code=property.unit) ' +
    'WHERE id=%d', [AProp]));
end;

procedure TMainForm.SeedUnits;

  procedure U(const ACode, AName, AQty, AFactor, AShift: string);
  begin
    Exec(InsIgnoreSql('unit', 'code,name,quantity,factor,shift',
      QuotedStr(ACode) + ',' + QuotedStr(AName) + ',' + QuotedStr(AQty) + ',' +
      AFactor + ',' + AShift));
  end;

begin
  if ScalarInt('SELECT COUNT(*) FROM unit') > 0 then Exit;
  U('m', 'Meter', 'Laenge', '1', '0');
  U('mm', 'Millimeter', 'Laenge', '0.001', '0');
  U('cm', 'Zentimeter', 'Laenge', '0.01', '0');
  U('km', 'Kilometer', 'Laenge', '1000', '0');
  U('in', 'Zoll', 'Laenge', '0.0254', '0');
  U('kg', 'Kilogramm', 'Masse', '1', '0');
  U('g', 'Gramm', 'Masse', '0.001', '0');
  U('t', 'Tonne', 'Masse', '1000', '0');
  U('s', 'Sekunde', 'Zeit', '1', '0');
  U('min', 'Minute', 'Zeit', '60', '0');
  U('h', 'Stunde', 'Zeit', '3600', '0');
  U('N', 'Newton', 'Kraft', '1', '0');
  U('kN', 'Kilonewton', 'Kraft', '1000', '0');
  U('Pa', 'Pascal', 'Druck', '1', '0');
  U('kPa', 'Kilopascal', 'Druck', '1000', '0');
  U('MPa', 'Megapascal', 'Druck', '1000000', '0');
  U('bar', 'Bar', 'Druck', '100000', '0');
  U('K', 'Kelvin', 'Temperatur', '1', '0');
  U(#$C2#$B0 + 'C', 'Grad Celsius', 'Temperatur', '1', '273.15');
  U('rad', 'Radiant', 'Winkel', '1', '0');
  U(#$C2#$B0, 'Grad', 'Winkel', '0.017453292519943', '0');
  U('mm' + #$C2#$B2, 'Quadratmillimeter', 'Flaeche', '0.000001', '0');
  U('cm' + #$C2#$B2, 'Quadratzentimeter', 'Flaeche', '0.0001', '0');
  U('m' + #$C2#$B2, 'Quadratmeter', 'Flaeche', '1', '0');
  U('ml', 'Milliliter', 'Volumen', '0.000001', '0');
  U('l', 'Liter', 'Volumen', '0.001', '0');
  U('m' + #$C2#$B3, 'Kubikmeter', 'Volumen', '1', '0');
  U('Nm', 'Newtonmeter', 'Drehmoment', '1', '0');
  U('W', 'Watt', 'Leistung', '1', '0');
  U('kW', 'Kilowatt', 'Leistung', '1000', '0');
  U('V', 'Volt', 'Spannung', '1', '0');
  U('A', 'Ampere', 'Strom', '1', '0');
end;

{ Ergaenzt aeltere Datenbanken: Einheiten, Aufzaehlungen, Uebersetzungen,
  beschreibende Attribute, Status, Kennungsbestandteile der Lieferanten }
procedure TMainForm.MigrateSchema2;
var
  T: Integer;
  Tbl: string;
begin
  Exec('CREATE TABLE IF NOT EXISTS unit(' +
    'id ' + PkType + ', code TEXT NOT NULL UNIQUE, ' +
    'name TEXT NOT NULL, quantity TEXT NOT NULL DEFAULT '''', ' +
    'factor ' + RealType + ' NOT NULL DEFAULT 1, shift ' + RealType + ' NOT NULL DEFAULT 0)');
  Exec('CREATE TABLE IF NOT EXISTS enum_value(' +
    'id ' + PkType + ', property_id INTEGER NOT NULL, ' +
    'code TEXT NOT NULL, name TEXT NOT NULL, UNIQUE(property_id, code))');
  Exec('CREATE TABLE IF NOT EXISTS translation(' +
    'id ' + PkType + ', kind TEXT NOT NULL, ref_id INTEGER NOT NULL, ' +
    'lang TEXT NOT NULL, name TEXT, definition TEXT, UNIQUE(kind, ref_id, lang))');

  EnsureColumn('supplier', 'icd', 'TEXT');
  EnsureColumn('supplier', 'org_id', 'TEXT');
  EnsureColumn('supplier', 'opi', 'TEXT');
  EnsureColumn('supplier', 'dict_id', 'TEXT');

  for T := 0 to 1 do
  begin
    if T = 0 then Tbl := 'class' else Tbl := 'property';
    EnsureColumn(Tbl, 'short_name', 'TEXT');
    EnsureColumn(Tbl, 'synonyms', 'TEXT');
    EnsureColumn(Tbl, 'note', 'TEXT');
    EnsureColumn(Tbl, 'status', 'TEXT NOT NULL DEFAULT ''in Arbeit''');
    EnsureColumn(Tbl, 'created', 'TEXT');
    EnsureColumn(Tbl, 'modified', 'TEXT');
    Exec('UPDATE ' + Tbl + ' SET created=' + DateSql + ' WHERE created IS NULL');
    Exec('UPDATE ' + Tbl + ' SET modified=' + DateSql + ' WHERE modified IS NULL');
  end;
  EnsureColumn('property', 'unit_id', 'INTEGER');
  EnsureColumn('part', 'cad_path', 'TEXT');

  SeedUnits;
  Exec('UPDATE property SET unit_id=(SELECT id FROM unit WHERE unit.code=property.unit) ' +
    'WHERE unit_id IS NULL AND COALESCE(unit,'''')<>''''');

  // Klassennummer (Format siehe MigrateSchema3)
  Exec('CREATE TABLE IF NOT EXISTS class_image(' +
    'class_id INTEGER PRIMARY KEY, ext TEXT NOT NULL, data ' + BlobType + ' NOT NULL, added TEXT)');
  EnsureColumn('class', 'class_no', 'TEXT');
  Exec('CREATE UNIQUE INDEX IF NOT EXISTS ux_class_no ON class(class_no)');
  MigrateSchema3;
end;

{ Naechste freie Klassennummer unter AParent (0 = Hauptklasse).
  Hauptklassen in Zehnerschritten (10, 20, 30 ...), darunter fortlaufend (01, 02 ...).
  Leer, wenn keine Nummer moeglich ist (4. Ebene erreicht oder alles belegt). }
function TMainForm.NextClassNo(AParent: Int64): string;
var
  Q: TSQLQuery;
  PNo: string;
  Lv, G, Mx, i: Integer;
  Used: array[0..99] of Boolean;
begin
  Result := '';
  PNo := '';
  if AParent = 0 then
    Lv := 1
  else
  begin
    PNo := RowStr('class', 'class_no', AParent);
    if not ValidClassNo(PNo) then Exit;
    Lv := ClassNoLevel(PNo) + 1;
    if Lv > 4 then Exit;
  end;
  for i := 0 to 99 do Used[i] := False;
  Mx := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    if AParent = 0 then
      Q.SQL.Text := 'SELECT class_no FROM class WHERE class_no LIKE ''__.00.00.00'''
    else
      Q.SQL.Text := 'SELECT class_no FROM class WHERE class_no LIKE ' +
        QuotedStr(Copy(PNo, 1, (Lv - 1) * 3) + '%');
    Q.Open;
    while not Q.EOF do
    begin
      G := ClassNoGroup(FieldText(Q.Fields[0]), Lv);
      if (G > 0) and (G <= 99) then
      begin
        Used[G] := True;
        if G > Mx then Mx := G;
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  if Lv = 1 then
    G := (Mx div 10 + 1) * 10
  else
    G := Mx + 1;
  if G > 99 then
  begin
    // Luecke suchen
    G := 0;
    for i := 1 to 99 do
      if not Used[i] then
      begin
        G := i;
        Break;
      end;
    if G = 0 then Exit;
  end;
  Result := MakeClassNo(PNo, Lv, G);
end;

{ Prueft eine Klassennummer fuer eine Klasse unter AParent (ASelf = eigene Klasse
  beim Umnummerieren, sonst 0) }
function TMainForm.CheckClassNo(const ANo: string; AParent, ASelf: Int64;
  out AMsg: string): Boolean;
var
  PNo: string;
  Lv: Integer;
begin
  Result := False;
  AMsg := '';
  if not ValidClassNo(ANo) then
  begin
    AMsg := 'Die Klassennummer hat das Format AA.BB.CC.DD, z. B. 10.01.02.00 ' +
      '(je Ebene 01 bis 99, 00 = Ebene nicht belegt, keine Lücken).';
    Exit;
  end;
  Lv := ClassNoLevel(ANo);
  if AParent = 0 then
  begin
    if Lv <> 1 then
    begin
      AMsg := 'Eine Hauptklasse hat eine Nummer der Form AA.00.00.00.';
      Exit;
    end;
  end
  else
  begin
    PNo := RowStr('class', 'class_no', AParent);
    if (ClassNoLevel(PNo) + 1 <> Lv) or
      (Copy(ANo, 1, (Lv - 1) * 3 - 1) <> Copy(PNo, 1, (Lv - 1) * 3 - 1)) then
    begin
      AMsg := 'Die Nummer passt nicht zur Oberklasse ' + PNo + '.' + LineEnding +
        'Sie muss mit ' + Copy(PNo, 1, (Lv - 1) * 3 - 1) + ' beginnen und die ' +
        IntToStr(ClassNoLevel(PNo) + 1) + '. Ebene belegen, z. B. ' +
        NextClassNo(AParent) + '.';
      if ClassNoLevel(PNo) >= 4 then
        AMsg := 'Die Oberklasse liegt schon auf der 4. Ebene, darunter sind keine ' +
          'Unterklassen möglich.';
      Exit;
    end;
  end;
  if ScalarInt('SELECT COUNT(*) FROM class WHERE class_no=' + QuotedStr(ANo) +
    ' AND id<>' + IntToStr(ASelf)) > 0 then
  begin
    AMsg := 'Die Klassennummer ' + ANo + ' ist schon vergeben.';
    Exit;
  end;
  Result := True;
end;

{ vergibt Nummern an Klassen, die noch keine haben (von oben nach unten) }
procedure TMainForm.AssignClassNumbers;
var
  Q: TSQLQuery;
  Ids, Pars: array of Int64;
  n, i, Pass: Integer;
  No: string;
begin
  for Pass := 1 to 5 do
  begin
    Ids := nil;
    Pars := nil;
    n := 0;
    Q := TSQLQuery.Create(nil);
    try
      Q.DataBase := DbCtx.Conn;
      Q.Transaction := DbCtx.Trans;
      Q.SQL.Text := 'SELECT c.id, COALESCE(c.parent_id,0) FROM class c ' +
        'LEFT JOIN class p ON p.id=c.parent_id ' +
        'WHERE COALESCE(c.class_no,'''')='''' AND (c.parent_id IS NULL OR ' +
        'COALESCE(p.class_no,'''')<>'''') ORDER BY c.id';
      Q.Open;
      while not Q.EOF do
      begin
        SetLength(Ids, n + 1);
        SetLength(Pars, n + 1);
        Ids[n] := Q.Fields[0].AsLargeInt;
        Pars[n] := Q.Fields[1].AsLargeInt;
        Inc(n);
        Q.Next;
      end;
      Q.Close;
    finally
      Q.Free;
    end;
    if n = 0 then Exit;
    for i := 0 to n - 1 do
    begin
      No := NextClassNo(Pars[i]);
      if No <> '' then
        Exec(Format('UPDATE class SET class_no=%s WHERE id=%d', [QuotedStr(No), Ids[i]]));
    end;
  end;
end;

{ Klassennummer AA.BB.CC.DD, Hersteller, Suchbegriffe und Klassenvorschlag }
procedure TMainForm.MigrateSchema3;
var
  Bad: Int64;
begin
  // alte fuenfstellige Nummern durch das neue Schema ersetzen
  if DbCtx.IsPg then
    Bad := ScalarInt('SELECT COUNT(*) FROM class WHERE COALESCE(class_no,'''')<>'''' AND ' +
      'class_no !~ ''^[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2}$''')
  else
    Bad := ScalarInt('SELECT COUNT(*) FROM class WHERE COALESCE(class_no,'''')<>'''' AND ' +
      'class_no NOT GLOB ''[0-9][0-9].[0-9][0-9].[0-9][0-9].[0-9][0-9]''');
  if Bad > 0 then Exec('UPDATE class SET class_no=NULL');
  AssignClassNumbers;

  EnsureColumn('part', 'manufacturer', 'TEXT');
  EnsureColumn('part', 'cad_link', 'TEXT');
  EnsureColumn('part', 'alt_nr', 'TEXT');   // fruehere Teilenummer, nur zur Doppelpruefung beim Import
  Exec('CREATE TABLE IF NOT EXISTS search_term(' +
    'id ' + PkType + ', term TEXT NOT NULL, class_id INTEGER NOT NULL, ' +
    'weight INTEGER NOT NULL DEFAULT 10, UNIQUE(term, class_id))');
  Exec('CREATE TABLE IF NOT EXISTS suggest_weight(' +
    'wkey TEXT NOT NULL PRIMARY KEY, points INTEGER NOT NULL, label TEXT)');
  Exec('CREATE TABLE IF NOT EXISTS suggest_history(' +
    'id ' + PkType + ', article_text TEXT, suggested_class_id INTEGER, ' +
    'chosen_class_id INTEGER, created TEXT)');
  // Standardgewichte des Punktesystems (im Programm aenderbar)
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''AEHNLICH'',10,''je ähnlichem Artikel''') );
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''AEHNLICH_MAX'',20,''höchstens so viele ähnliche Artikel zählen''') );
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''NORM'',20,''Übereinstimmung Norm''') );
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''MATERIAL'',15,''Übereinstimmung Werkstoff''') );
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''BEGRIFF'',10,''Übereinstimmung Suchbegriff (mal Gewichtung/10)''') );
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''MERKMAL'',5,''je übereinstimmendem Merkmal''') );
  Exec(InsIgnoreSql('suggest_weight', 'wkey,points,label',
    '''HISTORIE'',10,''Übereinstimmung Klassenhistorie''') );
  // Indizes fuer grosse Datenmengen
  Exec('CREATE INDEX IF NOT EXISTS ix_class_parent ON class(parent_id)');
  Exec('CREATE INDEX IF NOT EXISTS ix_part_class ON part(class_id)');
  Exec('CREATE INDEX IF NOT EXISTS ix_part_manu ON part(manufacturer)');
  Exec('CREATE INDEX IF NOT EXISTS ix_part_no ON part(part_number)');
  Exec('CREATE INDEX IF NOT EXISTS ix_pv_prop ON part_value(property_id, value)');
  Exec('CREATE INDEX IF NOT EXISTS ix_st_term ON search_term(term)');
  Exec('CREATE INDEX IF NOT EXISTS ix_st_class ON search_term(class_id)');
  Exec('CREATE INDEX IF NOT EXISTS ix_hist_chosen ON suggest_history(chosen_class_id)');
end;

{ ---------- Beschreibung, Status, Uebersetzung ---------- }

procedure TMainForm.BtnClassDesc(Sender: TObject);
var
  Cid: Int64;
  V, Old: TStrArr;
  i: Integer;
  AnyChange, Bump: Boolean;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  SetLength(V, 5);
  SetLength(Old, 5);
  V[0] := RowStr('class', 'short_name', Cid);
  V[1] := RowStr('class', 'synonyms', Cid);
  V[2] := RowStr('class', 'definition', Cid);
  V[3] := RowStr('class', 'note', Cid);
  V[4] := RowStr('class', 'status', Cid);
  for i := 0 to 4 do Old[i] := V[i];
  if not EditFields('Beschreibung der Klasse ' + Tree.Selected.Text,
    ['Kurzname:', 'Synonyme (mit ; trennen):', 'Definition:', 'Anmerkung:', 'Status:'],
    ['text', 'text', 'memo', 'memo', 'combo:in Arbeit;freigegeben;veraltet'], V) then Exit;
  AnyChange := False;
  for i := 0 to 3 do
    if V[i] <> Old[i] then AnyChange := True;
  // freigegebene Elemente: inhaltliche Aenderung erzwingt eine neue Version
  Bump := AnyChange and (Old[4] = 'freigegeben') and (V[4] = 'freigegeben');
  Exec(Format('UPDATE class SET short_name=%s, synonyms=%s, definition=%s, note=%s, ' +
    'status=%s, modified=' + DateSql + ', version=version+%d WHERE id=%d',
    [QuotedStr(Trim(V[0])), QuotedStr(Trim(V[1])), QuotedStr(Trim(V[2])),
     QuotedStr(Trim(V[3])), QuotedStr(V[4]), Ord(Bump), Cid]));
  if Bump then
    ShowMessage('Die Klasse war freigegeben. Ihre Version wurde auf ' +
      RowStr('class', 'version', Cid) + ' erhoeht.');
  LoadTree(Cid);
end;

procedure TMainForm.DescProp(AProp: Int64);
var
  V, Old: TStrArr;
  i: Integer;
  AnyChange, Bump: Boolean;
begin
  SetLength(V, 5);
  SetLength(Old, 5);
  V[0] := RowStr('property', 'short_name', AProp);
  V[1] := RowStr('property', 'synonyms', AProp);
  V[2] := RowStr('property', 'definition', AProp);
  V[3] := RowStr('property', 'note', AProp);
  V[4] := RowStr('property', 'status', AProp);
  for i := 0 to 4 do Old[i] := V[i];
  if not EditFields('Beschreibung des Merkmals ' + RowStr('property', 'name', AProp),
    ['Kurzname:', 'Synonyme (mit ; trennen):', 'Definition:', 'Anmerkung:', 'Status:'],
    ['text', 'text', 'memo', 'memo', 'combo:in Arbeit;freigegeben;veraltet'], V) then Exit;
  AnyChange := False;
  for i := 0 to 3 do
    if V[i] <> Old[i] then AnyChange := True;
  Bump := AnyChange and (Old[4] = 'freigegeben') and (V[4] = 'freigegeben');
  Exec(Format('UPDATE property SET short_name=%s, synonyms=%s, definition=%s, note=%s, ' +
    'status=%s, modified=' + DateSql + ', version=version+%d WHERE id=%d',
    [QuotedStr(Trim(V[0])), QuotedStr(Trim(V[1])), QuotedStr(Trim(V[2])),
     QuotedStr(Trim(V[3])), QuotedStr(V[4]), Ord(Bump), AProp]));
  if Bump then
    ShowMessage('Das Merkmal war freigegeben. Seine Version wurde auf ' +
      RowStr('property', 'version', AProp) + ' erhoeht.');
end;

procedure TMainForm.EditTranslation(const AKind: string; ARefId: Int64;
  const ABase: string);
var
  Lang, Filt: string;
  V: TStrArr;
begin
  Lang := DbCtx.Lang;
  if Lang = '' then Lang := 'en';
  if not InputQuery('Uebersetzung', 'Sprachcode fuer "' + ABase +
    '" (z. B. en, fr, es):', Lang) then Exit;
  Lang := LowerCase(Trim(Lang));
  if (Length(Lang) < 2) or (Length(Lang) > 8) then
  begin
    ShowMessage('Bitte einen Sprachcode mit 2 bis 8 Zeichen angeben.');
    Exit;
  end;
  Filt := Format('kind=%s AND ref_id=%d AND lang=%s',
    [QuotedStr(AKind), ARefId, QuotedStr(Lang)]);
  SetLength(V, 2);
  V[0] := ScalarStr('SELECT COALESCE(name,'''') FROM translation WHERE ' + Filt);
  V[1] := ScalarStr('SELECT COALESCE(definition,'''') FROM translation WHERE ' + Filt);
  if not EditFields('Uebersetzung (' + Lang + ') von ' + ABase,
    ['Name:', 'Definition:'], ['text', 'memo'], V) then Exit;
  Exec('DELETE FROM translation WHERE ' + Filt);
  if (Trim(V[0]) <> '') or (Trim(V[1]) <> '') then
    Exec(Format('INSERT INTO translation(kind,ref_id,lang,name,definition) VALUES(%s,%d,%s,%s,%s)',
      [QuotedStr(AKind), ARefId, QuotedStr(Lang), QuotedStr(Trim(V[0])),
       QuotedStr(Trim(V[1]))]));
end;

procedure TMainForm.BtnClassTrans(Sender: TObject);
var
  Cid: Int64;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  EditTranslation('class', Cid, RowStr('class', 'name', Cid));
  LoadTree(Cid);
end;

procedure TMainForm.BtnLang(Sender: TObject);
var
  Items, Langs: TStringList;
  Q: TSQLQuery;
  Idx: Integer;
begin
  Items := TStringList.Create;
  Langs := TStringList.Create;
  Q := TSQLQuery.Create(nil);
  try
    Items.Add('Grundsprache (Standard)');
    Langs.Add('');
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT DISTINCT lang FROM translation ORDER BY lang';
    Q.Open;
    while not Q.EOF do
    begin
      Langs.Add(FieldText(Q.Fields[0]));
      Items.Add(Langs[Langs.Count - 1]);
      Q.Next;
    end;
    Q.Close;
    Idx := PickIndex('Datensprache waehlen',
      'Anzeigesprache fuer Namen von Klassen, Merkmalen und Aufzaehlungswerten. ' +
      'Fehlt eine Uebersetzung, wird der Name der Grundsprache gezeigt.',
      Items, Langs.IndexOf(DbCtx.Lang));
    if Idx < 0 then Exit;
    DbCtx.Lang := Langs[Idx];
  finally
    Q.Free;
    Items.Free;
    Langs.Free;
  end;
  LoadTree(0);
  LoadValues;
end;

procedure TMainForm.MnuToggleIrdi(Sender: TObject);
begin
  FIrdi := MnuIrdiItem.Checked;
  LoadTree(0);
end;

procedure TMainForm.MnuToggleIds(Sender: TObject);
begin
  FShowIds := MnuShowIdsItem.Checked;
  LoadTree(0);
end;

{ ---------- Dialog: Einheitenverzeichnis ---------- }

procedure TMainForm.BtnUnits(Sender: TObject);
var
  F: TForm;
  PB: TPanel;
  InfoLbl: TLabel;

begin
  F := TForm.CreateNew(Self);
  try
    F.Caption := 'Einheitenverzeichnis';
    F.Position := poScreenCenter;
    F.Width := 700;
    F.Height := 460;
    RememberDialog(F, 'Einheiten');

    PB := DlgToolbar(F);
    DlgTB(PB, 32, 'Neue Einheit', @UnitNew);
    DlgTB(PB, 33, 'Einheit ändern', @UnitEdit);
    DlgTB(PB, 34, 'Einheit löschen', @UnitDel);
    DlgTBClose(PB);

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 60;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.WordWrap := True;
    InfoLbl.Caption := 'Basiswert = Wert * Faktor + Verschiebung. Einheiten gleicher ' +
      'Groessenart lassen sich ineinander umrechnen, z. B. fuer Suchfilter ' +
      '(laenge>=0,04m findet 40 mm). Merkmale verweisen ueber den Einheiten-Code.';

    UnitList := TListBox.Create(F);
    UnitList.Parent := F;
    UnitList.Align := alClient;
    UnitRefresh;
    F.ShowModal;
  finally
    UnitList := nil;
    F.Free;
  end;
  LoadParts;
end;

procedure TMainForm.UnitRefresh;
var
  Q: TSQLQuery;
  n, Sel: Integer;
begin
  if UnitList = nil then Exit;
  Sel := UnitList.ItemIndex;
  UnitIds := nil;
  n := 0;
  UnitList.Items.BeginUpdate;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT id, code, name, quantity, factor, shift FROM unit ' +
      'ORDER BY quantity, factor, code';
    Q.Open;
    UnitList.Items.Clear;
    while not Q.EOF do
    begin
      SetLength(UnitIds, n + 1);
      UnitIds[n] := Q.Fields[0].AsLargeInt;
      UnitList.Items.Add(FieldText(Q.Fields[1]) + ' - ' + FieldText(Q.Fields[2]) +
        '   (' + FieldText(Q.Fields[3]) + ', Faktor ' + FieldText(Q.Fields[4]) +
        ', Verschiebung ' + FieldText(Q.Fields[5]) + ')');
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
    UnitList.Items.EndUpdate;
  end;
  if Sel >= UnitList.Items.Count then Sel := UnitList.Items.Count - 1;
  if (Sel < 0) and (UnitList.Items.Count > 0) then Sel := 0;
  UnitList.ItemIndex := Sel;
end;

procedure TMainForm.UnitNew(Sender: TObject);
var
  V: TStrArr;
  Fct, Sh: Double;
begin
  SetLength(V, 5);
  V[0] := '';
  V[1] := '';
  V[2] := '';
  V[3] := '1';
  V[4] := '0';
  if not EditFields('Neue Einheit',
    ['Code (z. B. mm):', 'Name:', 'Groessenart (z. B. Laenge):',
     'Faktor zur Basiseinheit (SI), z. B. 0.001:', 'Verschiebung (nur Temperaturen), meist 0:'],
    ['text', 'text', 'text', 'text', 'text'], V) then Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  V[2] := Trim(V[2]);
  if (V[0] = '') or (V[1] = '') or (V[2] = '') then
  begin
    ShowMessage('Code, Name und Groessenart muessen ausgefuellt sein.');
    Exit;
  end;
  if not (ParseNum(V[3], Fct) and ParseNum(V[4], Sh)) or (Fct <= 0) then
  begin
    ShowMessage('Faktor (groesser 0) und Verschiebung muessen Zahlen sein.');
    Exit;
  end;
  if CodeTaken('unit', V[0], 0) then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist schon vergeben.');
    Exit;
  end;
  Exec('INSERT INTO unit(code,name,quantity,factor,shift) VALUES(' + QuotedStr(V[0]) + ',' +
    QuotedStr(V[1]) + ',' + QuotedStr(V[2]) + ',' + NumSql(Fct) + ',' + NumSql(Sh) + ')');
  UnitRefresh;
end;

procedure TMainForm.UnitEdit(Sender: TObject);
var
  Idx: Integer;
  Id: Int64;
  V: TStrArr;
  Fct, Sh: Double;
begin
  Idx := UnitList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte eine Einheit in der Liste waehlen.');
    Exit;
  end;
  Id := UnitIds[Idx];
  SetLength(V, 5);
  V[0] := RowStr('unit', 'code', Id);
  V[1] := RowStr('unit', 'name', Id);
  V[2] := RowStr('unit', 'quantity', Id);
  V[3] := RowStr('unit', 'factor', Id);
  V[4] := RowStr('unit', 'shift', Id);
  if not EditFields('Einheit aendern',
    ['Code:', 'Name:', 'Groessenart:', 'Faktor zur Basiseinheit (SI):', 'Verschiebung:'],
    ['text', 'text', 'text', 'text', 'text'], V) then Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  V[2] := Trim(V[2]);
  if (V[0] = '') or (V[1] = '') or (V[2] = '') then Exit;
  if not (ParseNum(V[3], Fct) and ParseNum(V[4], Sh)) or (Fct <= 0) then
  begin
    ShowMessage('Faktor (groesser 0) und Verschiebung muessen Zahlen sein.');
    Exit;
  end;
  if CodeTaken('unit', V[0], Id) then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist schon vergeben.');
    Exit;
  end;
  Exec(Format('UPDATE unit SET code=%s, name=%s, quantity=%s, factor=%s, shift=%s WHERE id=%d',
    [QuotedStr(V[0]), QuotedStr(V[1]), QuotedStr(V[2]), NumSql(Fct), NumSql(Sh), Id]));
  // Merkmale, die diese Einheit verwenden, zeigen den neuen Code
  Exec(Format('UPDATE property SET unit=(SELECT code FROM unit WHERE id=%d) WHERE unit_id=%d',
    [Id, Id]));
  UnitRefresh;
end;

procedure TMainForm.UnitDel(Sender: TObject);
var
  Idx: Integer;
  Id, InUse: Int64;
begin
  Idx := UnitList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte eine Einheit in der Liste waehlen.');
    Exit;
  end;
  Id := UnitIds[Idx];
  InUse := ScalarInt('SELECT COUNT(*) FROM property WHERE unit_id=' + IntToStr(Id));
  if InUse > 0 then
  begin
    ShowMessage('Diese Einheit wird noch von ' + IntToStr(InUse) +
      ' Merkmal(en) verwendet. Aendere zuerst deren Einheit.');
    Exit;
  end;
  if MessageDlg('Einheit wirklich loeschen?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  Exec('DELETE FROM unit WHERE id=' + IntToStr(Id));
  UnitRefresh;
end;

{ ---------- Dialog: Aufzaehlungswerte eines Merkmals ---------- }

procedure TMainForm.ManageEnum(AProp: Int64);
var
  F: TForm;
  PB: TPanel;
  InfoLbl: TLabel;

begin
  EnumProp := AProp;
  F := TForm.CreateNew(Self);
  try
    F.Caption := 'Aufzaehlungswerte von ' + RowStr('property', 'name', AProp);
    F.Position := poScreenCenter;
    F.Width := 640;
    F.Height := 420;
    RememberDialog(F, 'Aufzaehlungswerte');

    PB := DlgToolbar(F);
    DlgTB(PB, 35, 'Neuer Aufzählungswert', @EnumNew);
    DlgTB(PB, 36, 'Wert ändern', @EnumEdit);
    DlgTB(PB, 11, 'Übersetzung', @EnumTrans);
    DlgTB(PB, 37, 'Wert entfernen', @EnumDel);
    DlgTBClose(PB);

    InfoLbl := TLabel.Create(F);
    InfoLbl.Parent := F;
    InfoLbl.Align := alTop;
    InfoLbl.Top := 60;
    InfoLbl.BorderSpacing.Around := 6;
    InfoLbl.WordWrap := True;
    InfoLbl.Caption := 'Erlaubte Werte dieses Merkmals. Bei einem Teil wird der Code ' +
      'gespeichert und der Name angezeigt.';

    EnumList := TListBox.Create(F);
    EnumList.Parent := F;
    EnumList.Align := alClient;
    EnumRefresh;
    F.ShowModal;
  finally
    EnumList := nil;
    F.Free;
  end;
  LoadParts;
end;

procedure TMainForm.EnumRefresh;
var
  Q: TSQLQuery;
  n, Sel: Integer;
begin
  if EnumList = nil then Exit;
  Sel := EnumList.ItemIndex;
  EnumIds := nil;
  n := 0;
  EnumList.Items.BeginUpdate;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT e.id, e.code, ' + NameSql('enum', 'e.id', 'e.name') +
      ' FROM enum_value e WHERE e.property_id=' + IntToStr(EnumProp) + ' ORDER BY e.code';
    Q.Open;
    EnumList.Items.Clear;
    while not Q.EOF do
    begin
      SetLength(EnumIds, n + 1);
      EnumIds[n] := Q.Fields[0].AsLargeInt;
      EnumList.Items.Add(FieldText(Q.Fields[1]) + ' - ' + FieldText(Q.Fields[2]));
      Inc(n);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
    EnumList.Items.EndUpdate;
  end;
  if Sel >= EnumList.Items.Count then Sel := EnumList.Items.Count - 1;
  if (Sel < 0) and (EnumList.Items.Count > 0) then Sel := 0;
  EnumList.ItemIndex := Sel;
end;

procedure TMainForm.EnumNew(Sender: TObject);
var
  V: TStrArr;
begin
  SetLength(V, 2);
  V[0] := '';
  V[1] := '';
  if not EditFields('Neuer Aufzaehlungswert', ['Code (z. B. A2):', 'Name:'],
    ['text', 'text'], V) then Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  if (not ValidCode(V[0])) or (V[1] = '') then
  begin
    ShowMessage('Code (nur Buchstaben, Ziffern, - _ .) und Name muessen ausgefuellt sein.');
    Exit;
  end;
  if ScalarInt(Format('SELECT COUNT(*) FROM enum_value WHERE property_id=%d AND code=%s',
    [EnumProp, QuotedStr(V[0])])) > 0 then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist bei diesem Merkmal schon vergeben.');
    Exit;
  end;
  Exec(Format('INSERT INTO enum_value(property_id,code,name) VALUES(%d,%s,%s)',
    [EnumProp, QuotedStr(V[0]), QuotedStr(V[1])]));
  EnumRefresh;
end;

procedure TMainForm.EnumEdit(Sender: TObject);
var
  Idx: Integer;
  Id: Int64;
  V: TStrArr;
  OldCode: string;
begin
  Idx := EnumList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte einen Wert in der Liste waehlen.');
    Exit;
  end;
  Id := EnumIds[Idx];
  OldCode := RowStr('enum_value', 'code', Id);
  SetLength(V, 2);
  V[0] := OldCode;
  V[1] := RowStr('enum_value', 'name', Id);
  if not EditFields('Aufzaehlungswert aendern', ['Code:', 'Name:'], ['text', 'text'], V) then
    Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  if (not ValidCode(V[0])) or (V[1] = '') then
  begin
    ShowMessage('Code (nur Buchstaben, Ziffern, - _ .) und Name muessen ausgefuellt sein.');
    Exit;
  end;
  if ScalarInt(Format('SELECT COUNT(*) FROM enum_value WHERE property_id=%d AND code=%s AND id<>%d',
    [EnumProp, QuotedStr(V[0]), Id])) > 0 then
  begin
    ShowMessage('Der Code "' + V[0] + '" ist bei diesem Merkmal schon vergeben.');
    Exit;
  end;
  Exec(Format('UPDATE enum_value SET code=%s, name=%s WHERE id=%d',
    [QuotedStr(V[0]), QuotedStr(V[1]), Id]));
  if V[0] <> OldCode then
    Exec(Format('UPDATE part_value SET value=%s WHERE property_id=%d AND value=%s',
      [QuotedStr(V[0]), EnumProp, QuotedStr(OldCode)]));
  EnumRefresh;
end;

procedure TMainForm.EnumTrans(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := EnumList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte einen Wert in der Liste waehlen.');
    Exit;
  end;
  EditTranslation('enum', EnumIds[Idx], RowStr('enum_value', 'name', EnumIds[Idx]));
  EnumRefresh;
end;

procedure TMainForm.EnumDel(Sender: TObject);
var
  Idx: Integer;
  Id, InUse: Int64;
  Code: string;
begin
  Idx := EnumList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte einen Wert in der Liste waehlen.');
    Exit;
  end;
  Id := EnumIds[Idx];
  Code := RowStr('enum_value', 'code', Id);
  InUse := ScalarInt(Format('SELECT COUNT(*) FROM part_value WHERE property_id=%d AND value=%s',
    [EnumProp, QuotedStr(Code)]));
  if MessageDlg('Wert "' + Code + '" entfernen?' + LineEnding + 'Er wird bei ' +
    IntToStr(InUse) + ' Teil(en) verwendet; diese Werte werden geloescht.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Exec(Format('DELETE FROM part_value WHERE property_id=%d AND value=%s',
    [EnumProp, QuotedStr(Code)]));
  Exec(Format('DELETE FROM translation WHERE kind=''enum'' AND ref_id=%d', [Id]));
  Exec(Format('DELETE FROM enum_value WHERE id=%d', [Id]));
  EnumRefresh;
end;

{ ---------- Merkmals-Dialoge: Beschreibung, Uebersetzung, Aufzaehlung ---------- }

procedure TMainForm.DlgDesc(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := DlgList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  DescProp(DlgProps[Idx].Id);
  DlgRefresh;
end;

procedure TMainForm.DlgTrans(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := DlgList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  EditTranslation('property', DlgProps[Idx].Id, DlgProps[Idx].Code);
  DlgRefresh;
end;

procedure TMainForm.DlgEnum(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := DlgList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  if DlgProps[Idx].DataType <> 'enum' then
  begin
    ShowMessage('Aufzaehlungswerte gibt es nur bei Merkmalen vom Datentyp enum.');
    Exit;
  end;
  ManageEnum(DlgProps[Idx].Id);
end;

procedure TMainForm.CatDesc(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CatList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  DescProp(CatProps[Idx].Id);
  CatRefresh;
end;

procedure TMainForm.CatTrans(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CatList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  EditTranslation('property', CatProps[Idx].Id, CatProps[Idx].Code);
  CatRefresh;
end;

procedure TMainForm.CatEnum(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := CatList.ItemIndex;
  if Idx < 0 then
  begin
    ShowMessage('Bitte ein Merkmal in der Liste waehlen.');
    Exit;
  end;
  if CatProps[Idx].DataType <> 'enum' then
  begin
    ShowMessage('Aufzaehlungswerte gibt es nur bei Merkmalen vom Datentyp enum.');
    Exit;
  end;
  ManageEnum(CatProps[Idx].Id);
end;

{ ---------- Musterdaten ---------- }

{ Legt Normteile (Schrauben, Muttern, Scheiben, Bolzen, Stifte) mit Merkmalen,
  Aufzaehlungswerten und Beispielteilen an. Vorhandene Eintraege mit gleichem Code
  bzw. gleicher Teilenummer bleiben unveraendert. }
{ ---------- Klassenbilder aus einem Ordner importieren (Dateiname = Klassencode) ---------- }

procedure TMainForm.MnuImportImages(Sender: TObject);
var
  Dlg: TSelectDirectoryDialog;
  Dir, FName, Ext: string;
  Ids: array of Int64;
  Codes: array of string;
  Q: TSQLQuery;
  Fs: TFileStream;
  Pic: TPicture;
  I, Cnt, Neu, Ersetzt, Uebersprungen, Fehler: Integer;
  Overwrite: Boolean;
  Ans: Integer;
  PF: TForm;
  PBar: TProgressBar;
  PLbl: TLabel;
begin
  Dlg := TSelectDirectoryDialog.Create(Self);
  try
    Dlg.Title := 'Ordner mit den Klassenbildern wählen (Dateiname = Klassencode, z. B. SKS.png)';
    Dir := ExtractFilePath(ParamStr(0)) + 'klassenbilder';
    if DirectoryExists(Dir) then Dlg.InitialDir := Dir;
    if not Dlg.Execute then Exit;
    Dir := IncludeTrailingPathDelimiter(Dlg.FileName);
  finally
    Dlg.Free;
  end;
  Ans := MessageDlg('Sollen Klassen, die schon ein eigenes Bild haben, ein neues Bild bekommen?' +
    LineEnding + LineEnding + 'Ja = vorhandene Bilder ersetzen' + LineEnding +
    'Nein = nur Klassen ohne Bild füllen', mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if Ans = mrCancel then Exit;
  Overwrite := Ans = mrYes;

  // alle Klassen vorab einlesen
  Cnt := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT id, code FROM class ORDER BY id';
    Q.Open;
    while not Q.EOF do
    begin
      SetLength(Ids, Cnt + 1);
      SetLength(Codes, Cnt + 1);
      Ids[Cnt] := Q.Fields[0].AsLargeInt;
      Codes[Cnt] := Q.Fields[1].AsString;
      Inc(Cnt);
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;

  Neu := 0;
  Ersetzt := 0;
  Uebersprungen := 0;
  Fehler := 0;
  PF := TForm.CreateNew(Self);
  PF.BorderStyle := bsDialog;
  PF.BorderIcons := [];
  PF.Position := poOwnerFormCenter;
  PF.Caption := 'Klassenbilder werden importiert ...';
  PF.ClientWidth := 420;
  PF.ClientHeight := 80;
  PLbl := TLabel.Create(PF);
  PLbl.Parent := PF;
  PLbl.SetBounds(16, 12, 388, 18);
  PLbl.Caption := 'Bitte warten ...';
  PBar := TProgressBar.Create(PF);
  PBar.Parent := PF;
  PBar.SetBounds(16, 38, 388, 24);
  PBar.Min := 0;
  PBar.Max := Cnt + 1;
  PF.Show;
  Application.ProcessMessages;
  DbCtx.Batch := True;
  try
    try
      for I := 0 to Cnt - 1 do
      begin
        if (I mod 4) = 0 then
        begin
          PBar.Position := I;
          PLbl.Caption := 'Klasse ' + Codes[I] + ' (' + IntToStr(I + 1) + ' von ' + IntToStr(Cnt) + ')';
          Application.ProcessMessages;
        end;
        FName := '';
        if FileExists(Dir + Codes[I] + '.png') then
          FName := Dir + Codes[I] + '.png'
        else if FileExists(Dir + Codes[I] + '.jpg') then
          FName := Dir + Codes[I] + '.jpg'
        else if FileExists(Dir + Codes[I] + '.jpeg') then
          FName := Dir + Codes[I] + '.jpeg';
        if FName = '' then Continue;
        if (not Overwrite) and
          (ScalarInt('SELECT COUNT(*) FROM class_image WHERE class_id=' + IntToStr(Ids[I])) > 0) then
        begin
          Inc(Uebersprungen);
          Continue;
        end;
        Ext := LowerCase(ExtractFileExt(FName));
        Pic := TPicture.Create;
        try
          try
            Pic.LoadFromFile(FName);
          except
            Inc(Fehler);
            Continue;
          end;
        finally
          Pic.Free;
        end;
        Fs := TFileStream.Create(FName, fmOpenRead or fmShareDenyNone);
        try
          Q := TSQLQuery.Create(nil);
          try
            Q.DataBase := DbCtx.Conn;
            Q.Transaction := DbCtx.Trans;
            if ScalarInt('SELECT COUNT(*) FROM class_image WHERE class_id=' + IntToStr(Ids[I])) > 0 then
            begin
              Q.SQL.Text := 'UPDATE class_image SET ext=:ext, data=:dat, added=' + DateSql +
                ' WHERE class_id=:cid';
              Inc(Ersetzt);
            end
            else
            begin
              Q.SQL.Text := 'INSERT INTO class_image(class_id, ext, data, added) VALUES(:cid, :ext, :dat, ' +
                DateSql + ')';
              Inc(Neu);
            end;
            Q.ParamByName('cid').AsLargeInt := Ids[I];
            Q.ParamByName('ext').AsString := Ext;
            Q.ParamByName('dat').LoadFromStream(Fs, ftBlob);
            Q.ExecSQL;
          finally
            Q.Free;
          end;
        finally
          Fs.Free;
        end;
      end;
      DbCtx.Trans.CommitRetaining;
    except
      DbCtx.Trans.RollbackRetaining;
      raise;
    end;
  finally
    DbCtx.Batch := False;
    PF.Free;
  end;
  UpdateClassImage;
  ShowMessage('Klassenbilder importiert:' + LineEnding +
    IntToStr(Neu) + ' neu zugeordnet, ' + IntToStr(Ersetzt) + ' ersetzt, ' +
    IntToStr(Uebersprungen) + ' übersprungen (hatten schon ein Bild)' +
    LineEnding + IntToStr(Fehler) + ' Datei(en) nicht lesbar.');
end;

{ ---------- Klassenvorschlag: Gewichte und Suchbegriffe ---------- }

procedure TMainForm.BtnSuggestWeights(Sender: TObject);
var
  Q: TSQLQuery;
  Keys, Labels: TStringList;
  V: TStrArr;
  Caps: array of string;
  Specs: array of string;
  i, n, Pts: Integer;
begin
  Keys := TStringList.Create;
  Labels := TStringList.Create;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT wkey, points, COALESCE(label,wkey) FROM suggest_weight ORDER BY wkey';
    Q.Open;
    n := 0;
    while not Q.EOF do
    begin
      Keys.Add(FieldText(Q.Fields[0]));
      Labels.Add(FieldText(Q.Fields[2]));
      SetLength(V, n + 1);
      V[n] := IntToStr(Q.Fields[1].AsInteger);
      Inc(n);
      Q.Next;
    end;
    Q.Close;
    if n = 0 then
    begin
      ShowMessage('Es sind keine Gewichte angelegt.');
      Exit;
    end;
    SetLength(Caps, n);
    SetLength(Specs, n);
    for i := 0 to n - 1 do
    begin
      Caps[i] := Labels[i] + ' (' + Keys[i] + '):';
      Specs[i] := 'text';
    end;
    if not EditFieldsEx('Punkte für den Klassenvorschlag', Caps, Specs, V, 0) then Exit;
    for i := 0 to n - 1 do
    begin
      Pts := StrToIntDef(Trim(V[i]), -1);
      if (Pts < 0) or (Pts > 1000) then
      begin
        ShowMessage('„' + Labels[i] + '": bitte eine ganze Zahl von 0 bis 1000 eingeben.');
        Exit;
      end;
    end;
    DbCtx.Batch := True;
    try
      try
        for i := 0 to n - 1 do
          Exec(Format('UPDATE suggest_weight SET points=%d WHERE wkey=%s',
            [StrToInt(Trim(V[i])), QuotedStr(Keys[i])]));
        DbCtx.Trans.CommitRetaining;
      except
        DbCtx.Trans.RollbackRetaining;
        raise;
      end;
    finally
      DbCtx.Batch := False;
    end;
    ShowStatus('Punkte gespeichert.');
  finally
    Q.Free;
    Labels.Free;
    Keys.Free;
  end;
end;

{ Suchbegriffe der gewaehlten Klasse bearbeiten: eine Zeile je Begriff, optional ";Gewichtung" }
procedure TMainForm.BtnClassTerms(Sender: TObject);
var
  Cid: Int64;
  Q: TSQLQuery;
  V: TStrArr;
  Lines: TStringList;
  Txt, T: string;
  i, Wt, P: Integer;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse wählen.');
    Exit;
  end;
  Txt := '';
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT term, weight FROM search_term WHERE class_id=' + IntToStr(Cid) +
      ' ORDER BY term';
    Q.Open;
    while not Q.EOF do
    begin
      Txt := Txt + FieldText(Q.Fields[0]) + ';' + IntToStr(Q.Fields[1].AsInteger) + LineEnding;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  SetLength(V, 1);
  V[0] := Txt;
  if not EditFieldsEx('Suchbegriffe der Klasse ' + RowStr('class', 'class_no', Cid) + ' ' +
    RowStr('class', 'name', Cid),
    ['Ein Begriff je Zeile, optional mit Gewichtung (Standard 10), z. B. DIN933;20. ' +
     'Der Klassenvorschlag nutzt diese Begriffe:'], ['memo'], V, 0) then Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := V[0];
    DbCtx.Batch := True;
    try
      try
        Exec('DELETE FROM search_term WHERE class_id=' + IntToStr(Cid));
        for i := 0 to Lines.Count - 1 do
        begin
          T := Trim(Lines[i]);
          if T = '' then Continue;
          Wt := 10;
          P := Pos(';', T);
          if P > 0 then
          begin
            Wt := StrToIntDef(Trim(Copy(T, P + 1, MaxInt)), 10);
            T := Trim(Copy(T, 1, P - 1));
          end;
          T := NormText(T);
          if T = '' then Continue;
          if Wt < 1 then Wt := 1;
          if Wt > 100 then Wt := 100;
          if ScalarInt('SELECT COUNT(*) FROM search_term WHERE class_id=' + IntToStr(Cid) +
            ' AND term=' + QuotedStr(T)) = 0 then
            Exec(Format('INSERT INTO search_term(term,class_id,weight) VALUES(%s,%d,%d)',
              [QuotedStr(T), Cid, Wt]));
        end;
        DbCtx.Trans.CommitRetaining;
      except
        DbCtx.Trans.RollbackRetaining;
        raise;
      end;
    finally
      DbCtx.Batch := False;
    end;
  finally
    Lines.Free;
  end;
  ShowStatus('Suchbegriffe gespeichert.');
end;

{ ---------- Datenbank leeren (Neustart mit neuem Klassenschema) ---------- }

procedure TMainForm.MnuClearDb(Sender: TObject);
const
  Tabs: array[0..9] of string = ('part_value', 'part', 'class_image', 'class_property',
    'enum_value', 'translation', 'search_term', 'suggest_history', 'property', 'class');
var
  i: Integer;
begin
  if MessageDlg('Wirklich ALLE Klassen, Merkmale, Teile und Werte löschen? ' +
    'Lieferanten, Einheiten und die Gewichte des Klassenvorschlags bleiben erhalten.' +
    LineEnding + LineEnding + 'Das lässt sich nicht rückgängig machen. ' +
    'Vorher am besten eine Sicherung anlegen (Datei, Datenbank sichern).',
    mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;
  if MessageDlg('Ganz sicher? Diese Aktion löscht wirklich alle Klassen und Teile.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Screen.Cursor := crHourGlass;
  DbCtx.Batch := True;
  try
    try
      for i := 0 to High(Tabs) do Exec('DELETE FROM ' + Tabs[i]);
      DbCtx.Trans.CommitRetaining;
    except
      DbCtx.Trans.RollbackRetaining;
      raise;
    end;
  finally
    DbCtx.Batch := False;
    Screen.Cursor := crDefault;
  end;
  LoadTree(0);
  UpdateClassImage;
  ShowStatus('Datenbank geleert.');
  ShowMessage('Die Datenbank ist leer. Über „Datei, Klassenbaum aus Textdatei importieren" ' +
    'und „Normteile importieren" kannst du den neuen Bestand einspielen.');
end;

{ ---------- Klassenbaum aus Textdatei importieren ---------- }

procedure TMainForm.MnuImportTree(Sender: TObject);
var
  Dlg: TOpenDialog;
  Def: string;
begin
  if MessageDlg('Klassenbaum aus einer Textdatei importieren?' + LineEnding + LineEnding +
    'Die mitgelieferte Datei modellbau_klassenbaum.txt legt Einheiten, Merkmale und ' +
    'einen Klassenbaum für den Modellbau an (Normteile, Mechanik, Hydraulik, ' +
    'Elektronik, Material, eigene Konstruktionen). Was es schon gibt, bleibt ' +
    'unverändert. Es werden keine Teile angelegt.' + LineEnding + LineEnding +
    'Tipp: vorher eine Sicherung anlegen (Datei, Datenbank sichern).',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Klassenbaum-Datei wählen';
    Dlg.Filter := 'Klassenbaum (*.txt)|*.txt|Alle Dateien|*.*';
    Def := ResDir + 'modellbau_klassenbaum.txt';
    if FileExists(Def) then
    begin
      Dlg.InitialDir := ExtractFilePath(Def);
      Dlg.FileName := Def;
    end;
    if not Dlg.Execute then Exit;
    ImportTreeFile(Dlg.FileName);
  finally
    Dlg.Free;
  end;
end;

procedure TMainForm.MnuImportNormparts(Sender: TObject);
var
  Dlg: TOpenDialog;
  Def: string;
begin
  if ScalarInt('SELECT COUNT(*) FROM class WHERE code=''SKS''') = 0 then
  begin
    ShowMessage('Bitte zuerst den Klassenbaum importieren ' +
      '(Datei, Klassenbaum aus Textdatei importieren).');
    Exit;
  end;
  if MessageDlg('Normteile aus einer Textdatei importieren?' + LineEnding + LineEnding +
    'Die mitgelieferte Datei normteile.txt legt Klassen je Norm und rund 2500 Teile ' +
    'mit Merkmalen an: Schrauben (Sechskant, Zylinder, Senk, Linsenkopf, Kreuzschlitz, ' +
    'Blech, Gewindestifte, Gewindestangen), Muttern, Scheiben, Feder- und Zahnscheiben, ' +
    'Sicherungsringe, Stifte, Bolzen, Splinte und Passfedern, teils auch in ' +
    'Edelstahl A2. Vorhandene Teilenummern bleiben unverändert.' + LineEnding + LineEnding +
    'Die Maße stammen aus gängigen Normtabellen und sind nicht gegen die Normtexte ' +
    'geprüft - bitte vor der Konstruktion stichprobenartig vergleichen.' + LineEnding + LineEnding +
    'Tipp: vorher eine Sicherung anlegen (Datei, Datenbank sichern).',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Normteile-Datei wählen';
    Dlg.Filter := 'Normteile (*.txt)|*.txt|Alle Dateien|*.*';
    Def := ResDir + 'normteile.txt';
    if FileExists(Def) then
    begin
      Dlg.InitialDir := ExtractFilePath(Def);
      Dlg.FileName := Def;
    end;
    if not Dlg.Execute then Exit;
    ImportTreeFile(Dlg.FileName);
    LoadParts;
  finally
    Dlg.Free;
  end;
end;

procedure TMainForm.ImportTreeFile(const AFile: string);
const
  MaxWarn = 12;
var
  Lines, F, Sets, Items: TStringList;
  I, K, P, Lv, NewCls, NewProps, NewUnits, NewParts, SkipParts, WarnCnt, NewTerms, Wt: Integer;
  ClsCache, PropCache: TStringList;
  Stack: array[0..9] of Int64;
  Ln, Warn, Codes, Kind, Tok, ItemName, CNo, CMsg: string;
  Id, ParentId, PropId, FirstRoot: Int64;
  Fct, Sh: Double;
  Existed: Boolean;
  PF: TForm;
  PBar: TProgressBar;
  PLbl: TLabel;

  procedure AddWarn(const AMsg: string);
  begin
    Inc(WarnCnt);
    if WarnCnt <= MaxWarn then
      Warn := Warn + LineEnding + 'Zeile ' + IntToStr(I + 1) + ': ' + AMsg;
  end;

  function CodeOk(const ACode: string): Boolean;
  var
    N: Integer;
  begin
    Result := (ACode <> '') and (Length(ACode) <= 40);
    for N := 1 to Length(ACode) do
      if not (ACode[N] in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.']) then
        Result := False;
  end;

  procedure SplitInto(const S: string; ADelim: Char; AList: TStringList);
  begin
    AList.Clear;
    AList.StrictDelimiter := True;
    AList.Delimiter := ADelim;
    AList.DelimitedText := S;
  end;

  { ersetzt @Gruppenname durch die Merkmalscodes der Gruppe }
  function ExpandCodes(const S: string): string;
  var
    N: Integer;
    T: string;
  begin
    Result := '';
    SplitInto(S, ',', Items);
    for N := 0 to Items.Count - 1 do
    begin
      T := Trim(Items[N]);
      if T = '' then Continue;
      if T[1] = '@' then T := Sets.Values[Copy(T, 2, MaxInt)];
      if T = '' then Continue;
      if Result <> '' then Result := Result + ',';
      Result := Result + T;
    end;
  end;

begin
  Lines := TStringList.Create;
  F := TStringList.Create;
  Sets := TStringList.Create;
  Items := TStringList.Create;
  ClsCache := TStringList.Create;
  PropCache := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFile);
    except
      on E: Exception do
      begin
        ShowMessage('Die Datei konnte nicht gelesen werden:' + LineEnding + E.Message);
        Exit;
      end;
    end;
    NewCls := 0;
    NewProps := 0;
    NewUnits := 0;
    NewParts := 0;
    NewTerms := 0;
    SkipParts := 0;
    WarnCnt := 0;
    Warn := '';
    FirstRoot := 0;
    for K := 0 to 9 do Stack[K] := 0;
    PF := TForm.CreateNew(Self);
    PF.BorderStyle := bsDialog;
    PF.BorderIcons := [];
    PF.Position := poOwnerFormCenter;
    PF.Caption := 'Import läuft ...';
    PF.ClientWidth := 420;
    PF.ClientHeight := 80;
    PLbl := TLabel.Create(PF);
    PLbl.Parent := PF;
    PLbl.SetBounds(16, 12, 388, 18);
    PLbl.Caption := 'Bitte warten ...';
    PBar := TProgressBar.Create(PF);
    PBar.Parent := PF;
    PBar.SetBounds(16, 38, 388, 24);
    PBar.Min := 0;
    PBar.Max := Lines.Count;
    PF.Show;
    Application.ProcessMessages;
    DbCtx.Batch := True;   // alles in einer Transaktion: ganz oder gar nicht
    try
      try
        for I := 0 to Lines.Count - 1 do
        begin
          if (I mod 25) = 0 then
          begin
            PBar.Position := I;
            PLbl.Caption := 'Zeile ' + IntToStr(I + 1) + ' von ' + IntToStr(Lines.Count) +
              ' - ' + IntToStr(NewCls) + ' Klassen, ' + IntToStr(NewProps) + ' Merkmale, ' + IntToStr(NewParts) + ' Teile';
            Application.ProcessMessages;
          end;
          Ln := Trim(Lines[I]);
          if (I = 0) and (Copy(Ln, 1, 3) = #$EF#$BB#$BF) then Ln := Trim(Copy(Ln, 4, MaxInt));
          if (Ln = '') or (Ln[1] = '#') then Continue;
          SplitInto(Ln, '|', F);
          while F.Count < 7 do F.Add('');
          Kind := UpperCase(Trim(F[0]));

          if Kind = 'U' then
          begin
            if (Trim(F[1]) = '') or (Trim(F[2]) = '') or
              (not ParseNum(F[4], Fct)) or (not ParseNum(F[5], Sh)) or (Fct <= 0) then
              AddWarn('Einheit ungültig')
            else if ScalarInt('SELECT COUNT(*) FROM unit WHERE code=' +
              QuotedStr(Trim(F[1]))) = 0 then
            begin
              Exec('INSERT INTO unit(code,name,quantity,factor,shift) VALUES(' +
                QuotedStr(Trim(F[1])) + ',' + QuotedStr(Trim(F[2])) + ',' +
                QuotedStr(Trim(F[3])) + ',' + NumSql(Fct) + ',' + NumSql(Sh) + ')');
              Inc(NewUnits);
            end;
          end

          else if Kind = 'D' then
            Sets.Values[Trim(F[1])] := Trim(F[2])

          else if Kind = 'P' then
          begin
            if (not CodeOk(Trim(F[1]))) or (Trim(F[2]) = '') or
              (Pos('|' + LowerCase(Trim(F[3])) + '|',
                '|string|integer|real|boolean|enum|') = 0) then
              AddWarn('Merkmal ungültig')
            else
            begin
              Existed := ScalarInt('SELECT id FROM property WHERE code=' +
                QuotedStr(Trim(F[1]))) <> 0;
              PropId := EnsureProp(Trim(F[1]), Trim(F[2]), LowerCase(Trim(F[3])),
                Trim(F[4]));
              if not Existed then Inc(NewProps);
              if Trim(F[5]) <> '' then
              begin
                SplitInto(F[5], ';', Items);
                for K := 0 to Items.Count - 1 do
                begin
                  Tok := Items[K];
                  if Pos('=', Tok) > 0 then
                  begin
                    ItemName := Trim(Copy(Tok, Pos('=', Tok) + 1, MaxInt));
                    Tok := Trim(Copy(Tok, 1, Pos('=', Tok) - 1));
                    if (Tok <> '') and (ItemName <> '') then
                      Exec(InsIgnoreSql('enum_value', 'property_id,code,name',
                        Format('%d,%s,%s', [PropId, QuotedStr(Tok), QuotedStr(ItemName)])));
                  end;
                end;
              end;
            end;
          end

          else if Kind = 'C' then
          begin
            Lv := StrToIntDef(Trim(F[1]), 0);
            if (Lv < 1) or (Lv > 9) or (not CodeOk(Trim(F[2]))) or (Trim(F[3]) = '') then
              AddWarn('Klasse ungültig')
            else if Lv > 4 then
              AddWarn('Klasse ' + Trim(F[2]) + ': höchstens 4 Ebenen (AA.BB.CC.DD)')
            else if (Lv > 1) and (Stack[Lv - 1] = 0) then
              AddWarn('Oberklasse fehlt (Ebene ' + IntToStr(Lv - 1) + ')')
            else
            begin
              if Lv = 1 then ParentId := 0 else ParentId := Stack[Lv - 1];
              Id := ScalarInt('SELECT id FROM class WHERE code=' + QuotedStr(Trim(F[2])));
              if Id = 0 then
              begin
                // optionale Klassennummer in Spalte 7, sonst automatisch
                CNo := Trim(F[6]);
                if (CNo <> '') and not CheckClassNo(CNo, ParentId, 0, CMsg) then
                begin
                  AddWarn('Klasse ' + Trim(F[2]) + ': ' + CMsg + ' Nummer wird automatisch vergeben.');
                  CNo := '';
                end;
                if (CNo = '') and (NextClassNo(ParentId) = '') then
                begin
                  AddWarn('Klasse ' + Trim(F[2]) + ': keine Klassennummer frei');
                  Continue;
                end;
                Id := AddClass(Trim(F[2]), Trim(F[3]), ParentId, Trim(F[5]), CNo);
                Inc(NewCls);
              end;
              if (Lv = 1) and (FirstRoot = 0) then FirstRoot := Id;
              Stack[Lv] := Id;
              for K := Lv + 1 to 9 do Stack[K] := 0;
              Codes := ExpandCodes(F[4]);
              SplitInto(Codes, ',', Items);
              for K := 0 to Items.Count - 1 do
              begin
                Tok := Trim(Items[K]);
                if Tok = '' then Continue;
                PropId := ScalarInt('SELECT id FROM property WHERE code=' + QuotedStr(Tok));
                if PropId = 0 then
                  AddWarn('Merkmal "' + Tok + '" unbekannt (Klasse ' + Trim(F[2]) + ')')
                else
                  LinkProp(Id, PropId);
              end;
            end;
          end
          else if Kind = 'T' then
          begin
            Tok := Trim(F[1]);
            ParentId := StrToInt64Def(ClsCache.Values[Tok], -1);
            if ParentId < 0 then
            begin
              ParentId := ScalarInt('SELECT id FROM class WHERE code=' + QuotedStr(Tok));
              ClsCache.Values[Tok] := IntToStr(ParentId);
            end;
            if (ParentId = 0) or (Trim(F[2]) = '') then
              AddWarn('Teil ungültig (Klasse "' + Tok + '" unbekannt?)')
            else if PartNoTaken(Trim(F[2])) then
              Inc(SkipParts)
            else
            begin
              Id := AddPart(ParentId, Trim(F[2]), Trim(F[3]));
              Inc(NewParts);
              if Trim(F[5]) <> '' then
                Exec(Format('UPDATE part SET manufacturer=%s WHERE id=%d',
                  [QuotedStr(Trim(F[5])), Id]));
              if Trim(F[6]) <> '' then
                Exec(Format('UPDATE part SET cad_link=%s WHERE id=%d',
                  [QuotedStr(Trim(F[6])), Id]));
              if Trim(F[4]) <> '' then
              begin
                SplitInto(F[4], ';', Items);
                for K := 0 to Items.Count - 1 do
                begin
                  Tok := Items[K];
                  P := Pos('=', Tok);
                  if P > 0 then
                  begin
                    ItemName := Trim(Copy(Tok, P + 1, MaxInt));
                    Tok := Trim(Copy(Tok, 1, P - 1));
                    PropId := StrToInt64Def(PropCache.Values[Tok], -1);
                    if PropId < 0 then
                    begin
                      PropId := ScalarInt('SELECT id FROM property WHERE code=' + QuotedStr(Tok));
                      PropCache.Values[Tok] := IntToStr(PropId);
                    end;
                    if PropId = 0 then
                      AddWarn('Merkmal "' + Tok + '" unbekannt (Teil ' + Trim(F[2]) + ')')
                    else if ItemName <> '' then
                      SetValue(Id, PropId, ItemName);
                  end;
                end;
              end;
            end;
          end
          else if Kind = 'S' then
          begin
            // Suchbegriff: S|Begriff|Klassencode|Gewichtung
            Tok := Trim(F[2]);
            ParentId := StrToInt64Def(ClsCache.Values[Tok], -1);
            if ParentId < 0 then
            begin
              ParentId := ScalarInt('SELECT id FROM class WHERE code=' + QuotedStr(Tok));
              ClsCache.Values[Tok] := IntToStr(ParentId);
            end;
            Wt := StrToIntDef(Trim(F[3]), 10);
            if (Trim(F[1]) = '') or (ParentId = 0) then
              AddWarn('Suchbegriff ungültig (Klasse "' + Tok + '" unbekannt?)')
            else if ScalarInt('SELECT COUNT(*) FROM search_term WHERE term=' +
              QuotedStr(NormText(F[1])) + ' AND class_id=' + IntToStr(ParentId)) = 0 then
            begin
              Exec(Format('INSERT INTO search_term(term,class_id,weight) VALUES(%s,%d,%d)',
                [QuotedStr(NormText(F[1])), ParentId, Wt]));
              Inc(NewTerms);
            end;
          end
          else
            AddWarn('Unbekannte Zeilenart "' + Kind + '"');
        end;
        DbCtx.Trans.CommitRetaining;
      except
        DbCtx.Trans.RollbackRetaining;
        raise;
      end;
    finally
      DbCtx.Batch := False;
      PF.Free;
    end;
    LoadTree(FirstRoot);
    ShowMessage('Import fertig:' + LineEnding +
      IntToStr(NewCls) + ' neue Klassen, ' + IntToStr(NewProps) + ' neue Merkmale, ' +
      IntToStr(NewUnits) + ' neue Einheiten, ' + IntToStr(NewTerms) + ' neue Suchbegriffe, ' +
      IntToStr(NewParts) + ' neue Teile' +
      ' (' + IntToStr(SkipParts) + ' schon vorhanden).' + LineEnding +
      'Bereits vorhandene Einträge blieben unverändert.' +
      LineEnding + IntToStr(WarnCnt) + ' Hinweis(e).' + Warn);
  finally
    PropCache.Free;
    ClsCache.Free;
    Items.Free;
    Sets.Free;
    F.Free;
    Lines.Free;
  end;
end;

procedure TMainForm.MnuSampleData(Sender: TObject);
var
  cNT, cSCHR, cSKS, cZKS, cMUT, cSKM, cUSC, cBOL, cSTI: Int64;
  pWerk, pNorm, pObfl, pFkl, pDn, pL, pSw, pK, pDk, pSwi, pM, pD1, pD2, pS: Int64;
  NewParts: Integer;

  function Cls(const ACode, AName: string; AParent: Int64): Int64;
  begin
    Result := ScalarInt('SELECT id FROM class WHERE code=' + QuotedStr(ACode));
    if Result = 0 then Result := AddClass(ACode, AName, AParent, '');
  end;

  procedure EnumVal(AProp: Int64; const ACode, AName: string);
  begin
    Exec(InsIgnoreSql('enum_value', 'property_id,code,name',
      Format('%d,%s,%s', [AProp, QuotedStr(ACode), QuotedStr(AName)])));
  end;

  { AVals: 'CODE=Wert;CODE=Wert;...' }
  procedure Pt(AClass: Int64; const APartNo, ADesc, AVals: string);
  var
    PartId, PropId: Int64;
    Rest, Item: string;
    p: Integer;
  begin
    if PartNoTaken(APartNo) then
      Exit;
    PartId := AddPart(AClass, APartNo, ADesc);
    Inc(NewParts);
    Rest := AVals + ';';
    while Rest <> '' do
    begin
      p := Pos(';', Rest);
      Item := Copy(Rest, 1, p - 1);
      Delete(Rest, 1, p);
      p := Pos('=', Item);
      if p > 0 then
      begin
        PropId := ScalarInt('SELECT id FROM property WHERE code=' +
          QuotedStr(Copy(Item, 1, p - 1)));
        if PropId <> 0 then SetValue(PartId, PropId, Copy(Item, p + 1, MaxInt));
      end;
    end;
  end;

  procedure HexScrew(const ASize, ALen, ASW, AK: string);
  begin
    Pt(cSKS, 'SKS-M' + ASize + 'x' + ALen,
      'Sechskantschraube DIN 933 M' + ASize + 'x' + ALen,
      'NORM=DIN 933;WERKSTOFF=Stahl;FKL=8.8;OBERFL=ZN;DN=' + ASize + ';L=' + ALen +
      ';SW=' + ASW + ';K=' + AK);
  end;

  procedure CapScrew(const ASize, ALen, ADK, AK, ASWI: string; AStainless: Boolean);
  begin
    if AStainless then
      Pt(cZKS, 'ZKS-M' + ASize + 'x' + ALen + '-A2',
        'Zylinderkopfschraube DIN 912 M' + ASize + 'x' + ALen + ' A2',
        'NORM=DIN 912;WERKSTOFF=Edelstahl A2;FKL=A2-70;OBERFL=BLANK;DN=' + ASize +
        ';L=' + ALen + ';K=' + AK + ';DK=' + ADK + ';SWI=' + ASWI)
    else
      Pt(cZKS, 'ZKS-M' + ASize + 'x' + ALen,
        'Zylinderkopfschraube DIN 912 M' + ASize + 'x' + ALen,
        'NORM=DIN 912;WERKSTOFF=Stahl;FKL=12.9;OBERFL=BRUEN;DN=' + ASize +
        ';L=' + ALen + ';K=' + AK + ';DK=' + ADK + ';SWI=' + ASWI);
  end;

  procedure HexNut(const ASize, ASW, AM: string);
  begin
    Pt(cSKM, 'SKM-M' + ASize, 'Sechskantmutter DIN 934 M' + ASize,
      'NORM=DIN 934;WERKSTOFF=Stahl;FKL=8;OBERFL=ZN;DN=' + ASize + ';SW=' + ASW +
      ';M=' + AM);
  end;

  procedure Washer(const ASize, AD1, AD2, AThick: string);
  begin
    Pt(cUSC, 'USC-' + ASize, 'Scheibe DIN 125 fuer M' + ASize,
      'NORM=DIN 125-A;WERKSTOFF=Stahl;OBERFL=ZN;DN=' + ASize + ';D1=' + AD1 +
      ';D2=' + AD2 + ';S=' + AThick);
  end;

  procedure PinPart(AClass: Int64; const APrefix, ADesc, ANorm, ASize, ALen: string);
  begin
    Pt(AClass, APrefix + '-' + ASize + 'x' + ALen, ADesc + ' ' + ASize + 'x' + ALen,
      'NORM=' + ANorm + ';WERKSTOFF=Stahl;OBERFL=BLANK;DN=' + ASize + ';L=' + ALen);
  end;

begin
  if MessageDlg('Musterdaten einfuegen?' + LineEnding + LineEnding +
    'Es werden Klassen, Merkmale und Teile fuer Schrauben (DIN 933, DIN 912), ' +
    'Muttern (DIN 934), Scheiben (DIN 125), Bolzen (ISO 2341) und Zylinderstifte ' +
    '(ISO 2338) angelegt. Vorhandene Eintraege mit gleichem Code oder gleicher ' +
    'Teilenummer bleiben unveraendert.' + LineEnding + LineEnding +
    'Die Massangaben sind Richtwerte aus meinem Wissen; bitte vor dem produktiven ' +
    'Einsatz mit den Normen abgleichen.',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  NewParts := 0;
  DbCtx.Batch := True;   // alles in einer Transaktion: schnell und ganz oder gar nicht
  try
    // Klassen
    cNT := Cls('NT', 'Normteil', 0);
    cSCHR := Cls('SCHR', 'Schraube', cNT);
    cSKS := Cls('SKS', 'Sechskantschraube', cSCHR);
    cZKS := Cls('ZKS', 'Zylinderkopfschraube', cSCHR);
    cMUT := Cls('MUT', 'Mutter', cNT);
    cSKM := Cls('SKM', 'Sechskantmutter', cMUT);
    cUSC := Cls('USC', 'Unterlegscheibe', cNT);
    cBOL := Cls('BOL', 'Bolzen', cNT);
    cSTI := Cls('STI', 'Zylinderstift', cNT);

    // Merkmale
    pWerk := EnsureProp('WERKSTOFF', 'Werkstoff', 'string', '');
    pNorm := EnsureProp('NORM', 'Norm', 'string', '');
    pObfl := EnsureProp('OBERFL', 'Oberfläche', 'enum', '');
    pFkl := EnsureProp('FKL', 'Festigkeitsklasse', 'enum', '');
    pDn := EnsureProp('DN', 'Nenndurchmesser', 'real', 'mm');
    pL := EnsureProp('L', 'Länge', 'real', 'mm');
    pSw := EnsureProp('SW', 'Schlüsselweite', 'real', 'mm');
    pK := EnsureProp('K', 'Kopfhöhe', 'real', 'mm');
    pDk := EnsureProp('DK', 'Kopfdurchmesser', 'real', 'mm');
    pSwi := EnsureProp('SWI', 'Innensechskant (Schlüsselweite)', 'real', 'mm');
    pM := EnsureProp('M', 'Mutternhöhe', 'real', 'mm');
    pD1 := EnsureProp('D1', 'Innendurchmesser', 'real', 'mm');
    pD2 := EnsureProp('D2', 'Außendurchmesser', 'real', 'mm');
    pS := EnsureProp('S', 'Dicke', 'real', 'mm');

    // Aufzaehlungswerte
    EnumVal(pObfl, 'BLANK', 'blank');
    EnumVal(pObfl, 'ZN', 'galvanisch verzinkt');
    EnumVal(pObfl, 'BRUEN', 'schwarz brüniert');
    EnumVal(pObfl, 'HDG', 'feuerverzinkt');
    EnumVal(pFkl, '8.8', 'Festigkeitsklasse 8.8');
    EnumVal(pFkl, '10.9', 'Festigkeitsklasse 10.9');
    EnumVal(pFkl, '12.9', 'Festigkeitsklasse 12.9');
    EnumVal(pFkl, 'A2-70', 'Edelstahl A2-70');
    EnumVal(pFkl, 'A4-70', 'Edelstahl A4-70');
    EnumVal(pFkl, '6', 'Mutter Klasse 6');
    EnumVal(pFkl, '8', 'Mutter Klasse 8');
    EnumVal(pFkl, '10', 'Mutter Klasse 10');

    // Merkmale den Klassen zuordnen (werden an Unterklassen vererbt)
    LinkProp(cNT, pWerk);
    LinkProp(cNT, pNorm);
    LinkProp(cNT, pObfl);
    LinkProp(cSCHR, pDn);
    LinkProp(cSCHR, pFkl);
    LinkProp(cSKS, pL);
    LinkProp(cSKS, pSw);
    LinkProp(cSKS, pK);
    LinkProp(cZKS, pL);
    LinkProp(cZKS, pK);
    LinkProp(cZKS, pDk);
    LinkProp(cZKS, pSwi);
    LinkProp(cMUT, pDn);
    LinkProp(cMUT, pFkl);
    LinkProp(cSKM, pSw);
    LinkProp(cSKM, pM);
    LinkProp(cUSC, pDn);
    LinkProp(cUSC, pD1);
    LinkProp(cUSC, pD2);
    LinkProp(cUSC, pS);
    LinkProp(cBOL, pDn);
    LinkProp(cBOL, pL);
    LinkProp(cSTI, pDn);
    LinkProp(cSTI, pL);

    // Sechskantschrauben DIN 933 (Groesse, Laenge, Schluesselweite, Kopfhoehe)
    HexScrew('6', '20', '10', '4');
    HexScrew('6', '30', '10', '4');
    HexScrew('8', '25', '13', '5.3');
    HexScrew('8', '40', '13', '5.3');
    HexScrew('10', '30', '17', '6.4');
    HexScrew('10', '50', '17', '6.4');
    HexScrew('12', '40', '19', '7.5');
    HexScrew('12', '60', '19', '7.5');

    // Zylinderkopfschrauben DIN 912 (Groesse, Laenge, Kopf-O, Kopfhoehe, Innensechskant)
    CapScrew('6', '20', '10', '6', '5', False);
    CapScrew('6', '30', '10', '6', '5', False);
    CapScrew('8', '25', '13', '8', '6', False);
    CapScrew('8', '40', '13', '8', '6', False);
    CapScrew('10', '30', '16', '10', '8', False);
    CapScrew('10', '50', '16', '10', '8', False);
    CapScrew('12', '40', '18', '12', '10', False);
    CapScrew('12', '60', '18', '12', '10', False);
    CapScrew('8', '25', '13', '8', '6', True);
    CapScrew('10', '30', '16', '10', '8', True);

    // Sechskantmuttern DIN 934 (Groesse, Schluesselweite, Mutternhoehe)
    HexNut('6', '10', '5');
    HexNut('8', '13', '6.5');
    HexNut('10', '17', '8');
    HexNut('12', '19', '10');

    // Scheiben DIN 125 (Groesse, Innen-O, Aussen-O, Dicke)
    Washer('6', '6.4', '12', '1.6');
    Washer('8', '8.4', '16', '1.6');
    Washer('10', '10.5', '20', '2');
    Washer('12', '13', '24', '2.5');

    // Bolzen ISO 2341 B und Zylinderstifte ISO 2338
    PinPart(cBOL, 'BOL', 'Bolzen ISO 2341 B', 'ISO 2341 B', '6', '20');
    PinPart(cBOL, 'BOL', 'Bolzen ISO 2341 B', 'ISO 2341 B', '8', '30');
    PinPart(cBOL, 'BOL', 'Bolzen ISO 2341 B', 'ISO 2341 B', '10', '40');
    PinPart(cBOL, 'BOL', 'Bolzen ISO 2341 B', 'ISO 2341 B', '12', '40');
    PinPart(cSTI, 'STI', 'Zylinderstift ISO 2338', 'ISO 2338', '6', '20');
    PinPart(cSTI, 'STI', 'Zylinderstift ISO 2338', 'ISO 2338', '8', '30');
    PinPart(cSTI, 'STI', 'Zylinderstift ISO 2338', 'ISO 2338', '10', '40');

    DbCtx.Trans.CommitRetaining;
  finally
    DbCtx.Batch := False;
  end;
  LoadTree(cNT);
  ShowMessage(IntToStr(NewParts) + ' Teile wurden angelegt.' + LineEnding +
    'Bereits vorhandene Teile mit gleicher Teilenummer wurden uebersprungen.');
end;

{ ---------- Kontextmenues (rechte Maustaste) ---------- }

function TMainForm.AddPopItem(APopup: TPopupMenu; const ACaption: string;
  AClick: TNotifyEvent; ATag: Integer): TMenuItem;
begin
  Result := TMenuItem.Create(APopup);
  Result.Caption := ACaption;
  Result.OnClick := AClick;
  Result.Tag := ATag;
  APopup.Items.Add(Result);
end;

{ Tag 0 = braucht ein markiertes Objekt, 1 = immer moeglich,
  2 = braucht eine gewaehlte Klasse, 3 = braucht ein gewaehltes Teil }
procedure TMainForm.BuildPopups;
begin
  // --- Klassenbaum ---
  PopTree := TPopupMenu.Create(Self);
  PopTree.OnPopup := @PopupOpen;
  AddPopItem(PopTree, 'Neue Unterklasse ...', @BtnNewClass, 1);
  AddPopItem(PopTree, 'Neue Hauptklasse ...', @MnuNewRootClass, 1);
  AddPopItem(PopTree, '-', nil, 1);
  AddPopItem(PopTree, 'Klasse umbenennen ...', @BtnRenameClass, 0);
  AddPopItem(PopTree, 'Beschreibung / Status ...', @BtnClassDesc, 0);
  AddPopItem(PopTree, 'Übersetzung der Klasse ...', @BtnClassTrans, 0);
  AddPopItem(PopTree, 'Klassenbild zuordnen ...', @BtnClassImage, 0);
  AddPopItem(PopTree, 'Klassenbild entfernen', @BtnClassImageDel, 0);
  AddPopItem(PopTree, '-', nil, 1);
  AddPopItem(PopTree, 'Merkmale der Klasse verwalten ...', @BtnManageProps, 0);
  AddPopItem(PopTree, 'Neues Teil in dieser Klasse ...', @BtnNewPartInClass, 0);
  AddPopItem(PopTree, '-', nil, 1);
  AddPopItem(PopTree, 'Alle aufklappen', @MnuTreeExpand, 1);
  AddPopItem(PopTree, 'Alle zuklappen', @MnuTreeCollapse, 1);
  AddPopItem(PopTree, '-', nil, 1);
  AddPopItem(PopTree, 'Klasse löschen ...', @BtnDelClass, 0);
  Tree.PopupMenu := PopTree;
  Tree.OnMouseDown := @TreeMouseDown;

  // --- Teileliste ---
  PopParts := TPopupMenu.Create(Self);
  PopParts.OnPopup := @PopupOpen;
  AddPopItem(PopParts, 'Werte / Teil bearbeiten ...', @BtnEditValues, 0);
  AddPopItem(PopParts, 'Neues Teil in der Klasse ...', @BtnNewPartInClass, 2);
{$IFDEF WINDOWS}
  AddPopItem(PopParts, '-', nil, 1);
  AddPopItem(PopParts, 'In Solid Edge öffnen', @BtnSeOpen, 0);
  AddPopItem(PopParts, 'In Baugruppe einfügen', @BtnSeInsert, 0);
  AddPopItem(PopParts, 'CAD-Datei zuordnen ...', @BtnSeAssign, 0);
  AddPopItem(PopParts, 'CAD-Datei entfernen', @BtnSeUnassign, 0);
  AddPopItem(PopParts, 'Eigenschaften nach Solid Edge schreiben', @BtnSeWriteProps, 0);
{$ENDIF}
  SetupPlugins;
  AddPopItem(PopParts, '-', nil, 1);
  AddPopItem(PopParts, 'CAD-Katalog-Link öffnen', @BtnOpenCadLink, 0);
  AddPopItem(PopParts, 'Teilenummer kopieren', @MnuCopyPartNo, 0);
  AddPopItem(PopParts, 'Zeile kopieren', @MnuCopyRow, 0);
  AddPopItem(PopParts, '-', nil, 1);
  AddPopItem(PopParts, 'Teil löschen ...', @BtnDelPart, 0);
  GridParts.PopupMenu := PopParts;
  GridParts.OnMouseDown := @GridMouseDown;
  GridParts.OnContextPopup := @GridPartsContextPopup;

  // --- Merkmalswerte des gewaehlten Teils ---
  PopValues := TPopupMenu.Create(Self);
  PopValues.OnPopup := @PopupOpen;
  AddPopItem(PopValues, 'Wert ändern ...', @MnuValueEdit, 0);
  AddPopItem(PopValues, 'Wert löschen', @MnuValueDelete, 0);
  AddPopItem(PopValues, 'Wert kopieren', @MnuValueCopy, 0);
  AddPopItem(PopValues, '-', nil, 1);
  AddPopItem(PopValues, 'Alle Werte des Teils bearbeiten ...', @BtnEditValues, 3);
  GridValues.PopupMenu := PopValues;
  GridValues.OnMouseDown := @GridMouseDown;
end;

function TMainForm.ValueRowOk: Boolean;
begin
  Result := (GridValues.RowCount > 1) and (GridValues.Row >= 1) and
    (Trim(CellBy(GridValues, 'Code', GridValues.Row)) <> '');
end;

procedure TMainForm.PopupOpen(Sender: TObject);
var
  PM: TPopupMenu;
  i: Integer;
  HasObj: Boolean;
begin
  PM := Sender as TPopupMenu;
  if PM = PopTree then
    HasObj := CurClass <> 0
  else if PM = PopParts then
    HasObj := CurPart <> 0
  else
    HasObj := ValueRowOk;
  for i := 0 to PM.Items.Count - 1 do
    case PM.Items[i].Tag of
      0: PM.Items[i].Enabled := HasObj;
      2: PM.Items[i].Enabled := CurClass <> 0;
      3: PM.Items[i].Enabled := CurPart <> 0;
    else
      PM.Items[i].Enabled := True;
    end;
end;

{ Rechtsklick markiert zuerst das Element unter dem Mauszeiger }
procedure TMainForm.TreeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  N: TTreeNode;
begin
  if Button <> mbRight then Exit;
  N := Tree.GetNodeAt(X, Y);
  if N <> nil then Tree.Selected := N;
end;

procedure TMainForm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  G: TStringGrid;
  C, R: Integer;
begin
  G := Sender as TStringGrid;
  G.MouseToCell(X, Y, C, R);
  if Button = mbRight then
  begin
    if (R >= 1) and (R < G.RowCount) then G.Row := R;
    Exit;
  end;
  // Doppelklick auf eine Zeile oeffnet die Bearbeitung
  if (Button = mbLeft) and (ssDouble in Shift) and (R >= 1) and (R < G.RowCount) then
  begin
    G.Row := R;
    if G = GridParts then
      BtnEditValues(nil)
    else
      MnuValueEdit(nil);
  end;
end;

procedure TMainForm.ListMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LB: TListBox;
  Idx: Integer;
begin
  if Button <> mbRight then Exit;
  LB := Sender as TListBox;
  Idx := LB.ItemAtPos(Point(X, Y), True);
  if Idx >= 0 then LB.ItemIndex := Idx;
end;

procedure TMainForm.MnuNewRootClass(Sender: TObject);
var
  Prev: Int64;
begin
  Prev := CurClass;
  Tree.Selected := nil;
  BtnNewClass(nil);
  if CurClass = 0 then LoadTree(Prev);
end;

procedure TMainForm.MnuTreeExpand(Sender: TObject);
begin
  Tree.FullExpand;
end;

procedure TMainForm.MnuTreeCollapse(Sender: TObject);
begin
  Tree.FullCollapse;
  if Assigned(Tree.Selected) then Tree.Selected.MakeVisible;
end;

procedure TMainForm.MnuCopyPartNo(Sender: TObject);
begin
  if CurPart = 0 then Exit;
  Clipboard.AsText := CellBy(GridParts, 'Teilenummer', GridParts.Row);
end;

procedure TMainForm.MnuCopyRow(Sender: TObject);
var
  c: Integer;
  S: string;
begin
  if CurPart = 0 then Exit;
  S := '';
  for c := 0 to GridParts.ColCount - 1 do
  begin
    if c > 0 then S := S + #9;
    S := S + GridParts.Cells[c, GridParts.Row];
  end;
  Clipboard.AsText := S;
end;

{ Findet Teil und Merkmal der markierten Zeile in der Werteliste }
function TMainForm.ValueTarget(out APart, AProp: Int64): Boolean;
begin
  Result := False;
  APart := CurPart;
  AProp := 0;
  if (APart = 0) or (not ValueRowOk) then Exit;
  AProp := ScalarInt('SELECT id FROM property WHERE code=' +
    QuotedStr(CellBy(GridValues, 'Code', GridValues.Row)));
  Result := AProp <> 0;
end;

procedure TMainForm.MnuValueEdit(Sender: TObject);
var
  PartId, PropId: Int64;
  P: TPropDef;
  V: string;
begin
  if not ValueTarget(PartId, PropId) then Exit;
  P.Id := PropId;
  P.Name := RowStr('property', 'name', PropId);
  P.UnitName := RowStr('property', 'unit', PropId);
  P.DataType := RowStr('property', 'datatype', PropId);
  P.Code := RowStr('property', 'code', PropId);
  V := ScalarStr(Format('SELECT value FROM part_value WHERE part_id=%d AND property_id=%d',
    [PartId, PropId]));
  if not AskValue(P, V) then Exit;
  if V = '' then
    Exec(Format('DELETE FROM part_value WHERE part_id=%d AND property_id=%d',
      [PartId, PropId]))
  else
    SetValue(PartId, PropId, V);
  LoadParts;
  SelectPart(PartId);
end;

procedure TMainForm.MnuValueDelete(Sender: TObject);
var
  PartId, PropId: Int64;
begin
  if not ValueTarget(PartId, PropId) then Exit;
  if MessageDlg('Wert "' + CellBy(GridValues, 'Eigenschaft', GridValues.Row) +
    '" dieses Teils loeschen?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  Exec(Format('DELETE FROM part_value WHERE part_id=%d AND property_id=%d',
    [PartId, PropId]));
  LoadParts;
  SelectPart(PartId);
end;

procedure TMainForm.MnuValueCopy(Sender: TObject);
begin
  if not ValueRowOk then Exit;
  Clipboard.AsText := CellBy(GridValues, 'Wert', GridValues.Row);
end;

procedure TMainForm.MakeDlgPopup(AList: TListBox);
var
  PM: TPopupMenu;
begin
  PM := TPopupMenu.Create(AList);
  AddPopItem(PM, 'Neues Merkmal ...', @DlgNew, 1);
  AddPopItem(PM, '-', nil, 1);
  AddPopItem(PM, 'Merkmal ändern ...', @DlgEdit, 1);
  AddPopItem(PM, 'Beschreibung / Status ...', @DlgDesc, 1);
  AddPopItem(PM, 'Übersetzung ...', @DlgTrans, 1);
  AddPopItem(PM, 'Aufzählungswerte ...', @DlgEnum, 1);
  AddPopItem(PM, '-', nil, 1);
  AddPopItem(PM, 'Von der Klasse entfernen', @DlgDel, 1);
  AList.PopupMenu := PM;
  AList.OnMouseDown := @ListMouseDown;
end;

procedure TMainForm.MakeCatPopup(AList: TListBox);
var
  PM: TPopupMenu;
begin
  PM := TPopupMenu.Create(AList);
  AddPopItem(PM, 'Neues Merkmal ...', @CatNew, 1);
  AddPopItem(PM, '-', nil, 1);
  AddPopItem(PM, 'Der gewählten Klasse zuordnen', @CatAssign, 1);
  AddPopItem(PM, '-', nil, 1);
  AddPopItem(PM, 'Merkmal ändern ...', @CatEdit, 1);
  AddPopItem(PM, 'Beschreibung / Status ...', @CatDesc, 1);
  AddPopItem(PM, 'Übersetzung ...', @CatTrans, 1);
  AddPopItem(PM, 'Aufzählungswerte ...', @CatEnum, 1);
  AddPopItem(PM, '-', nil, 1);
  AddPopItem(PM, 'Aus dem Katalog löschen ...', @CatDel, 1);
  AList.PopupMenu := PM;
  AList.OnMouseDown := @ListMouseDown;
end;

{ Prueft, ob ein Code in einer Tabelle schon vergeben ist }
function TMainForm.CodeTaken(const ATable, ACode: string; AExceptId: Int64): Boolean;
begin
  Result := ScalarInt(Format('SELECT COUNT(*) FROM %s WHERE code=%s AND id<>%d',
    [ATable, QuotedStr(ACode), AExceptId])) > 0;
end;

{ ---------- Klassenbaum: Farben und Hinweise ---------- }

procedure TMainForm.TreeCustomDraw(Sender: TCustomTreeView; Node: TTreeNode;
  State: TCustomDrawState; var DefaultDraw: Boolean);
var
  St: Integer;
begin
  DefaultDraw := True;
  if Node = nil then Exit;
  St := Node.ImageIndex mod 3;
  if St = 2 then
    Sender.Canvas.Font.Style := [fsStrikeOut]
  else
    Sender.Canvas.Font.Style := [];
  if cdsSelected in State then Exit;
  case St of
    1: Sender.Canvas.Font.Color := ThemeOkColor;        // freigegeben
    2: Sender.Canvas.Font.Color := ThemeMutedColor;     // veraltet: grau
  else
    Sender.Canvas.Font.Color := ThemeTextColor;
  end;
end;

function TMainForm.TreeHintText(Node: TTreeNode): string;
var
  Id: Int64;
  Df: string;
begin
  Result := '';
  if Node = nil then Exit;
  Id := Int64(PtrUInt(Node.Data{%H-}));
  Result := 'Klasse ' + RowStr('class', 'class_no', Id) + ' (' +
    RowStr('class', 'code', Id) + ')' + LineEnding +
    RowStr('class', 'name', Id) + LineEnding +
    'Status: ' + RowStr('class', 'status', Id) + ', Version ' +
    RowStr('class', 'version', Id) + LineEnding +
    'Unterklassen: ' + IntToStr(ScalarInt('SELECT COUNT(*) FROM class WHERE parent_id=' +
      IntToStr(Id))) + LineEnding +
    'Teile in dieser Klasse: ' + IntToStr(ScalarInt(
      'SELECT COUNT(*) FROM part WHERE class_id=' + IntToStr(Id)));
  Df := RowStr('class', 'definition', Id);
  if Df <> '' then Result := Result + LineEnding + LineEnding + Df;
end;

{ ---------- Klassenbild ---------- }

{ Liest das Bild der Klasse oder der naechsten Oberklasse mit Bild in einen Stream.
  AOwner = Klasse, zu der das Bild gehoert (0 = kein Bild). AExt mit Punkt, z. B. '.png' }
function TMainForm.ReadClassImage(AClass: Int64; AStream: TStream; out AExt: string;
  out AOwner: Int64): Boolean;
var
  Q: TSQLQuery;
begin
  Result := False;
  AExt := '';
  AOwner := ScalarInt(
    'WITH RECURSIVE anc(id, depth) AS (SELECT id, 0 FROM class WHERE id=' +
    IntToStr(AClass) + ' UNION ALL SELECT c.parent_id, a.depth+1 FROM class c ' +
    'JOIN anc a ON c.id=a.id WHERE c.parent_id IS NOT NULL) ' +
    'SELECT ci.class_id FROM class_image ci JOIN anc ON anc.id=ci.class_id ' +
    'ORDER BY anc.depth LIMIT 1');
  if AOwner = 0 then Exit;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT ext, data FROM class_image WHERE class_id=' + IntToStr(AOwner);
    Q.Open;
    if not Q.EOF then
    begin
      AExt := FieldText(Q.Fields[0]);
      TBlobField(Q.Fields[1]).SaveToStream(AStream);
      Result := AStream.Size > 0;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TMainForm.LoadClassPicture(AClass: Int64; APic: TPicture;
  out AOwner: Int64): Boolean;
var
  Ms: TMemoryStream;
  Ext: string;
begin
  Result := False;
  Ms := TMemoryStream.Create;
  try
    if ReadClassImage(AClass, Ms, Ext, AOwner) then
    begin
      Ms.Position := 0;
      try
        APic.LoadFromStreamWithFileExt(Ms, Ext);
        Result := True;
      except
        Result := False;
      end;
    end;
  finally
    Ms.Free;
  end;
end;

{ Zeigt das Bild der gewaehlten Klasse im dauerhaften Bildbereich }
procedure TMainForm.UpdateClassImage;
var
  Cid, PicOwner: Int64;
  Pic: TPicture;
begin
  if (DockMgr = nil) or (ImgView = nil) then Exit;
  if not DockMgr.PaneVisible('image') then Exit;
  if not Visible then Exit;
  Cid := CurClass;
  if Cid = 0 then
  begin
    ImgView.Picture.Clear;
    ImgInfo.Caption := 'Keine Klasse gewählt';
    DockMgr.SetTitle('image', 'Klassenbild');
    Exit;
  end;
  Pic := TPicture.Create;
  try
    if LoadClassPicture(Cid, Pic, PicOwner) then
    begin
      ImgView.Picture.Assign(Pic);
      if PicOwner = Cid then
        ImgInfo.Caption := 'Bild dieser Klasse'
      else
        ImgInfo.Caption := 'Bild der Oberklasse ' + RowStr('class', 'code', PicOwner);
    end
    else
    begin
      ImgView.Picture.Clear;
      ImgInfo.Caption := 'Kein Bild vorhanden (Rechtsklick: Bild zuordnen)';
    end;
  finally
    Pic.Free;
  end;
  DockMgr.SetTitle('image', 'Klassenbild: ' + RowStr('class', 'code', Cid) + ' - ' +
    RowStr('class', 'name', Cid));
end;

{ Mausrad scrollt die Tabelle unter dem Mauszeiger (auch ohne Fokus) }
procedure TMainForm.FormWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint; var Handled: Boolean);
var
  C: TControl;
  G: TStringGrid;
  NewTop: Integer;
begin
  C := FindControlAtPosition(Mouse.CursorPos, True);
  if C = nil then C := FindLCLControl(Mouse.CursorPos);
  if (C = nil) or not (C is TStringGrid) then Exit;
  G := TStringGrid(C);
  if WheelDelta > 0 then NewTop := G.TopRow - 3 else NewTop := G.TopRow + 3;
  if NewTop > G.RowCount - 1 then NewTop := G.RowCount - 1;
  if NewTop < G.FixedRows then NewTop := G.FixedRows;
  G.TopRow := NewTop;
  Handled := True;
end;

procedure TMainForm.MainShow(Sender: TObject);
begin
  // Aufteilung erst aufbauen, wenn das Fenster seine endgueltige Groesse hat
  Application.QueueAsyncCall(@AsyncBuild, 0);
  Application.QueueAsyncCall(@UpdateAuto, 0);   // Update-Pruefung (hoechstens einmal pro Tag)
end;

{ ---------- Programm-Update ---------- }

procedure TMainForm.MnuCheckUpdate(Sender: TObject);
begin
  StartUpdate(True);
end;

{ Beim Start: pruefen, wenn eingeschaltet und heute noch nicht geprueft }
procedure TMainForm.UpdateAuto(Data: PtrInt);
var
  Ini: TIniFile;
  Auto: Boolean;
begin
  Ini := TIniFile.Create(IniName);
  try
    Auto := (Ini.ReadInteger('Update', 'AutoPruefen', 1) <> 0) and
      (Ini.ReadString('Update', 'LetztePruefung', '') <> FormatDateTime('yyyy-mm-dd', Date));
  finally
    Ini.Free;
  end;
  if Auto then StartUpdate(False);
end;

procedure TMainForm.StartUpdate(AManual: Boolean);
var
  Ini: TIniFile;
  Src: string;
begin
  Ini := TIniFile.Create(IniName);
  try
    Src := Ini.ReadString('Update', 'Quelle', '');
  finally
    Ini.Free;
  end;
  if AManual then ShowStatus('Suche nach Updates ...');
  StartUpdateCheck(Src, AppVersion, AManual, @UpdateDone);
end;

procedure TMainForm.UpdateDone(const AInfo: TUpdateInfo; AManual: Boolean);
var
  Ini: TIniFile;
  Msg, Skipped: string;
  R: Integer;
begin
  if AManual then ShowStatus('');
  Ini := TIniFile.Create(IniName);
  try
    if AInfo.Ok then
      Ini.WriteString('Update', 'LetztePruefung', FormatDateTime('yyyy-mm-dd', Date));
    Skipped := Ini.ReadString('Update', 'Uebersprungen', '');
  finally
    Ini.Free;
  end;
  if not AInfo.Ok then
  begin
    // beim automatischen Pruefen still bleiben (z. B. kein Netz, privates Repository)
    if AManual then
    begin
      if (Pos('404', AInfo.Error) > 0) and (Pos('api.github.com', AInfo.Error) > 0) then
        Msg := 'Es wurde keine Update-Information gefunden.' + LineEnding + LineEnding +
          'Die Veröffentlichung auf GitHub ist zurzeit nicht abrufbar (das Projekt ist ' +
          'nicht öffentlich oder es gibt noch keine veröffentlichte Version).' + LineEnding +
          LineEnding + 'Eine andere Quelle (z. B. eine Textdatei im Netzwerk) trägst du in ' +
          'der Datei plib.ini unter [Update] bei "Quelle=" ein.'
      else
        Msg := 'Die Update-Quelle ist zurzeit nicht erreichbar.' + LineEnding + LineEnding +
          AInfo.Error;
      InfoText('Update-Prüfung', Msg);
    end;
    Exit;
  end;
  if not AInfo.Available then
  begin
    if AManual then
      InfoText('Update-Prüfung', 'PLIB ist auf dem neuesten Stand (Version ' + AppVersion + ').');
    Exit;
  end;
  if (not AManual) and SameText(Skipped, AInfo.Version) then Exit;
  Msg := 'Es ist eine neue Version von PLIB verfügbar: ' + AInfo.Version +
    LineEnding + '(installiert: ' + AppVersion + ')';
  if AInfo.Notes <> '' then
    Msg := Msg + LineEnding + LineEnding + 'Neu in dieser Version:' + LineEnding + AInfo.Notes;
  Msg := Msg + LineEnding + LineEnding + 'Jetzt aktualisieren?';
  R := AskUpdate('PLIB-Update', Msg);
  if R = 1 then
    InstallUpdate(AInfo)
  else if R = 3 then
  begin
    Ini := TIniFile.Create(IniName);
    try
      Ini.WriteString('Update', 'Uebersprungen', AInfo.Version);
    finally
      Ini.Free;
    end;
  end;
end;

procedure TMainForm.InstallUpdate(const AInfo: TUpdateInfo);
var
  Local, Err: string;
  P: TProcess;
begin
  Screen.Cursor := crHourGlass;
  try
    ShowStatus('Installer wird geladen ...');
    Application.ProcessMessages;
    Local := FetchInstaller(AInfo.Download, Err);
  finally
    Screen.Cursor := crDefault;
    ShowStatus('');
  end;
  if Local = '' then
  begin
    ShowMessage('Der Installer konnte nicht geladen werden:' + LineEnding + Err);
    Exit;
  end;
  {$IFDEF WINDOWS}
  // Installer starten und PLIB beenden, damit die Dateien ersetzt werden koennen
  P := TProcess.Create(nil);
  try
    P.Executable := Local;
    P.Execute;
  finally
    P.Free;
  end;
  Application.Terminate;
  {$ELSE}
  P := nil;
  OpenDocument(Local);
  ShowMessage('Der Installer wurde geöffnet. Beende PLIB und installiere die neue Version.');
  {$ENDIF}
end;

procedure TMainForm.AsyncBuild(Data: PtrInt);
begin
  DockMgr.Rebuild;
end;

procedure TMainForm.DockChanged(Sender: TObject);
var
  K: Integer;
begin
  for K := 0 to 4 do
    if Assigned(PaneItems[K]) then
      PaneItems[K].Checked := DockMgr.PaneAt(K).State <> dsHidden;
  if Assigned(MnuToolbarItem) then
    MnuToolbarItem.Checked := DockMgr.ToolbarVisible;
  if FRibbon <> nil then FRibbon.Visible := DockMgr.ToolbarVisible;
  EnsureHelpLoaded;
  UpdateClassImage;
end;

procedure TMainForm.MnuTogglePane(Sender: TObject);
var
  It: TMenuItem;
begin
  It := Sender as TMenuItem;
  DockMgr.SetPaneVisible(DockMgr.PaneAt(It.Tag).Name, It.Checked);
end;

procedure TMainForm.BtnClassImage(Sender: TObject);
var
  Cid: Int64;
  Dlg: TOpenDialog;
  Ext: string;
  Fs: TFileStream;
  Pic: TPicture;
  Q: TSQLQuery;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Bild für Klasse ' + RowStr('class', 'code', Cid) + ' wählen';
    Dlg.Filter := 'Bilder (png, jpg, bmp, gif)|*.png;*.jpg;*.jpeg;*.bmp;*.gif|Alle Dateien|*.*';
    if not Dlg.Execute then Exit;
    Ext := LowerCase(ExtractFileExt(Dlg.FileName));
    if Pos('|' + Ext + '|', '|.png|.jpg|.jpeg|.bmp|.gif|') = 0 then
    begin
      ShowMessage('Unterstützt werden png, jpg, bmp und gif.');
      Exit;
    end;
    Pic := TPicture.Create;
    try
      try
        Pic.LoadFromFile(Dlg.FileName);
      except
        ShowMessage('Die Datei lässt sich nicht als Bild lesen.');
        Exit;
      end;
    finally
      Pic.Free;
    end;
    Fs := TFileStream.Create(Dlg.FileName, fmOpenRead or fmShareDenyNone);
    try
      if Fs.Size > 10 * 1024 * 1024 then
      begin
        ShowMessage('Das Bild ist größer als 10 MB. Bitte verkleinern.');
        Exit;
      end;
      Q := TSQLQuery.Create(nil);
      try
        Q.DataBase := DbCtx.Conn;
        Q.Transaction := DbCtx.Trans;
        if DbCtx.IsPg then
          Q.SQL.Text := 'INSERT INTO class_image(class_id, ext, data, added) ' +
            'VALUES(:cid, :ext, :dat, ' + DateSql + ') ON CONFLICT (class_id) DO UPDATE ' +
            'SET ext=EXCLUDED.ext, data=EXCLUDED.data, added=EXCLUDED.added'
        else
          Q.SQL.Text := 'INSERT OR REPLACE INTO class_image(class_id, ext, data, added) ' +
            'VALUES(:cid, :ext, :dat, ' + DateSql + ')';
        Q.ParamByName('cid').AsLargeInt := Cid;
        Q.ParamByName('ext').AsString := Ext;
        Q.ParamByName('dat').LoadFromStream(Fs, ftBlob);
        Q.ExecSQL;
        if not DbCtx.Batch then DbCtx.Trans.CommitRetaining;
      finally
        Q.Free;
      end;
    finally
      Fs.Free;
    end;
  finally
    Dlg.Free;
  end;
  UpdateClassImage;
end;

procedure TMainForm.BtnClassImageDel(Sender: TObject);
var
  Cid: Int64;
begin
  Cid := CurClass;
  if Cid = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse waehlen.');
    Exit;
  end;
  if ScalarInt('SELECT COUNT(*) FROM class_image WHERE class_id=' + IntToStr(Cid)) = 0 then
  begin
    ShowMessage('Diese Klasse hat kein eigenes Bild. ' +
      'Ein angezeigtes Bild gehört einer Oberklasse.');
    Exit;
  end;
  if MessageDlg('Das Bild dieser Klasse entfernen?', mtConfirmation, [mbYes, mbNo], 0) <>
    mrYes then Exit;
  Exec('DELETE FROM class_image WHERE class_id=' + IntToStr(Cid));
  UpdateClassImage;
end;

procedure TMainForm.ImgSaveAs(Sender: TObject);
var
  Cid, PicOwner: Int64;
  Ms: TMemoryStream;
  Ext: string;
  Dlg: TSaveDialog;
begin
  Cid := CurClass;
  if Cid = 0 then Exit;
  Ms := TMemoryStream.Create;
  try
    if not ReadClassImage(Cid, Ms, Ext, PicOwner) then
    begin
      ShowMessage('Kein Bild vorhanden.');
      Exit;
    end;
    Dlg := TSaveDialog.Create(Self);
    try
      Dlg.FileName := RowStr('class', 'code', PicOwner) + Ext;
      Dlg.Filter := 'Bild|*' + Ext;
      if Dlg.Execute then Ms.SaveToFile(Dlg.FileName);
    finally
      Dlg.Free;
    end;
  finally
    Ms.Free;
  end;
end;

procedure TMainForm.TreeMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  N: TTreeNode;
begin
  N := Tree.GetNodeAt(X, Y);
  if N = FHintNode then Exit;
  FHintNode := N;
  if N = nil then
    Tree.Hint := ''
  else
    Tree.Hint := TreeHintText(N);
  Application.CancelHint;
end;

{ ---------- Statusleiste, Vorschlaege, Bedienkomfort ---------- }

procedure TMainForm.UpdateStatus;
var
  Cid: Int64;
  N: Integer;
begin
  if SBar = nil then Exit;
  Cid := CurClass;
  if Cid = 0 then
    SBar.Panels[0].Text := 'Keine Klasse gewählt'
  else
    SBar.Panels[0].Text := 'Klasse ' + RowStr('class', 'class_no', Cid) + '  ' +
      RowStr('class', 'code', Cid) + ' - ' + RowStr('class', 'name', Cid);
  N := GridParts.RowCount - 1;
  if N < 0 then N := 0;
  if FPartsCapped then
    SBar.Panels[1].Text := 'Teile: ' + IntToStr(N) + '+ (gekürzt)'
  else
    SBar.Panels[1].Text := 'Teile: ' + IntToStr(N);
  if CurPart <> 0 then
    SBar.Panels[2].Text := 'Teil: ' + CellBy(GridParts, 'Teilenummer', GridParts.Row)
  else
    SBar.Panels[2].Text := '';
end;

procedure TMainForm.ShowStatus(const AMsg: string);
begin
  if SBar <> nil then SBar.Panels[3].Text := AMsg;
end;

{ Vorschlag fuer den Namen einer neuen (Unter-)Klasse }
function TMainForm.SuggestClassName(AParent: Int64): string;
var
  Base: string;
  n: Integer;
begin
  if AParent = 0 then
  begin
    Base := 'Neue Klasse';
    n := Integer(ScalarInt('SELECT COUNT(*) FROM class WHERE parent_id IS NULL')) + 1;
  end
  else
  begin
    Base := RowStr('class', 'name', AParent) + ' - Unterklasse';
    n := Integer(ScalarInt('SELECT COUNT(*) FROM class WHERE parent_id=' +
      IntToStr(AParent))) + 1;
  end;
  repeat
    Result := Base + ' ' + IntToStr(n);
    Inc(n);
  until ScalarInt('SELECT COUNT(*) FROM class WHERE name=' + QuotedStr(Result)) = 0;
end;

{ Vorschlag fuer den Code: Code der Oberklasse plus laufende Nummer (SCHR01, SCHR02 ...) }
function TMainForm.SuggestClassCode(AParent: Int64): string;
var
  Base: string;
  n: Integer;
begin
  if AParent = 0 then
  begin
    Base := 'KL';
    n := Integer(ScalarInt('SELECT COUNT(*) FROM class WHERE parent_id IS NULL')) + 1;
  end
  else
  begin
    Base := Copy(RowStr('class', 'code', AParent), 1, 30);
    n := Integer(ScalarInt('SELECT COUNT(*) FROM class WHERE parent_id=' +
      IntToStr(AParent))) + 1;
  end;
  repeat
    Result := Base + Format('%.2d', [n]);
    Inc(n);
  until not CodeTaken('class', Result, 0);
end;

procedure TMainForm.TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key in [VK_UP, VK_DOWN, VK_LEFT, VK_RIGHT, VK_PRIOR, VK_NEXT, VK_HOME, VK_END] then
    FTreeKeyTick := GetTickCount64;
  case Key of
    VK_INSERT:
      begin
        Key := 0;
        BtnNewClass(nil);
      end;
    VK_DELETE:
      begin
        Key := 0;
        BtnDelClass(nil);
      end;
    VK_RETURN:
      begin
        Key := 0;
        if GridParts.CanFocus then GridParts.SetFocus;
      end;
  end;
end;

procedure TMainForm.ValuesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
      begin
        Key := 0;
        MnuValueEdit(nil);
      end;
    VK_ESCAPE:
      begin
        Key := 0;
        if GridParts.CanFocus then GridParts.SetFocus;
      end;
  end;
end;

procedure TMainForm.MnuRefresh(Sender: TObject);
begin
  LoadTree(0);
  UpdateClassImage;
  ShowStatus('Aktualisiert.');
end;

{ ---------- Sortierung der Teileliste (Klick auf die Spaltenueberschrift) ---------- }

procedure TMainForm.PartsCompare(Sender: TObject; ACol, ARow, BCol, BRow: Integer;
  var Result: Integer);
var
  A, B: string;
  DA, DB: Double;
begin
  A := GridParts.Cells[ACol, ARow];
  B := GridParts.Cells[BCol, BRow];
  if ParseNum(A, DA) and ParseNum(B, DB) then
  begin
    if DA < DB then Result := -1
    else if DA > DB then Result := 1
    else Result := 0;
  end
  else
    Result := CompareText(A, B);
  if not FSortAsc then Result := -Result;
end;

procedure TMainForm.ApplyPartSort;
var
  ci: Integer;
begin
  if (FSortName = '') or (GridParts.RowCount < 3) then Exit;
  ci := ColIdx(GridParts, FSortName);
  if ci < 0 then Exit;
  GridParts.SortOrder := soAscending;
  GridParts.SortColRow(True, ci);
end;

procedure TMainForm.PartsHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
var
  Keep: Int64;
  Dir: string;
begin
  if not IsColumn then Exit;
  Keep := CurPart;
  if SameText(FSortName, GridParts.Cells[Index, 0]) then
    FSortAsc := not FSortAsc
  else
  begin
    FSortName := GridParts.Cells[Index, 0];
    FSortAsc := True;
  end;
  ApplyPartSort;
  if Keep <> 0 then SelectPart(Keep);
  if FSortAsc then Dir := ' (aufsteigend)' else Dir := ' (absteigend)';
  ShowStatus('Sortiert nach "' + GridParts.Cells[Index, 0] + '"' + Dir);
end;

{ ---------- Sicherheit: Sitzungsdatei, automatische Sicherung, Pruefung ---------- }

function TMainForm.SessionFileName: string;
begin
  Result := DataDir + 'plib.session';
end;

procedure TMainForm.CreateSessionFile;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    try
      L.SaveToFile(SessionFileName);
    except
      // Ordner nicht beschreibbar: die Absturzerkennung entfaellt dann
    end;
  finally
    L.Free;
  end;
end;

function TMainForm.BackupDir: string;
begin
  Result := ExtractFilePath(DbCtx.Conn.DatabaseName) + 'backup' + PathDelim;
end;

procedure TMainForm.BackupList(AList: TStrings);
var
  SR: TSearchRec;
begin
  AList.Clear;
  if FindFirst(BackupDir + BackupPrefix + '*.sqlite3', faAnyFile, SR) = 0 then
  begin
    repeat
      AList.Add(SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  TStringList(AList).Sort;
end;

function TMainForm.NewestBackup: string;
var
  L: TStringList;
begin
  Result := '';
  L := TStringList.Create;
  try
    BackupList(L);
    if L.Count > 0 then Result := BackupDir + L[L.Count - 1];
  finally
    L.Free;
  end;
end;

{ Legt eine Sicherung im Ordner backup an und behaelt die 20 neuesten }
procedure TMainForm.MakeAutoBackup;
var
  L: TStringList;
  i: Integer;
begin
  try
    ForceDirectories(BackupDir);
    CopyFileStream(DbCtx.Conn.DatabaseName,
      BackupDir + BackupPrefix + FormatDateTime('yyyymmdd_hhnnss', Now) + '.sqlite3');
    L := TStringList.Create;
    try
      BackupList(L);
      for i := 0 to L.Count - 21 do
        DeleteFile(BackupDir + L[i]);
    finally
      L.Free;
    end;
  except
    // Sicherung ist zusaetzlich; ein Fehler hier darf den Start nicht verhindern
  end;
end;

procedure TMainForm.RestoreFromBackup(const ABackup: string);
var
  Bad: string;
begin
  if DbCtx.Trans.Active then DbCtx.Trans.Rollback;
  DbCtx.Conn.Close;
  Bad := DbCtx.Conn.DatabaseName + '.defekt_' + FormatDateTime('yyyymmdd_hhnnss', Now);
  RenameFile(DbCtx.Conn.DatabaseName, Bad);
  CopyFileStream(ABackup, DbCtx.Conn.DatabaseName);
  DbCtx.Conn.Open;
  DbCtx.Trans.StartTransaction;
end;

{ Prueft die Datenbank beim Start; bei Schaeden wird die letzte Sicherung angeboten }
procedure TMainForm.CheckDatabase(AWasCrash: Boolean);
var
  R, Bk: string;
begin
  if DbCtx.IsPg then Exit;
  try
    R := ScalarStr('PRAGMA integrity_check');
  except
    on E: Exception do R := E.Message;
  end;
  if R = 'ok' then
  begin
    if AWasCrash then
      ShowMessage('Das Programm wurde beim letzten Mal nicht ordnungsgemäß beendet.' +
        LineEnding + 'Die Datenbank wurde geprüft und ist in Ordnung.');
    MakeAutoBackup;
    Exit;
  end;
  Bk := NewestBackup;
  if Bk = '' then
  begin
    ShowMessage('Die Datenbank scheint beschädigt zu sein:' + LineEnding + R +
      LineEnding + LineEnding + 'Es ist noch keine automatische Sicherung vorhanden.');
    Exit;
  end;
  if MessageDlg('Die Datenbank scheint beschädigt zu sein:' + LineEnding + R +
    LineEnding + LineEnding + 'Soll die letzte automatische Sicherung wiederhergestellt ' +
    'werden? (' + ExtractFileName(Bk) + ')' + LineEnding +
    'Die beschädigte Datei bleibt als *.defekt_... erhalten.',
    mtError, [mbYes, mbNo], 0) = mrYes then
    RestoreFromBackup(Bk);
end;

procedure TMainForm.MnuCheckDb(Sender: TObject);
var
  R: string;
begin
  if PgNoFile then Exit;
  R := ScalarStr('PRAGMA integrity_check');
  if R = 'ok' then
    ShowMessage('Die Datenbank wurde geprüft und ist in Ordnung.')
  else
    ShowMessage('Die Prüfung meldet ein Problem:' + LineEnding + R + LineEnding +
      LineEnding + 'Mit „Datei, Sicherung wiederherstellen" kannst du eine ältere ' +
      'Sicherung laden.');
end;

procedure TMainForm.MnuRestore(Sender: TObject);
var
  L, Items: TStringList;
  Idx, i: Integer;
begin
  if PgNoFile then Exit;
  L := TStringList.Create;
  Items := TStringList.Create;
  try
    BackupList(L);
    if L.Count = 0 then
    begin
      ShowMessage('Es gibt noch keine automatischen Sicherungen.');
      Exit;
    end;
    for i := L.Count - 1 downto 0 do Items.Add(L[i]);
    Idx := PickIndex('Sicherung wiederherstellen',
      'Wähle die Sicherung (neueste zuerst). Der Dateiname enthält Datum und Uhrzeit.',
      Items, 0);
    if Idx < 0 then Exit;
    if MessageDlg('Die aktuelle Datenbank wird durch die Sicherung ersetzt und als ' +
      '*.defekt_... aufgehoben. Fortfahren?', mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;
    RestoreFromBackup(BackupDir + Items[Idx]);
  finally
    L.Free;
    Items.Free;
  end;
  MigrateSchema;
  MigrateSchema2;
  LoadTree(0);
  UpdateClassImage;
  ShowStatus('Sicherung wiederhergestellt.');
end;

procedure TMainForm.MnuOpenBackupDir(Sender: TObject);
begin
  if PgNoFile then Exit;
  ForceDirectories(BackupDir);
  OpenDocument(BackupDir);
end;

procedure TMainForm.MnuShowLog(Sender: TObject);
var
  LogName: string;
begin
  LogName := DataDir + 'plib_error.log';
  if FileExists(LogName) then
    OpenDocument(LogName)
  else
    ShowMessage('Es gibt noch kein Fehlerprotokoll. Bisher ist kein Fehler aufgetreten.');
end;

{ ---------- Fehlerbehandlung ---------- }

function TMainForm.FriendlyError(E: Exception): string;
var
  M, L: string;
begin
  M := E.Message;
  L := LowerCase(M);
  if Pos('libpq', L) > 0 then
    Result := 'Die PostgreSQL-Bibliothek libpq.dll wurde nicht gefunden. Kopiere libpq.dll ' +
      'und die zugehörigen DLLs (z. B. aus dem Ordner runtime von pgAdmin 4) neben die plib.exe.'
  else if Pos('password authentication failed', L) > 0 then
    Result := 'Benutzername oder Passwort sind falsch.'
  else if (Pos('could not connect', L) > 0) or (Pos('connection refused', L) > 0) or
    (Pos('timeout', L) > 0) or (Pos('timed out', L) > 0) or
    (Pos('could not translate host', L) > 0) then
    Result := 'Der PostgreSQL-Server ist nicht erreichbar. Prüfe Adresse, Port, ob der ' +
      'Container läuft und ob die Firewall des NAS den Port erlaubt.'
  else if (Pos('database "', L) > 0) and (Pos('does not exist', L) > 0) then
    Result := 'Die angegebene Datenbank gibt es auf dem Server nicht.'
  else if Pos('unique constraint', L) > 0 then
    Result := 'Ein Eintrag mit diesem Code oder dieser Nummer existiert bereits.'
  else if (Pos('locked', L) > 0) or (Pos('busy', L) > 0) then
    Result := 'Die Datenbank ist gesperrt. Wird sie gerade von einem anderen Programm benutzt?'
  else if Pos('readonly', L) > 0 then
    Result := 'Die Datenbank ist schreibgeschützt. Prüfe die Rechte des Programmordners.'
  else if (Pos('malformed', L) > 0) or (Pos('not a database', L) > 0) or
    (Pos('disk i/o', L) > 0) then
    Result := 'Die Datenbank ist beschädigt. Mit „Datei, Sicherung wiederherstellen" ' +
      'kannst du eine ältere Sicherung laden.'
  else if (Pos('no such table', L) > 0) or (Pos('no such column', L) > 0) then
    Result := 'Die Datenbank hat eine unerwartete Struktur. Bitte das Programm neu starten.'
  else if E is EAccessViolation then
    Result := 'Interner Programmfehler (Speicherzugriff).'
  else
    Result := M;
  Result := Result + LineEnding + LineEnding + '(' + E.ClassName + ': ' + M + ')';
end;

{ Zeigt unbehandelte Fehler verstaendlich, protokolliert sie in plib_error.log und
  bricht Fehlerschleifen ab }
procedure TMainForm.AppException(Sender: TObject; E: Exception);
var
  F: TextFile;
  LogName, Msg: string;
  Fatal: Boolean;
  Tick: QWord;
begin
  try
    try
      // eine durch den Fehler abgebrochene Transaktion (PostgreSQL) zuruecksetzen
      if Assigned(DbCtx.Trans) and DbCtx.Trans.Active then DbCtx.Trans.RollbackRetaining;
    except
      // Verbindung evtl. verloren
    end;
    Tick := GetTickCount64;
    if Tick - FErrTick < 1500 then Inc(FErrCount) else FErrCount := 1;
    FErrTick := Tick;

    LogName := DataDir + 'plib_error.log';
    try
      AssignFile(F, LogName);
      if FileExists(LogName) then Append(F) else Rewrite(F);
      try
        WriteLn(F, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), '  ', E.ClassName, ': ',
          E.Message);
        WriteLn(F, '    Adresse: ', BackTraceStrFunc(ExceptAddr));
      finally
        CloseFile(F);
      end;
    except
      // Protokoll nicht schreibbar: die Meldung wird trotzdem gezeigt
    end;

    if FErrCount > 5 then
    begin
      ShowMessage('Das Programm meldet wiederholt Fehler und wird beendet.' + LineEnding +
        'Alle bisherigen Änderungen sind gespeichert. Details: plib_error.log');
      Application.Terminate;
      Exit;
    end;

    Fatal := (E is EAccessViolation) or (E is EInvalidPointer) or (E is EOutOfMemory);
    Msg := FriendlyError(E);
    if Fatal then
    begin
      if MessageDlg('Schwerer Programmfehler' + LineEnding + LineEnding + Msg +
        LineEnding + LineEnding + 'Das Programm sollte beendet und neu gestartet werden. ' +
        'Alle bisherigen Änderungen sind gespeichert. Jetzt beenden?',
        mtError, [mbYes, mbNo], 0) = mrYes then
        Application.Terminate;
    end
    else
      ShowMessage(Msg);
  except
    // Fehler im Fehlerbehandler: nichts weiter tun
  end;
end;

{ ---------- Datenbankpfad ---------- }

function TMainForm.DefaultDbPath: string;
begin
  Result := DataDir + 'plib.sqlite3';
end;

{ Relative Pfade gelten ab dem Programmordner }
function TMainForm.AbsDbPath(const P: string): string;
begin
  Result := Trim(P);
  if Result = '' then Exit;
  if not ((Length(Result) > 1) and ((Result[2] = ':') or (Result[1] = '\') or
    (Result[1] = '/'))) then
    Result := DataDir + Result;
end;

{ Reihenfolge: Programmparameter (Pfad oder --db=Pfad), plib.ini [Datenbank] Pfad=,
  sonst plib.sqlite3 neben dem Programm }
function TMainForm.ResolveDbPath: string;
var
  Ini: TIniFile;
  P: string;
begin
  P := '';
  if ParamCount >= 1 then
  begin
    P := ParamStr(1);
    if Copy(P, 1, 4) = '-psn' then P := '';
    if Copy(LowerCase(P), 1, 5) = '--db=' then P := Copy(P, 6, MaxInt);
  end;
  if P = '' then
  begin
    Ini := TIniFile.Create(IniName);
    try
      P := Ini.ReadString('Datenbank', 'Pfad', '');
    finally
      Ini.Free;
    end;
  end;
  P := AbsDbPath(P);
  if P = '' then P := DefaultDbPath;
  if not DirectoryExists(ExtractFilePath(P)) then
  begin
    if MessageDlg('Der Ordner der Datenbank ist nicht erreichbar:' + LineEnding + P +
      LineEnding + LineEnding + 'Stattdessen die Standard-Datenbank neben dem Programm ' +
      'verwenden?', mtWarning, [mbYes, mbNo], 0) = mrYes then
      P := DefaultDbPath
    else
      Halt(1);
  end;
  Result := P;
end;

procedure TMainForm.SaveDbPath(const AFile: string);
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(IniName);
    try
      if SameText(AFile, DefaultDbPath) then
        Ini.DeleteKey('Datenbank', 'Pfad')
      else
        Ini.WriteString('Datenbank', 'Pfad', AFile);
      Ini.WriteString('Datenbank', 'Typ', 'sqlite');
    finally
      Ini.Free;
    end;
  except
    ShowMessage('Der neue Datenbankpfad konnte nicht in plib.ini gespeichert werden. ' +
      'Beim nächsten Start wird wieder die bisherige Einstellung verwendet.');
  end;
end;

procedure TMainForm.UpdateDbInfo;
begin
  if DbCtx.IsPg then
  begin
    Caption := 'Teilebibliothek (ISO 13584 / PLIB) - PostgreSQL ' + PgDb + '@' + PgHost +
      '  [Version ' + AppVersion + ']';
    if SBar <> nil then
      SBar.Panels[4].Text := 'DB: PostgreSQL ' + ShortenPath(PgHost + ':' + PgPort + '/' + PgDb, 36);
  end
  else
  begin
    Caption := 'Teilebibliothek (ISO 13584 / PLIB) - ' +
      ExtractFileName(DbCtx.Conn.DatabaseName) + '  [Version ' + AppVersion + ']';
    if SBar <> nil then
      SBar.Panels[4].Text := 'DB: ' + ShortenPath(DbCtx.Conn.DatabaseName, 44);
  end;
end;

function TMainForm.BackupPrefix: string;
begin
  Result := ChangeFileExt(ExtractFileName(DbCtx.Conn.DatabaseName), '') + '_';
end;

{ Legt Tabellen an und aktualisiert aeltere Datenbanken }
procedure TMainForm.PrepareDatabase;
begin
  Exec('CREATE TABLE IF NOT EXISTS class(' +
    'id ' + PkType + ', code TEXT NOT NULL UNIQUE, ' +
    'name TEXT NOT NULL, parent_id INTEGER REFERENCES class(id), definition TEXT)');
  Exec('CREATE TABLE IF NOT EXISTS property(' +
    'id ' + PkType + ', code TEXT NOT NULL UNIQUE, ' +
    'name TEXT NOT NULL, datatype TEXT NOT NULL DEFAULT ''string'', ' +
    'unit TEXT, definition TEXT)');
  Exec('CREATE TABLE IF NOT EXISTS class_property(' +
    'class_id INTEGER NOT NULL, property_id INTEGER NOT NULL, ' +
    'PRIMARY KEY(class_id, property_id))');
  Exec('CREATE TABLE IF NOT EXISTS part(' +
    'id ' + PkType + ', class_id INTEGER NOT NULL, ' +
    'part_number TEXT NOT NULL UNIQUE, description TEXT)');
  Exec('CREATE TABLE IF NOT EXISTS part_value(' +
    'part_id INTEGER NOT NULL, property_id INTEGER NOT NULL, value TEXT, ' +
    'PRIMARY KEY(part_id, property_id))');
  MigrateSchema;
  MigrateSchema2;
end;

{ Bei leerer Datenbank Beispielklassen anbieten (am Standardort automatisch) }
procedure TMainForm.OfferSeed;
begin
  if ScalarInt('SELECT COUNT(*) FROM class') > 0 then Exit;
  if SameText(DbCtx.Conn.DatabaseName, DefaultDbPath) or
    (MessageDlg('Die Datenbank ist leer. Sollen Beispielklassen (Normteil, Schraube, ' +
    'Sechskantschraube) angelegt werden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    SeedIfEmpty;
end;

{ Wechselt im laufenden Betrieb auf eine andere Datenbankdatei }
procedure TMainForm.SwitchDatabase(const ANewPath: string);
var
  OldPath: string;
begin
  OldPath := DbCtx.Conn.DatabaseName;
  try
    if DbCtx.Trans.Active then DbCtx.Trans.Commit;
    DbCtx.Conn.Close;
    ForceDirectories(ExtractFilePath(ANewPath));
    DbCtx.Conn.DatabaseName := ANewPath;
    DbCtx.Conn.Open;
    DbCtx.Trans.StartTransaction;
    CheckDatabase(False);
    PrepareDatabase;
    OfferSeed;
  except
    on E: Exception do
    begin
      try
        if DbCtx.Trans.Active then DbCtx.Trans.Rollback;
        DbCtx.Conn.Close;
      except
        // schon geschlossen
      end;
      DbCtx.Conn.DatabaseName := OldPath;
      DbCtx.Conn.Open;
      DbCtx.Trans.StartTransaction;
      ShowMessage('Die Datenbank konnte nicht geöffnet werden:' + LineEnding + E.Message +
        LineEnding + LineEnding + 'Es wird wieder die bisherige Datenbank verwendet.');
      LoadTree(0);
      Exit;
    end;
  end;
  SaveDbPath(ANewPath);
  UpdateDbInfo;
  LoadTree(0);
  UpdateClassImage;
  ShowStatus('Datenbank gewechselt.');
end;

procedure TMainForm.MnuDbPath(Sender: TObject);
var
  Items: TStringList;
  Idx: Integer;
  OpenDlg: TOpenDialog;
  SaveDlg: TSaveDialog;
  Target: string;
begin
  if DbCtx.IsPg then
  begin
    PgSwitchBack;
    Exit;
  end;
  Items := TStringList.Create;
  try
    Items.Add('Andere vorhandene Datenbank öffnen ...');
    Items.Add('Neue, leere Datenbank an einem Ort anlegen ...');
    Items.Add('Aktuelle Datenbank kopieren und die Kopie verwenden ...');
    Items.Add('Zurück zum Standardort (neben dem Programm)');
    Idx := PickIndex('Datenbank wechseln',
      'Aktuelle Datenbank:' + LineEnding + DbCtx.Conn.DatabaseName + LineEnding + LineEnding +
      'Die Einstellung wird in plib.ini gespeichert und gilt ab dem nächsten Start ' +
      'weiter. Ein Programmparameter (plib.exe "Pfad") hat Vorrang.', Items, 0);
  finally
    Items.Free;
  end;
  case Idx of
    0: begin
         OpenDlg := TOpenDialog.Create(Self);
         try
           OpenDlg.Title := 'Datenbank öffnen';
           OpenDlg.Filter := 'SQLite-Datenbanken (*.sqlite3;*.sqlite;*.db)|' +
             '*.sqlite3;*.sqlite;*.db|Alle Dateien|*.*';
           OpenDlg.InitialDir := ExtractFilePath(DbCtx.Conn.DatabaseName);
           OpenDlg.Options := OpenDlg.Options + [ofFileMustExist];
           if OpenDlg.Execute then SwitchDatabase(OpenDlg.FileName);
         finally
           OpenDlg.Free;
         end;
       end;
    1: begin
         SaveDlg := TSaveDialog.Create(Self);
         try
           SaveDlg.Title := 'Neue Datenbank anlegen';
           SaveDlg.Filter := 'SQLite-Datenbank (*.sqlite3)|*.sqlite3';
           SaveDlg.DefaultExt := 'sqlite3';
           SaveDlg.FileName := 'teilebibliothek.sqlite3';
           SaveDlg.InitialDir := ExtractFilePath(DbCtx.Conn.DatabaseName);
           if SaveDlg.Execute then
           begin
             Target := SaveDlg.FileName;
             if FileExists(Target) then
               if MessageDlg('Diese Datei gibt es schon. Soll sie als vorhandene ' +
                 'Datenbank geöffnet werden? (Es wird nichts überschrieben.)',
                 mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
             SwitchDatabase(Target);
           end;
         finally
           SaveDlg.Free;
         end;
       end;
    2: begin
         SaveDlg := TSaveDialog.Create(Self);
         try
           SaveDlg.Title := 'Kopie der Datenbank speichern unter';
           SaveDlg.Filter := 'SQLite-Datenbank (*.sqlite3)|*.sqlite3';
           SaveDlg.DefaultExt := 'sqlite3';
           SaveDlg.FileName := ExtractFileName(DbCtx.Conn.DatabaseName);
           if SaveDlg.Execute then
           begin
             Target := SaveDlg.FileName;
             if FileExists(Target) then
             begin
               ShowMessage('Diese Datei gibt es schon. Es wird nichts überschrieben. ' +
                 'Bitte einen anderen Namen wählen.');
               Exit;
             end;
             if DbCtx.Trans.Active then DbCtx.Trans.CommitRetaining;
             ForceDirectories(ExtractFilePath(Target));
             CopyFileStream(DbCtx.Conn.DatabaseName, Target);
             SwitchDatabase(Target);
           end;
         finally
           SaveDlg.Free;
         end;
       end;
    3: SwitchDatabase(DefaultDbPath);
  end;
end;

{ ---------- Datenbank-Dialekte (SQLite / PostgreSQL) ---------- }

{ ---------- PostgreSQL: Verbindung, Einstellungen, Datenuebernahme ---------- }

{ Liest Datenbanktyp und PostgreSQL-Zugang aus plib.ini }
procedure TMainForm.LoadDbSettings;
var
  Ini: TIniFile;
  V: TStrArr;
begin
  Ini := TIniFile.Create(IniName);
  try
    DbCtx.IsPg := SameText(Ini.ReadString('Datenbank', 'Typ', 'sqlite'), 'postgresql');
    PgHost := Ini.ReadString('Datenbank', 'PgServer', '');
    PgPort := Ini.ReadString('Datenbank', 'PgPort', '5433');
    PgDb := Ini.ReadString('Datenbank', 'PgDatenbank', 'plib');
    PgUser := Ini.ReadString('Datenbank', 'PgBenutzer', 'plib_user');
    // Passwort: bevorzugt verschluesselt (Windows-DPAPI); ein altes Klartext-Passwort wird
    // beim ersten Start verschluesselt und der Klartext aus plib.ini entfernt.
    PgPass := '';
    if not UnprotectStr(Ini.ReadString('Datenbank', 'PgPasswortGeschuetzt', ''), PgPass) then
      PgPass := '';
    if (PgPass = '') and Ini.ValueExists('Datenbank', 'PgPasswort') then
    begin
      PgPass := Ini.ReadString('Datenbank', 'PgPasswort', '');
      if (PgPass <> '') and (ProtectStr(PgPass) <> '') then
      begin
        Ini.WriteString('Datenbank', 'PgPasswortGeschuetzt', ProtectStr(PgPass));
        Ini.DeleteKey('Datenbank', 'PgPasswort');
      end;
    end;
  finally
    Ini.Free;
  end;
  {$IFDEF DARWIN}
  DbCtx.IsPg := False;   // die Mac-Version arbeitet nur mit einer lokalen SQLite-Datei
  {$ENDIF}
  if (ParamCount >= 1) and ((Copy(ParamStr(1), 1, 2) <> '--') or
    (Copy(LowerCase(ParamStr(1)), 1, 5) = '--db=')) then
    DbCtx.IsPg := False;
  if DbCtx.IsPg and (PgPass = '') then
  begin
    SetLength(V, 2);
    V[0] := '';
    V[1] := 'Nein';
    if not EditFields('PostgreSQL-Anmeldung',
      ['Passwort für ' + PgUser + ' auf ' + PgHost + ':',
       'Passwort speichern (verschlüsselt für dein Windows-Konto)'],
      ['password', 'check'], V) then
      Halt(1);
    PgPass := V[0];
    if V[1] = 'Ja' then
      SavePgSettings(PgHost, PgPort, PgDb, PgUser, PgPass, True);
  end;
end;

procedure TMainForm.SavePgSettings(const AHost, APort, ADb, AUser, APass: string;
  AStorePw: Boolean);
var
  Ini: TIniFile;
  Prot: string;
begin
  Ini := TIniFile.Create(IniName);
  try
    Ini.WriteString('Datenbank', 'Typ', 'postgresql');
    Ini.WriteString('Datenbank', 'PgServer', AHost);
    Ini.WriteString('Datenbank', 'PgPort', APort);
    Ini.WriteString('Datenbank', 'PgDatenbank', ADb);
    Ini.WriteString('Datenbank', 'PgBenutzer', AUser);
    Ini.DeleteKey('Datenbank', 'PgPasswort');
    Ini.DeleteKey('Datenbank', 'PgPasswortGeschuetzt');
    if AStorePw then
    begin
      Prot := ProtectStr(APass);
      if Prot <> '' then
        Ini.WriteString('Datenbank', 'PgPasswortGeschuetzt', Prot)   // Windows: verschluesselt
      else
        Ini.WriteString('Datenbank', 'PgPasswort', APass);           // ohne DPAPI (macOS)
    end;
  finally
    Ini.Free;
  end;
end;

function TMainForm.DbDescription: string;
begin
  if DbCtx.IsPg then
    Result := 'PostgreSQL ' + PgHost + ':' + PgPort + '/' + PgDb + ' (Benutzer ' + PgUser + ')'
  else
    Result := DbCtx.Conn.DatabaseName;
end;

procedure TMainForm.MnuPgConnect(Sender: TObject);
var
  V: TStrArr;
  Test: TSQLConnection;
  Tr: TSQLTransaction;
  PortNo: Integer;
begin
  SetLength(V, 6);
  V[0] := PgHost;
  V[1] := PgPort;
  if V[1] = '' then V[1] := '5433';
  V[2] := PgDb;
  if V[2] = '' then V[2] := 'plib';
  V[3] := PgUser;
  if V[3] = '' then V[3] := 'plib_user';
  V[4] := '';
  V[5] := 'Nein';
  if not EditFields('Verbindung zu PostgreSQL',
    ['Server (IP-Adresse oder Name des NAS):', 'Port:', 'Datenbank:', 'Benutzer:',
     'Passwort:', 'Passwort speichern (verschlüsselt für dein Windows-Konto)'],
    ['text', 'text', 'text', 'text', 'password', 'check'], V) then Exit;
  V[0] := Trim(V[0]);
  V[1] := Trim(V[1]);
  V[2] := Trim(V[2]);
  V[3] := Trim(V[3]);
  if (V[0] = '') or (V[2] = '') or (V[3] = '') or (not TryStrToInt(V[1], PortNo)) or
    (PortNo < 1) or (PortNo > 65535) then
  begin
    ShowMessage('Bitte Server, Port (1 bis 65535), Datenbank und Benutzer ausfüllen.');
    Exit;
  end;
  Screen.Cursor := crHourGlass;
  try
    Test := NewPgConnection(nil, V[0], V[1], V[2], V[3], V[4]);
    Tr := TSQLTransaction.Create(nil);
    try
      try
        Test.Transaction := Tr;
        Tr.DataBase := Test;
        Test.Open;
        Tr.StartTransaction;
        Test.ExecuteDirect('SELECT 1');
        Tr.Rollback;
        Test.Close;
      except
        on E: Exception do
        begin
          Screen.Cursor := crDefault;
          ShowMessage('Die Verbindung hat nicht geklappt:' + LineEnding + LineEnding +
            FriendlyError(E));
          Exit;
        end;
      end;
    finally
      Tr.Free;
      Test.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  SavePgSettings(V[0], V[1], V[2], V[3], V[4], V[5] = 'Ja');
  ShowMessage('Die Verbindung funktioniert und wurde gespeichert.' + LineEnding + LineEnding +
    'Das Programm wird jetzt beendet. Starte es bitte neu, dann arbeitet es mit dem ' +
    'PostgreSQL-Server. Danach kannst du über „Datei, Daten aus SQLite-Datei nach ' +
    'PostgreSQL übernehmen" deine bisherigen Daten übertragen.');
  Close;
end;

{ Kopiert eine Tabelle von einer Datenbank in eine andere (SQLite <-> PostgreSQL) }
procedure TMainForm.CopyTable(ASrc: TSQLConnection; ASrcTr: TSQLTransaction;
  ADst: TSQLConnection; ADstTr: TSQLTransaction; const ATable, AOrder: string);
var
  QS, QI: TSQLQuery;
  i: Integer;
  Cols, Pars: string;
  F: TField;
  Ms: TMemoryStream;
begin
  QS := TSQLQuery.Create(nil);
  QI := TSQLQuery.Create(nil);
  try
    QS.DataBase := ASrc;
    QS.Transaction := ASrcTr;
    if ASrc is TSQLite3Connection then
    begin
      QS.SQL.Text := 'SELECT COUNT(*) FROM sqlite_master WHERE type=''table'' AND name=' +
        QuotedStr(ATable);
      QS.Open;
      if QS.Fields[0].AsLargeInt = 0 then Exit;   // Tabelle gibt es in der Quelle nicht
      QS.Close;
    end;
    QS.SQL.Text := 'SELECT * FROM ' + ATable + ' ORDER BY ' + AOrder;
    QS.Open;
    Cols := '';
    Pars := '';
    for i := 0 to QS.FieldCount - 1 do
    begin
      if i > 0 then
      begin
        Cols := Cols + ',';
        Pars := Pars + ',';
      end;
      Cols := Cols + QS.Fields[i].FieldName;
      Pars := Pars + ':p' + IntToStr(i);
    end;
    QI.DataBase := ADst;
    QI.Transaction := ADstTr;
    QI.SQL.Text := 'INSERT INTO ' + ATable + '(' + Cols + ') VALUES(' + Pars + ')';
    while not QS.EOF do
    begin
      for i := 0 to QS.FieldCount - 1 do
      begin
        F := QS.Fields[i];
        if F.IsNull then
          QI.Params[i].Clear
        else
          case F.DataType of
            ftSmallint, ftInteger, ftLargeint, ftWord, ftAutoInc:
              QI.Params[i].AsLargeInt := F.AsLargeInt;
            ftFloat, ftCurrency, ftBCD, ftFMTBcd:
              QI.Params[i].AsFloat := F.AsFloat;
            ftBlob:
              begin
                Ms := TMemoryStream.Create;
                try
                  TBlobField(F).SaveToStream(Ms);
                  Ms.Position := 0;
                  QI.Params[i].LoadFromStream(Ms, ftBlob);
                finally
                  Ms.Free;
                end;
              end;
          else
            QI.Params[i].AsString := FieldText(F);
          end;
      end;
      QI.ExecSQL;
      QS.Next;
      Inc(FProgDone);
      if (FProgBar <> nil) and ((FProgDone mod 25) = 0) then
      begin
        FProgBar.Position := FProgDone;
        FProgLbl.Caption := 'Tabelle ' + ATable + ' - ' + IntToStr(FProgDone) + ' von ' +
          IntToStr(FProgBar.Max) + ' Zeilen';
        Application.ProcessMessages;
      end;
    end;
    QS.Close;
  finally
    QI.Free;
    QS.Free;
  end;
end;

procedure TMainForm.MnuPgImport(Sender: TObject);
const
  Tabs: array[0..12] of string = ('supplier', 'unit', 'class', 'property',
    'class_property', 'part', 'part_value', 'enum_value', 'translation', 'class_image',
    'search_term', 'suggest_weight', 'suggest_history');
  Orders: array[0..12] of string = ('id', 'id', 'id', 'id', 'class_id, property_id', 'id',
    'part_id, property_id', 'id', 'id', 'class_id', 'id', 'wkey', 'id');
  Seqs: array[0..8] of string = ('supplier', 'unit', 'class', 'property', 'part',
    'enum_value', 'translation', 'search_term', 'suggest_history');
var
  Dlg: TOpenDialog;
  Src: TSQLite3Connection;
  SrcTr: TSQLTransaction;
  SrcPath: string;
  i: Integer;
begin
  if not DbCtx.IsPg then
  begin
    ShowMessage('Diese Funktion gibt es nur, wenn das Programm mit einem PostgreSQL-Server ' +
      'verbunden ist. Verbinde dich zuerst über „Datei, Mit PostgreSQL-Server verbinden".');
    Exit;
  end;
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'SQLite-Datenbank wählen, deren Daten übernommen werden';
    Dlg.Filter := 'SQLite-Datenbanken (*.sqlite3;*.sqlite;*.db)|*.sqlite3;*.sqlite;*.db|' +
      'Alle Dateien|*.*';
    Dlg.Options := Dlg.Options + [ofFileMustExist];
    if not Dlg.Execute then Exit;
    SrcPath := Dlg.FileName;
  finally
    Dlg.Free;
  end;
  if MessageDlg('Alle Daten auf dem PostgreSQL-Server werden gelöscht und durch die Daten ' +
    'aus dieser Datei ersetzt:' + LineEnding + SrcPath + LineEnding + LineEnding +
    'Die SQLite-Datei muss mit dieser Programmversion schon einmal geöffnet worden sein. ' +
    'Fortfahren?', mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;

  Screen.Cursor := crHourGlass;
  Src := TSQLite3Connection.Create(nil);
  SrcTr := TSQLTransaction.Create(nil);
  DbCtx.Batch := True;
  try
    try
      Src.Transaction := SrcTr;
      SrcTr.DataBase := Src;
      Src.DatabaseName := SrcPath;
      Src.Open;
      SrcTr.StartTransaction;
      Exec('TRUNCATE TABLE supplier, unit, class, property, class_property, part, ' +
        'part_value, enum_value, translation, class_image, search_term, suggest_weight, ' +
        'suggest_history RESTART IDENTITY CASCADE');
      for i := 0 to High(Tabs) do
        CopyTable(Src, SrcTr, DbCtx.Conn, DbCtx.Trans, Tabs[i], Orders[i]);
      for i := 0 to High(Seqs) do
        ScalarInt('SELECT setval(pg_get_serial_sequence(''' + Seqs[i] + ''', ''id''), ' +
          'COALESCE((SELECT MAX(id) FROM ' + Seqs[i] + '), 1), ' +
          '(SELECT COUNT(*) > 0 FROM ' + Seqs[i] + '))');
      DbCtx.Trans.CommitRetaining;
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        try
          DbCtx.Trans.RollbackRetaining;
        except
          // Verbindung evtl. schon verloren
        end;
        ShowMessage('Die Übernahme ist fehlgeschlagen. Auf dem Server wurde nichts ' +
          'verändert.' + LineEnding + LineEnding + FriendlyError(E));
        Exit;
      end;
    end;
  finally
    DbCtx.Batch := False;
    Screen.Cursor := crDefault;
    try
      if SrcTr.Active then SrcTr.Rollback;
      Src.Close;
    except
      // Quelle schon geschlossen
    end;
    SrcTr.Free;
    Src.Free;
  end;
  PrepareDatabase;
  LoadTree(0);
  UpdateClassImage;
  ShowStatus('Daten aus SQLite übernommen.');
  ShowMessage('Die Daten wurden auf den PostgreSQL-Server übernommen.');
end;

{ Schreibt alle Daten des PostgreSQL-Servers in eine neue SQLite-Datei
  (z. B. fuer einen Rechner ohne Netzwerk wie den Mac) }
procedure TMainForm.MnuPgExport(Sender: TObject);
const
  Tabs: array[0..12] of string = ('supplier', 'unit', 'class', 'property',
    'class_property', 'part', 'part_value', 'enum_value', 'translation', 'class_image',
    'search_term', 'suggest_weight', 'suggest_history');
  Orders: array[0..12] of string = ('id', 'id', 'id', 'id', 'class_id, property_id', 'id',
    'part_id, property_id', 'id', 'id', 'class_id', 'id', 'wkey', 'id');
var
  Dlg: TSaveDialog;
  Dst: TSQLite3Connection;
  DstTr: TSQLTransaction;
  OldConn: TSQLConnection;
  OldTrans: TSQLTransaction;
  OldPg: Boolean;
  Target: string;
  i: Integer;
  Ok: Boolean;
  PF: TForm;
  PLbl: TLabel;
  Total: Int64;
begin
  if not DbCtx.IsPg then
  begin
    ShowMessage('PLIB arbeitet gerade schon mit einer SQLite-Datei:' + LineEnding +
      DbCtx.Conn.DatabaseName + LineEnding + LineEnding +
      'Diese Datei kannst du direkt auf den Mac kopieren (vorher PLIB beenden) ' +
      'oder über „Datei, Datenbank sichern" eine Kopie anlegen.');
    Exit;
  end;
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Title := 'PostgreSQL-Daten als SQLite-Datei speichern';
    Dlg.Filter := 'SQLite-Datenbank (*.sqlite3)|*.sqlite3';
    Dlg.DefaultExt := 'sqlite3';
    Dlg.FileName := 'plib.sqlite3';
    if not Dlg.Execute then Exit;
    Target := Dlg.FileName;
  finally
    Dlg.Free;
  end;
  if FileExists(Target) then
  begin
    if MessageDlg('Die Datei gibt es schon:' + LineEnding + Target + LineEnding + LineEnding +
      'Überschreiben?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
    if not DeleteFile(Target) then
    begin
      ShowMessage('Die Datei lässt sich nicht ersetzen (wird sie gerade benutzt?).');
      Exit;
    end;
  end;

  // Vorab prüfen, ob die Zieldatei überhaupt angelegt werden kann
  try
    with TFileStream.Create(Target, fmCreate) do Free;
  except
    on E: Exception do
    begin
      ShowMessage('Die Zieldatei kann nicht angelegt werden:' + LineEnding + Target +
        LineEnding + LineEnding + E.Message + LineEnding + LineEnding +
        'Wähle einen Ordner, in den du schreiben darfst (z. B. Dokumente oder Desktop), ' +
        'keinen geschützten Ordner und keinen Pfad mit Sonderzeichen.');
      Exit;
    end;
  end;
  Ok := False;
  Screen.Cursor := crHourGlass;
  Dst := TSQLite3Connection.Create(nil);
  DstTr := TSQLTransaction.Create(nil);
  try
    try
      Dst.Transaction := DstTr;
      DstTr.DataBase := Dst;
      Dst.DatabaseName := Target;
      Dst.Open;
      DstTr.StartTransaction;
      if DbCtx.Trans.Active then DbCtx.Trans.CommitRetaining;
      // Tabellen in der neuen Datei mit derselben Struktur anlegen (SQLite-Dialekt)
      OldConn := DbCtx.Conn;
      OldTrans := DbCtx.Trans;
      OldPg := DbCtx.IsPg;
      try
        DbCtx.Conn := Dst;
        DbCtx.Trans := DstTr;
        DbCtx.IsPg := False;
        PrepareDatabase;
        for i := High(Tabs) downto 0 do
          Exec('DELETE FROM ' + Tabs[i]);   // automatisch angelegte Grunddaten entfernen
      finally
        DbCtx.Conn := OldConn;
        DbCtx.Trans := OldTrans;
        DbCtx.IsPg := OldPg;
      end;
      Total := 0;
      for i := 0 to High(Tabs) do
        Total := Total + ScalarInt('SELECT COUNT(*) FROM ' + Tabs[i]);
      PF := TForm.CreateNew(Self);
      try
        PF.BorderStyle := bsDialog;
        PF.BorderIcons := [];
        PF.Position := poOwnerFormCenter;
        PF.Caption := 'Export nach SQLite ...';
        PF.ClientWidth := 420;
        PF.ClientHeight := 80;
        PLbl := TLabel.Create(PF);
        PLbl.Parent := PF;
        PLbl.SetBounds(16, 12, 388, 18);
        PLbl.Caption := 'Bitte warten ...';
        FProgLbl := PLbl;
        FProgBar := TProgressBar.Create(PF);
        FProgBar.Parent := PF;
        FProgBar.SetBounds(16, 38, 388, 24);
        FProgBar.Min := 0;
        FProgBar.Max := Total + 1;
        FProgDone := 0;
        PF.Show;
        Application.ProcessMessages;
        for i := 0 to High(Tabs) do
          CopyTable(DbCtx.Conn, DbCtx.Trans, Dst, DstTr, Tabs[i], Orders[i]);
      finally
        FProgBar := nil;
        FProgLbl := nil;
        PF.Free;
      end;
      DstTr.Commit;
      Ok := True;
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        try
          if DstTr.Active then DstTr.Rollback;
        except
          // nichts weiter tun
        end;
        ShowMessage('Der Export ist fehlgeschlagen:' + LineEnding + LineEnding +
          FriendlyError(E) + LineEnding + LineEnding + 'Ziel: ' + Target);
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    try
      Dst.Close;
    except
      // schon geschlossen
    end;
    DstTr.Free;
    Dst.Free;
  end;
  if not Ok then
  begin
    DeleteFile(Target);
    Exit;
  end;
  ShowStatus('Daten als SQLite-Datei exportiert.');
  ShowMessage('Alle Daten wurden in diese SQLite-Datei geschrieben:' + LineEnding + Target +
    LineEnding + LineEnding + 'Für den Mac: Datei als plib.sqlite3 in den Ordner' +
    LineEnding + '~/Library/Application Support/PLIB/' + LineEnding +
    'kopieren (oder in PLIB am Mac über „Datei, Datenbank wechseln" öffnen).');
end;

{ Wechsel zurueck zu SQLite, wenn gerade PostgreSQL benutzt wird }
procedure TMainForm.PgSwitchBack;
var
  Items: TStringList;
  Idx: Integer;
  Dlg: TOpenDialog;
begin
  Items := TStringList.Create;
  try
    Items.Add('Zu einer SQLite-Datei wechseln (Neustart nötig) ...');
    Items.Add('Verbindungsdaten zum PostgreSQL-Server ändern ...');
    Idx := PickIndex('Datenbank wechseln',
      'Aktuelle Datenbank:' + LineEnding + DbDescription, Items, 0);
  finally
    Items.Free;
  end;
  case Idx of
    0: begin
         Dlg := TOpenDialog.Create(Self);
         try
           Dlg.Title := 'SQLite-Datenbank öffnen';
           Dlg.Filter := 'SQLite-Datenbanken (*.sqlite3;*.sqlite;*.db)|' +
             '*.sqlite3;*.sqlite;*.db|Alle Dateien|*.*';
           if Dlg.Execute then
           begin
             SaveDbPath(Dlg.FileName);
             ShowMessage('Die Einstellung wurde gespeichert. Das Programm wird jetzt ' +
               'beendet. Starte es bitte neu.');
             Close;
           end;
         finally
           Dlg.Free;
         end;
       end;
    1: MnuPgConnect(nil);
  end;
end;

{ Bei PostgreSQL regelmaessig committen, damit keine Transaktion dauerhaft offen bleibt }
procedure TMainForm.AppIdle(Sender: TObject; var Done: Boolean);
var
  Tick: QWord;
begin
  Done := True;
  if (not DbCtx.IsPg) or DbCtx.Batch or (DbCtx.Trans = nil) or (not DbCtx.Trans.Active) then Exit;
  Tick := GetTickCount64;
  if Tick - FIdleTick < 3000 then Exit;
  FIdleTick := Tick;
  try
    DbCtx.Trans.CommitRetaining;
  except
    // Fehler zeigt der naechste Datenbankzugriff
  end;
end;

{ Bei PostgreSQL gibt es keine Datei-Sicherung durch das Programm }
function TMainForm.PgNoFile: Boolean;
begin
  Result := DbCtx.IsPg;
  if DbCtx.IsPg then
    ShowMessage('Bei PostgreSQL sichert der Server die Daten, nicht dieses Programm.' +
      LineEnding + 'Auf dem Synology-NAS geht das mit Hyper Backup (Ordner docker/postgres) ' +
      'oder mit pg_dump.');
end;

{ ---------- Solid Edge (COM-Automatisierung, nur Windows) ---------- }

{$IFDEF WINDOWS}
function TMainForm.SolidEdgeHint(E: Exception): string;
var
  Code: Cardinal;
  L: string;
begin
  Code := 0;
  if E is EOleSysError then Code := Cardinal(EOleSysError(E).ErrorCode);
  L := LowerCase(E.Message);
  if (Code = $80040154) or (Pos('not registered', L) > 0) or
    (Pos('nicht registriert', L) > 0) then
    Result := 'Solid Edge ist nicht als Automatisierungsobjekt registriert.' + LineEnding +
      'Mögliche Ursachen: Solid Edge ist nicht installiert, die Community Edition stellt ' +
      'diese Schnittstelle nicht bereit, oder Solid Edge muss einmal repariert bzw. mit ' +
      'Administratorrechten gestartet werden, damit sich die Schnittstelle registriert.'
  else if (Code = $80070005) or (Pos('zugriff verweigert', L) > 0) or
    (Pos('access is denied', L) > 0) then
    Result := 'Zugriff verweigert. Starte PLIB und Solid Edge mit denselben Rechten ' +
      '(beide normal oder beide als Administrator).'
  else if (Code = $800706BA) or (Code = $800706BE) then
    Result := 'Solid Edge antwortet nicht (RPC-Fehler). Beende Solid Edge in dem Task-Manager ' +
      'und versuche es erneut.'
  else
    Result := E.Message;
end;

procedure TMainForm.BtnSolidEdgeTest(Sender: TObject);
var
  SE, Docs, Doc: Variant;
  Info: string;
  Started: Boolean;
begin
  Started := False;
  Screen.Cursor := crHourGlass;
  try
    try
      SE := GetActiveOleObject('SolidEdge.Application');
      Info := 'Eine laufende Solid-Edge-Sitzung wurde gefunden.';
    except
      // Solid Edge laeuft nicht: ueber die Automatisierung starten
      try
        SE := CreateOleObject('SolidEdge.Application');
        Started := True;
        Info := 'Solid Edge wurde über die Automatisierung gestartet.';
      except
        on E: Exception do
        begin
          Screen.Cursor := crDefault;
          ShowMessage('Solid Edge lässt sich nicht ansprechen.' + LineEnding + LineEnding +
            SolidEdgeHint(E));
          Exit;
        end;
      end;
    end;
    try
      if Started then SE.Visible := True;
      Info := Info + LineEnding + LineEnding + 'Name: ' + VarToStr(SE.Name) + LineEnding +
        'Version: ' + VarToStr(SE.Version);
      Docs := SE.Documents;
      Info := Info + LineEnding + 'Offene Dokumente: ' + VarToStr(Docs.Count);
      // ActiveDocument loest ohne offenes Dokument in Solid Edge einen Fehler aus
      if StrToIntDef(VarToStr(Docs.Count), 0) > 0 then
      begin
        try
          Doc := SE.ActiveDocument;
          Info := Info + LineEnding + 'Aktives Dokument: ' + VarToStr(Doc.Name);
        except
          Info := Info + LineEnding + 'Aktives Dokument: nicht abfragbar';
        end;
      end
      else
        Info := Info + LineEnding + 'Aktives Dokument: keines';
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        ShowMessage('Solid Edge antwortet, aber die Abfrage ist fehlgeschlagen:' +
          LineEnding + LineEnding + SolidEdgeHint(E));
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  Doc := Unassigned;
  Docs := Unassigned;
  SE := Unassigned;
  ShowMessage('Die Verbindung zu Solid Edge funktioniert.' + LineEnding + LineEnding + Info);
end;
{$ELSE}
function TMainForm.SolidEdgeHint(E: Exception): string;
begin
  Result := E.Message;
end;

procedure TMainForm.BtnSolidEdgeTest(Sender: TObject);
begin
  ShowMessage('Die Solid-Edge-Anbindung gibt es nur unter Windows.');
end;
{$ENDIF}

{ ---------- Solid Edge: CAD-Dateien zuordnen, oeffnen, Eigenschaften schreiben ---------- }

function TMainForm.CadFullPath(const AStored: string): string;
begin
  Result := Trim(AStored);
  if (Result <> '') and (not IsAbsPath(Result)) and (CadRoot <> '') then
    Result := IncludeTrailingPathDelimiter(CadRoot) + Result;
end;

{ Liegt die Datei unter dem Basisordner, wird nur der relative Teil gespeichert }
function TMainForm.CadStoredPath(const AFull: string): string;
var
  Root: string;
begin
  Result := AFull;
  if CadRoot = '' then Exit;
  Root := IncludeTrailingPathDelimiter(CadRoot);
  if SameText(Copy(AFull, 1, Length(Root)), Root) then
    Result := Copy(AFull, Length(Root) + 1, MaxInt);
end;

procedure TMainForm.BtnSeAssign(Sender: TObject);
var
  Part: Int64;
  Dlg: TOpenDialog;
  Stored: string;
begin
  Part := CurPart;
  if Part = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil in der Teileliste wählen.');
    Exit;
  end;
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'CAD-Datei für Teil ' + RowStr('part', 'part_number', Part) + ' wählen';
    Dlg.Filter := 'Solid Edge (*.par;*.asm;*.psm;*.dft)|*.par;*.asm;*.psm;*.dft|' +
      'Alle Dateien|*.*';
    Dlg.Options := Dlg.Options + [ofFileMustExist];
    if (CadRoot <> '') and DirectoryExists(CadRoot) then Dlg.InitialDir := CadRoot;
    if not Dlg.Execute then Exit;
    Stored := CadStoredPath(Dlg.FileName);
  finally
    Dlg.Free;
  end;
  Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d', [QuotedStr(Stored), Part]));
  LoadParts;
  SelectPart(Part);
  ShowStatus('CAD-Datei zugeordnet.');
end;

procedure TMainForm.BtnSeUnassign(Sender: TObject);
var
  Part: Int64;
begin
  Part := CurPart;
  if Part = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil in der Teileliste wählen.');
    Exit;
  end;
  if RowStr('part', 'cad_path', Part) = '' then
  begin
    ShowMessage('Diesem Teil ist keine CAD-Datei zugeordnet.');
    Exit;
  end;
  Exec(Format('UPDATE part SET cad_path='''' WHERE id=%d', [Part]));
  LoadParts;
  SelectPart(Part);
  ShowStatus('CAD-Zuordnung entfernt (die Datei selbst bleibt unverändert).');
end;

procedure TMainForm.BtnSeRoot(Sender: TObject);
var
  Dlg: TSelectDirectoryDialog;
  Ini: TIniFile;
begin
  Dlg := TSelectDirectoryDialog.Create(Self);
  try
    Dlg.Title := 'Basisordner der CAD-Dateien wählen';
    if (CadRoot <> '') and DirectoryExists(CadRoot) then Dlg.InitialDir := CadRoot;
    if not Dlg.Execute then Exit;
    CadRoot := Dlg.FileName;
  finally
    Dlg.Free;
  end;
  try
    Ini := TIniFile.Create(IniName);
    try
      Ini.WriteString('SolidEdge', 'Basisordner', CadRoot);
    finally
      Ini.Free;
    end;
  except
    ShowMessage('Der Basisordner konnte nicht in plib.ini gespeichert werden.');
  end;
  ShowMessage('Basisordner: ' + CadRoot + LineEnding + LineEnding +
    'Neu zugeordnete Dateien unter diesem Ordner werden relativ gespeichert. ' +
    'Dadurch passen die Zuordnungen auch auf anderen Rechnern, auf denen derselbe ' +
    'Ordner anders eingebunden ist (dort den Basisordner entsprechend einstellen).');
end;

{ ---------- CAD-Katalog: Download beobachten und dem Teil zuordnen ---------- }

function TMainForm.DlFolder: string;
begin
  Result := DlDir;
  if (Result <> '') and DirectoryExists(Result) then Exit;
  Result := GetEnvironmentVariable('USERPROFILE');
  if Result = '' then Result := GetUserDir;
  Result := IncludeTrailingPathDelimiter(Result) + 'Downloads';
  if not DirectoryExists(Result) then Result := '';
end;

procedure TMainForm.BtnSeDlDir(Sender: TObject);
var
  Dlg: TSelectDirectoryDialog;
  Ini: TIniFile;
begin
  Dlg := TSelectDirectoryDialog.Create(Self);
  try
    Dlg.Title := 'Download-Ordner deines Browsers wählen';
    if DlFolder <> '' then Dlg.InitialDir := DlFolder;
    if not Dlg.Execute then Exit;
    DlDir := Dlg.FileName;
  finally
    Dlg.Free;
  end;
  try
    Ini := TIniFile.Create(IniName);
    try
      Ini.WriteString('SolidEdge', 'Downloadordner', DlDir);
    finally
      Ini.Free;
    end;
  except
    ShowMessage('Der Download-Ordner konnte nicht in plib.ini gespeichert werden.');
  end;
  ShowMessage('Download-Ordner: ' + DlDir + LineEnding + LineEnding +
    'In diesem Ordner sucht PLIB nach der heruntergeladenen CAD-Datei, ' +
    'nachdem du einen CAD-Katalog-Link geöffnet hast.');
end;

procedure TMainForm.StartDlWatch(APart: Int64);
var
  SR: TSearchRec;
  Dir: string;
begin
  Dir := DlFolder;
  if Dir = '' then
  begin
    ShowMessage('Der Download-Ordner ist nicht bekannt, deshalb kann PLIB die Datei nicht ' +
      'automatisch übernehmen.' + LineEnding +
      'Bitte unter "Solid Edge, Download-Ordner für CAD-Kataloge festlegen ..." wählen.');
    Exit;
  end;
  if FDlSnap = nil then FDlSnap := TStringList.Create;
  FDlSnap.Clear;
  // vorhandene Dateien merken: alles Neue danach ist der Download
  if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Attr and faDirectory) = 0 then FDlSnap.Add(LowerCase(SR.Name));
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
  FDlPart := APart;
  FDlStart := Now - 10 / 86400;
  FDlTicks := 0;
  FDlLast := '';
  FDlLastSize := -1;
  FDlBusy := False;
  if FDlTimer = nil then
  begin
    FDlTimer := TTimer.Create(Self);
    FDlTimer.Enabled := False;
    FDlTimer.Interval := 2000;
    FDlTimer.OnTimer := @DlTimerTick;
  end;
  FDlTimer.Enabled := True;
  ShowStatus('Warte auf den Download der CAD-Datei in ' + Dir + ' (bis zu 10 Minuten) ...');
end;

procedure TMainForm.DlTimerTick(Sender: TObject);
var
  SR: TSearchRec;
  Dir, Ext, Best, Full: string;
  BestTime, T: TDateTime;
  BestSize: Int64;
  FS: TFileStream;
begin
  if FDlBusy then Exit;
  Inc(FDlTicks);
  if FDlTicks > 300 then
  begin
    FDlTimer.Enabled := False;
    ShowStatus('Download-Beobachtung beendet: keine neue CAD-Datei gefunden.');
    Exit;
  end;
  Dir := DlFolder;
  if Dir = '' then
  begin
    FDlTimer.Enabled := False;
    Exit;
  end;
  Dir := IncludeTrailingPathDelimiter(Dir);
  Best := '';
  BestTime := 0;
  BestSize := 0;
  if FindFirst(Dir + '*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          Ext := LowerCase(ExtractFileExt(SR.Name));
          if IsCadExt(Ext) or (Ext = '.zip') then
          begin
            T := FileDateToDateTime(SR.Time);
            if ((T >= FDlStart) or (FDlSnap.IndexOf(LowerCase(SR.Name)) < 0)) and
              (T >= BestTime) then
            begin
              Best := SR.Name;
              BestTime := T;
              BestSize := SR.Size;
            end;
          end;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
  if (Best = '') or (BestSize <= 0) then Exit;
  // erst uebernehmen, wenn Name und Groesse sich nicht mehr aendern
  if (Best <> FDlLast) or (BestSize <> FDlLastSize) then
  begin
    FDlLast := Best;
    FDlLastSize := BestSize;
    Exit;
  end;
  Full := Dir + Best;
  try
    FS := TFileStream.Create(Full, fmOpenRead or fmShareExclusive);
    FS.Free;
  except
    Exit;   // Browser schreibt noch
  end;
  FDlTimer.Enabled := False;
  FDlBusy := True;
  try
    DlTakeFile(Full);
  finally
    FDlBusy := False;
  end;
end;

function TMainForm.DlUnzip(const AZip, ADir: string): string;
const
  Prio: array[0..9] of string = ('.par', '.psm', '.asm', '.stp', '.step', '.igs',
    '.iges', '.x_t', '.sldprt', '.sat');
var
  UZ: TUnZipper;
  I, K: Integer;
  Names: TStringList;
  EName, Ext: string;
begin
  Result := '';
  ForceDirectories(ADir);
  UZ := TUnZipper.Create;
  try
    try
      UZ.FileName := AZip;
      UZ.OutputPath := ADir;
      UZ.Examine;
      // Nur CAD-Dateien entpacken, keine Pfade ausserhalb des Zielordners ("..", absolute
      // Pfade, Laufwerke) und keine uebergrossen Eintraege (Schutz vor manipulierten ZIPs)
      Names := TStringList.Create;
      try
        for I := 0 to UZ.Entries.Count - 1 do
        begin
          EName := StringReplace(UZ.Entries[I].ArchiveFileName, '\', '/', [rfReplaceAll]);
          if (EName = '') or (EName[1] = '/') or (Pos(':', EName) > 0) or
             (Pos('../', EName + '/') > 0) or (EName = '..') then Continue;
          if UZ.Entries[I].Size > Int64(2000) * 1024 * 1024 then Continue;
          Ext := LowerCase(ExtractFileExt(EName));
          for K := 0 to High(Prio) do
            if Ext = Prio[K] then
            begin
              Names.Add(UZ.Entries[I].ArchiveFileName);
              Break;
            end;
        end;
        if Names.Count = 0 then Exit;
        UZ.UnZipFiles(Names);
      finally
        Names.Free;
      end;
    except
      on E: Exception do
      begin
        ShowMessage('Die ZIP-Datei konnte nicht entpackt werden:' + LineEnding + E.Message);
        Exit;
      end;
    end;
  finally
    UZ.Free;
  end;
  for I := 0 to High(Prio) do
  begin
    Result := FindFileExt(ADir, Prio[I]);
    if Result <> '' then Exit;
  end;
end;

procedure TMainForm.DlTakeFile(const AFull: string);
var
  Src, Dest, Dir, PartNo: string;
  Part: Int64;
begin
  Part := FDlPart;
  PartNo := RowStr('part', 'part_number', Part);
  Src := AFull;
  if LowerCase(ExtractFileExt(Src)) = '.zip' then
  begin
    Src := DlUnzip(AFull, IncludeTrailingPathDelimiter(GetTempDir) + 'plib_dl_' +
      IntToStr(Part) + '_' + IntToStr(GetTickCount64));
    if Src = '' then
    begin
      ShowStatus('In der heruntergeladenen ZIP-Datei war keine CAD-Datei.');
      Exit;
    end;
  end;
  if MessageDlg('Heruntergeladene CAD-Datei gefunden:' + LineEnding + ExtractFileName(Src) +
    LineEnding + LineEnding + 'Dem Teil ' + PartNo + ' zuordnen?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
  begin
    ShowStatus('Download nicht übernommen.');
    Exit;
  end;
  if (CadRoot <> '') and DirectoryExists(CadRoot) then
    Dir := IncludeTrailingPathDelimiter(CadRoot) + 'Katalog'
  else
    Dir := IncludeTrailingPathDelimiter(DlFolder) + 'PLIB_CAD';
  if not ForceDirectories(Dir) then
  begin
    ShowMessage('Der Zielordner konnte nicht angelegt werden:' + LineEnding + Dir);
    Exit;
  end;
  Dest := IncludeTrailingPathDelimiter(Dir) + CadFileBase(Part) + ExtractFileExt(Src);
  if FileExists(Dest) then
    if MessageDlg('Die Datei ' + ExtractFileName(Dest) + ' gibt es schon. Überschreiben?',
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;
  if not CopyFileSimple(Src, Dest) then
  begin
    ShowMessage('Die Datei konnte nicht kopiert werden:' + LineEnding + Dest);
    Exit;
  end;
  Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d', [QuotedStr(CadStoredPath(Dest)), Part]));
  LoadParts;
  SelectPart(Part);
  ShowStatus('CAD-Datei übernommen und zugeordnet: ' + Dest);
end;

{ ---------- Plugins (siehe pluginhost.pas und den Ordner plugins neben der plib.exe) ---------- }

procedure TMainForm.MnuFontSize(Sender: TObject);
begin
  TMenuItem(Sender).Checked := True;
  ThemeSetFontSize(IniName, TMenuItem(Sender).Tag);
end;

procedure TMainForm.MnuDpiInfo(Sender: TObject);
begin
  ShowMessage(DpiInfo(Self) +
    'Skalierung laut LCL (PixelsPerInch): ' + IntToStr(Screen.PixelsPerInch) + LineEnding +
    'Monitor-DPI laut LCL: ' + IntToStr(Monitor.PixelsPerInch) + LineEnding +
    'Bildschirm: ' + IntToStr(Screen.Width) + ' x ' + IntToStr(Screen.Height) + ' Pixel' + LineEnding +
    'Schrift: ' + Font.Name + ', Groesse ' + IntToStr(Font.Size) + LineEnding +
    'Hochaufloesend laut plib.ini: ja/nein siehe [Ansicht] Hochaufloesend');
end;

procedure TMainForm.MnuRibbon(Sender: TObject);
begin
  RibbonSave(IniName, TMenuItem(Sender).Checked);
  ShowMessage('Die Einstellung wird beim naechsten Start von PLIB angewendet.');
end;

{ Baut das Menueband aus den Knoepfen der alten Knopfleiste: jede Gruppe (durch Trenner
  getrennt) wird zu einer Gruppe im Band, geklickt wird der alte Knopf. }
procedure TMainForm.BuildRibbon;
var
  Gr: array of array of TSpeedButton;
  Names: array of string;
  N, I, J, M, T, G: Integer;
  C: TControl;

  function ShortCaption(B: TSpeedButton): string;
  var
    P: Integer;
  begin
    Result := B.Hint;
    P := Pos(LineEnding, Result);
    if P > 0 then Result := Copy(Result, 1, P - 1);
    P := Pos(' (', Result);
    if P > 0 then Result := Copy(Result, 1, P - 1);
    Result := StringReplace(Result, 'Eigenschaften nach Solid Edge schreiben',
      'Eigenschaften schreiben', []);
    Result := StringReplace(Result, 'Teil in Baugruppe einfügen', 'In Baugruppe einfügen', []);
    Result := StringReplace(Result, 'Aktuelles Solid-Edge-Dokument in PLIB zeigen',
      'Dokument in PLIB zeigen', []);
    Result := StringReplace(Result, 'Teil in Solid Edge öffnen', 'In Solid Edge öffnen', []);
  end;

begin
  if not RibbonEnabled(IniName) then Exit;
  N := 1;
  SetLength(Gr, 1);
  for I := 0 to ToolPanel.ControlCount - 1 do
  begin
    C := ToolPanel.Controls[I];
    if C is TSpeedButton then
    begin
      M := Length(Gr[N - 1]);
      SetLength(Gr[N - 1], M + 1);
      Gr[N - 1][M] := TSpeedButton(C);
    end
    else if C is TBevel then
      if Length(Gr[N - 1]) > 0 then
      begin
        Inc(N);
        SetLength(Gr, N);
      end;
  end;
  if Length(Gr[N - 1]) = 0 then Dec(N);
  if (N < 3) or (N > 6) then Exit;     // unerwarteter Aufbau: alte Knopfleiste behalten
  SetLength(Names, N);
  Names[0] := 'Suche';
  Names[1] := 'Klassen';
  Names[2] := 'Merkmale';
  if N >= 4 then Names[3] := 'Teile';
  if N = 6 then Names[4] := 'Solid Edge';
  Names[N - 1] := 'Hilfe';

  FRibbon := TPlibRibbon.Create(Self);
  FRibbon.Parent := Self;
  FRibbon.Align := alTop;
  // Reiter "Start": Suche + Hilfe; danach je ein Reiter fuer die uebrigen Gruppen
  T := FRibbon.AddTab('Start');
  G := FRibbon.AddGroup(T, 'Suche und Sprache');
  for J := 0 to High(Gr[0]) do
    FRibbon.AddItem(T, G, ShortCaption(Gr[0][J]), Gr[0][J]);
  G := FRibbon.AddGroup(T, 'Hilfe');
  for J := 0 to High(Gr[N - 1]) do
    FRibbon.AddItem(T, G, ShortCaption(Gr[N - 1][J]), Gr[N - 1][J]);
  for I := 1 to N - 2 do
  begin
    T := FRibbon.AddTab(Names[I]);
    G := FRibbon.AddGroup(T, Names[I]);
    for J := 0 to High(Gr[I]) do
      FRibbon.AddItem(T, G, ShortCaption(Gr[I][J]), Gr[I][J]);
  end;
  FRibbon.MenuSource := MainMenu1;   // Menueeintraege rechts im Band, Menueleiste entfaellt
  FRibbon.Finish;
  FRibbon.Top := 0;
  DockMgr.ToolbarHidden := True;
  FRibbon.Visible := DockMgr.ToolbarVisible;
end;

procedure TMainForm.MnuDesign(Sender: TObject);
begin
  // Die Farbe wird gespeichert und gilt nach einem Neustart (nur so werden auch die Menues sicher umgefaerbt)
  ThemeSave(IniName, TMenuItem(Sender).Checked);
  if MessageDlg('Design ändern',
    'Das Design wird nach einem Neustart von PLIB angewendet.' + LineEnding + LineEnding +
    'PLIB jetzt neu starten?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      with TProcess.Create(nil) do
      try
        Executable := 'cmd.exe';
        Parameters.Add('/c');
        Parameters.Add('ping -n 3 127.0.0.1 >nul & start "" "' + Application.ExeName + '"');
        Options := [poNoConsole];
        Execute;
      finally
        Free;
      end;
    except
    end;
    Close;
  end;
end;

procedure TMainForm.SetupPlugins;
var
  I: Integer;
  PlugMenu, Sub: TMenuItem;
  DesignItem: TMenuItem;
begin
  if FindComponent('miDesignDunkel') = nil then
  begin
    DesignItem := TMenuItem.Create(Self);
    DesignItem.Name := 'miDesignDunkel';
    DesignItem.Caption := '&Dunkles Design';
    DesignItem.AutoCheck := True;
    DesignItem.Checked := ThemeDark;
    DesignItem.OnClick := @MnuDesign;
    miAnsicht.Add(DesignItem);
    DesignItem := TMenuItem.Create(Self);
    DesignItem.Name := 'miSpalten';
    DesignItem.Caption := '&Tabellenspalten ein-/ausblenden ...';
    DesignItem.OnClick := @MnuColumns;
    miAnsicht.Add(DesignItem);
    DesignItem := TMenuItem.Create(Self);
    DesignItem.Name := 'miRenumber';
    DesignItem.Caption := 'Alte Teilenummern auf 7-stellig &umstellen ...';
    DesignItem.OnClick := @MnuRenumber;
    miTeile.Add(DesignItem);
    DesignItem := TMenuItem.Create(Self);
    DesignItem.Name := 'miMenuband';
    DesignItem.Caption := '&Menüband (nach Neustart)';
    DesignItem.AutoCheck := True;
    DesignItem.Checked := RibbonEnabled(IniName);
    DesignItem.OnClick := @MnuRibbon;
    miAnsicht.Add(DesignItem);
    DesignItem := TMenuItem.Create(Self);
    DesignItem.Name := 'miDpiInfo';
    DesignItem.Caption := 'Anzeige-&Info (Schärfe prüfen) ...';
    DesignItem.OnClick := @MnuDpiInfo;
    miAnsicht.Add(DesignItem);
    // Schriftgroesse: Untermenue mit Auswahl, wirkt sofort
    DesignItem := TMenuItem.Create(Self);
    DesignItem.Name := 'miSchriftgroesse';
    DesignItem.Caption := '&Schriftgröße';
    miAnsicht.Add(DesignItem);
    for I := 0 to 7 do
    begin
      Sub := TMenuItem.Create(Self);
      Sub.Name := 'miSchrift' + IntToStr(I);
      case I of
        0: Sub.Tag := 0;
        1: Sub.Tag := 9;
        2: Sub.Tag := 10;
        3: Sub.Tag := 11;
        4: Sub.Tag := 12;
        5: Sub.Tag := 13;
        6: Sub.Tag := 14;
      else
        Sub.Tag := 16;
      end;
      if Sub.Tag = 0 then Sub.Caption := 'Windows-Vorgabe'
      else Sub.Caption := IntToStr(Sub.Tag) + ' pt';
      Sub.RadioItem := True;
      Sub.GroupIndex := 7;
      Sub.AutoCheck := True;
      Sub.Checked := Sub.Tag = ThemeFontSize;
      Sub.OnClick := @MnuFontSize;
      DesignItem.Add(Sub);
    end;
  end;
  FPlugins := LoadPlugins(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'plugins');
  if Length(FPlugins) = 0 then Exit;
  // Rechtsklick-Menue der Teileliste
  AddPopItem(PopParts, '-', nil, 1);
  // Menue "Plugins" hinter "Solid Edge"
  PlugMenu := TMenuItem.Create(MainMenu1);
  PlugMenu.Caption := '&Plugins';
  MainMenu1.Items.Insert(miSolidEdge.MenuIndex + 1, PlugMenu);
  for I := 0 to High(FPlugins) do
  begin
    Sub := AddPopItem(PopParts, FPlugins[I].Name, @BtnPluginRun, 0);
    Sub.HelpContext := I + 1;     // Nummer des Plugins (ab 1)
    Sub := TMenuItem.Create(PlugMenu);
    Sub.Caption := FPlugins[I].Name;
    Sub.OnClick := @BtnPluginRun;
    Sub.HelpContext := I + 1;
    PlugMenu.Add(Sub);
  end;
end;

{ Klassencode, Klassenkette (Klasse und Oberklassen) und alle Merkmalswerte eines Teils }
function TMainForm.PluginCollect(APart: Int64; AChain, ACodes, AVals, AUnits: TStrings): string;
var
  Q: TSQLQuery;
begin
  Result := ScalarStr(Format('SELECT c.code FROM class c JOIN part p ON p.class_id=c.id ' +
    'WHERE p.id=%d', [APart]));
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := Format('WITH RECURSIVE anc(id) AS (' +
      ' SELECT class_id FROM part WHERE id=%d' +
      ' UNION ALL SELECT c.parent_id FROM class c JOIN anc a ON c.id=a.id' +
      ' WHERE c.parent_id IS NOT NULL) ' +
      'SELECT c.code FROM class c WHERE c.id IN (SELECT id FROM anc)', [APart]);
    Q.Open;
    while not Q.EOF do
    begin
      AChain.Add(FieldText(Q.Fields[0]));
      Q.Next;
    end;
    Q.Close;
    Q.SQL.Text := Format('SELECT pr.code, COALESCE(pv.value, ' + QuotedStr('') + '), ' +
      'COALESCE(pr.unit, ' + QuotedStr('') + ') ' +
      'FROM part_value pv JOIN property pr ON pr.id=pv.property_id WHERE pv.part_id=%d', [APart]);
    Q.Open;
    while not Q.EOF do
    begin
      ACodes.Add(FieldText(Q.Fields[0]));
      AVals.Add(FieldText(Q.Fields[1]));
      AUnits.Add(FieldText(Q.Fields[2]));
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

procedure TMainForm.BtnPluginRun(Sender: TObject);
var
  Idx, Ans: Integer;
  Part: Int64;
  Chain, Codes, Vals, Units: TStringList;
  ClsCode, PartNo, Katalog, Target, Req, OutFile, Msg, OldPath: string;
  ParFile, OldDir, Moved: string;
  Overwrite, Reused, Ok, SameBasePar: Boolean;
begin
  Ok := False;
  Reused := False;
  Idx := (Sender as TMenuItem).HelpContext - 1;
  if (Idx < 0) or (Idx > High(FPlugins)) then Exit;
  Part := CurPart;
  if Part = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil in der Teileliste wählen.');
    Exit;
  end;
  if (CadRoot = '') or (not DirectoryExists(CadRoot)) then
  begin
    ShowMessage('Der Basisordner für CAD-Dateien ist nicht gesetzt oder nicht erreichbar.' +
      LineEnding + LineEnding + 'Bitte im Menü "Solid Edge" den Basisordner festlegen.');
    Exit;
  end;
  Chain := TStringList.Create;
  Codes := TStringList.Create;
  Vals := TStringList.Create;
  Units := TStringList.Create;
  try
    ClsCode := PluginCollect(Part, Chain, Codes, Vals, Units);
    if not PluginAcceptsChain(FPlugins[Idx], Chain) then
    begin
      ShowMessage('Das Plugin "' + FPlugins[Idx].Name + '" ist für die Klasse ' + ClsCode +
        ' nicht vorgesehen.');
      Exit;
    end;
    PartNo := RowStr('part', 'part_number', Part);
    Katalog := IncludeTrailingPathDelimiter(CadRoot) + 'Katalog';
    if not ForceDirectories(Katalog) then
    begin
      ShowMessage('Der Ordner konnte nicht angelegt werden:' + LineEnding + Katalog);
      Exit;
    end;
    Target := IncludeTrailingPathDelimiter(Katalog) + CadFileBase(Part) + '.step';
    Overwrite := False;
    if FileExists(Target) then
    begin
      Ans := MessageDlg('Die Datei ' + ExtractFileName(Target) + ' gibt es schon.' + LineEnding +
        LineEnding + 'Neu erzeugen und überschreiben?' + LineEnding +
        '(Nein: die vorhandene Datei dem Teil zuordnen)',
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Ans = mrCancel then Exit;
      Overwrite := Ans = mrYes;
    end;
    Req := BuildPluginRequest(PartNo, RowStr('part', 'description', Part), ClsCode,
      Chain, Codes, Vals, Units, Target, Overwrite);
    ShowStatus('Plugin läuft: ' + FPlugins[Idx].Name + ' ...');
    Screen.Cursor := crHourGlass;
    try
      Ok := RunPlugin(FPlugins[Idx], Req, OutFile, Msg, Reused);
    finally
      Screen.Cursor := crDefault;
    end;
  finally
    Chain.Free;
    Codes.Free;
    Vals.Free;
    Units.Free;
  end;
  if not Ok then
  begin
    ShowStatus('Plugin: Fehler.');
    ShowMessage('Das Plugin meldet einen Fehler:' + LineEnding + LineEnding + Msg);
    Exit;
  end;
  if OutFile = '' then
  begin
    ShowStatus(Msg);
    Exit;
  end;
  // Sicherheit: PLIB uebernimmt nur die Datei, die es selbst angefordert hat
  if not SameText(ExpandFileName(OutFile), ExpandFileName(Target)) then
  begin
    ShowMessage('Das Plugin hat eine andere Datei gemeldet als angefordert:' + LineEnding +
      OutFile + LineEnding + 'Sie wird aus Sicherheitsgründen nicht übernommen.');
    Exit;
  end;
  OldPath := RowStr('part', 'cad_path', Part);
  ParFile := ChangeFileExt(OutFile, '.par');
  SameBasePar := (OldPath <> '') and SameText(OldPath, CadStoredPath(ParFile));
  if Reused and SameBasePar then
  begin
    // Die vorhandene STEP-Datei wurde nur wiederverwendet: das Solid-Edge-Teil bleibt zugeordnet
    ShowStatus(Msg + ' Die Zuordnung bleibt beim Solid-Edge-Teil (.par).');
    Exit;
  end;
  if (not Reused) and FileExists(ParFile) then
  begin
    // Neue STEP-Datei: das alte Solid-Edge-Teil beiseite legen. Beim naechsten Oeffnen in
    // Solid Edge entsteht aus der STEP-Datei automatisch ein neues Teil.
    OldDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParFile)) + 'alt';
    ForceDirectories(OldDir);
    Moved := IncludeTrailingPathDelimiter(OldDir) + ChangeFileExt(ExtractFileName(ParFile), '') +
      '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.par';
    if not RenameFile(ParFile, Moved) then
    begin
      ShowMessage('Die neue STEP-Datei wurde erzeugt, aber das alte Solid-Edge-Teil konnte nicht ' +
        'beiseite gelegt werden:' + LineEnding + ParFile + LineEnding + LineEnding +
        'Ist es noch in Solid Edge geöffnet? Bitte schließen und das Plugin noch einmal starten.');
      ShowStatus('Plugin: altes Solid-Edge-Teil ist noch in Benutzung.');
      Exit;
    end;
  end;
  if (OldPath <> '') and (not SameBasePar) and (not SameText(OldPath, CadStoredPath(OutFile))) then
    if MessageDlg('Dem Teil ist schon eine andere CAD-Datei zugeordnet:' + LineEnding + OldPath +
      LineEnding + LineEnding + 'Durch die neue Datei ersetzen?',
      mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      ShowStatus('Plugin: Zuordnung nicht geändert.');
      Exit;
    end;
  Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d', [QuotedStr(CadStoredPath(OutFile)), Part]));
  LoadParts;
  SelectPart(Part);
  ShowStatus(Msg + ' ' + OutFile);
end;

{ ---------- Teilesuche (eigenes Fenster, Unit PlibSearch) ---------- }

procedure TMainForm.BtnPartSearch(Sender: TObject);
var
  H: TPartSearchHost;
begin
  H.Owner := Self;
  H.CurClass := @CurClass;
  H.ShowPart := @ShowPartFromSearch;
  H.OpenCad := @BtnSeOpen;
  H.OpenLink := @BtnOpenCadLink;
  H.Status := @ShowStatus;
  ShowPartSearch(H);
end;

{ Treffer der Teilesuche im Hauptfenster zeigen }
procedure TMainForm.ShowPartFromSearch(AClass, APart: Int64);
begin
  SelectClass(AClass);
  LoadParts;
  SelectPart(APart);
end;

{ Sammelt die Eigenschaften (Name=Wert), die in die CAD-Datei geschrieben werden }
procedure TMainForm.BuildSeProps(APart: Int64; AList: TStrings);
var
  Q: TSQLQuery;
begin
  AList.Clear;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT pt.part_number, COALESCE(pt.description,''''), c.name, ' +
      'COALESCE(c.class_no,''''), c.code, COALESCE(s.code,''''), COALESCE(s.name,'''') ' +
      'FROM part pt JOIN class c ON c.id=pt.class_id ' +
      'LEFT JOIN supplier s ON s.id=pt.supplier_id WHERE pt.id=' + IntToStr(APart);
    Q.Open;
    if not Q.EOF then
    begin
      AList.Add('PLIB_Teilenummer=' + FieldText(Q.Fields[0]));
      AList.Add('PLIB_Benennung=' + FieldText(Q.Fields[1]));
      AList.Add('PLIB_Klasse=' + FieldText(Q.Fields[2]));
      AList.Add('PLIB_Klassennummer=' + FieldText(Q.Fields[3]));
      AList.Add('PLIB_Klassencode=' + FieldText(Q.Fields[4]));
      AList.Add('PLIB_Lieferant=' + FieldText(Q.Fields[5]));
      AList.Add('PLIB_Lieferantenname=' + FieldText(Q.Fields[6]));
      AList.Add('PLIB_BSU=' + FieldText(Q.Fields[5]) + '/' + FieldText(Q.Fields[0]));
    end;
    Q.Close;
    Q.SQL.Text := 'SELECT p.code, CASE WHEN p.datatype=''enum'' THEN COALESCE((SELECT ' +
      'e.name FROM enum_value e WHERE e.property_id=p.id AND e.code=pv.value), pv.value) ' +
      'ELSE pv.value END FROM part_value pv JOIN property p ON p.id=pv.property_id ' +
      'WHERE pv.part_id=' + IntToStr(APart) + ' ORDER BY p.code';
    Q.Open;
    while not Q.EOF do
    begin
      if FieldText(Q.Fields[1]) <> '' then
        AList.Add('PLIB_' + FieldText(Q.Fields[0]) + '=' + FieldText(Q.Fields[1]));
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

{$IFDEF WINDOWS}
{ Setzt eine Eigenschaft in einem Solid-Edge-Eigenschaftssatz; legt sie bei
  benutzerdefinierten Eigenschaften neu an. Sucht ueber den Index, damit keine
  Fehler fuer nicht vorhandene Namen entstehen. }
function SeSetProp(const AProps: Variant; const AName, AValue: string): Boolean;
var
  i, n: Integer;
  P: Variant;
  Found: Boolean;
begin
  Result := False;
  try
    Found := False;
    n := AProps.Count;
    for i := 1 to n do
    begin
      P := AProps.Item(i);
      if SameText(VarToStr(P.Name), AName) then
      begin
        P.Value := AValue;
        Found := True;
        Break;
      end;
    end;
    if not Found then AProps.Add(AName, AValue);
    Result := True;
  except
    Result := False;
  end;
end;

function TMainForm.SeGetApp(out SE: Variant): Boolean;
begin
  Result := False;
  try
    SE := GetActiveOleObject('SolidEdge.Application');
    Result := True;
  except
    try
      SE := CreateOleObject('SolidEdge.Application');
      SE.Visible := True;
      Result := True;
    except
      on E: Exception do
        ShowMessage('Solid Edge lässt sich nicht ansprechen.' + LineEnding + LineEnding +
          SolidEdgeHint(E));
    end;
  end;
end;

{ Oeffnet die Datei in Solid Edge (oder holt sie nach vorn, wenn sie schon offen ist) }
function TMainForm.SeOpenFile(const APath: string; out SE, Doc: Variant): Boolean;
var
  Docs: Variant;
  i, n: Integer;
  Found: Boolean;
  Tpl, Ext: string;
begin
  Result := False;
  if not FileExists(APath) then
  begin
    ShowMessage('Die CAD-Datei wurde nicht gefunden:' + LineEnding + APath +
      LineEnding + LineEnding + 'Prüfe die Zuordnung und den Basisordner.');
    Exit;
  end;
  if not SeGetApp(SE) then Exit;
  try
    SE.Visible := True;
    Docs := SE.Documents;
    n := Docs.Count;
    Found := False;
    for i := 1 to n do
    begin
      Doc := Docs.Item(i);
      if SameText(VarToStr(Doc.FullName), APath) then
      begin
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      // Fremdformate (STEP, IGES): mit Vorlage oeffnen, sonst fragt Solid Edge jedes Mal
      // nach Teil oder Baugruppe
      Ext := LowerCase(ExtractFileExt(APath));
      Tpl := '';
      if (Ext = '.stp') or (Ext = '.step') or (Ext = '.igs') or (Ext = '.iges') then
      begin
        Tpl := SeTemplateFor(SE);
      end;
      if Tpl <> '' then
      begin
        try
          Doc := Docs.OpenWithTemplate(APath, Tpl);
        except
          on E: Exception do
          begin
            ShowMessage('Das Öffnen mit Vorlage hat nicht funktioniert:' + LineEnding + E.Message +
              LineEnding + LineEnding + 'Vorlage: ' + Tpl);
            Doc := Docs.Open(APath);
          end;
        end;
      end
      else
        Doc := Docs.Open(APath);
    end;
    try
      Doc.Activate;
    except
      // Aktivieren ist nicht entscheidend
    end;
    Result := True;
  except
    on E: Exception do
      ShowMessage('Die Datei konnte in Solid Edge nicht geöffnet werden:' + LineEnding +
        APath + LineEnding + LineEnding + SolidEdgeHint(E));
  end;
end;

{ Sucht eine Datei mit diesem Namen im Ordner und seinen Unterordnern (bis ADepth Ebenen) }
function FindFileNamed(const ADir, AName: string; ADepth: Integer): string;
var
  SR: TSearchRec;
  Root: string;
begin
  Result := '';
  Root := IncludeTrailingPathDelimiter(ADir);
  if FindFirst(Root + '*', faAnyFile, SR) <> 0 then Exit;
  try
    repeat
      if (SR.Attr and faDirectory) = 0 then
      begin
        if SameText(SR.Name, AName) then
        begin
          Result := Root + SR.Name;
          Exit;
        end;
      end
      else if (SR.Name <> '.') and (SR.Name <> '..') and (ADepth > 0) then
      begin
        Result := FindFileNamed(Root + SR.Name, AName, ADepth - 1);
        if Result <> '' then Exit;
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

{ Teilevorlage fuer das Oeffnen von STEP/IGES, damit Solid Edge nicht nach Teil oder Baugruppe
  fragt. Reihenfolge: plib.ini [SolidEdge] VorlageTeil=..., dann "din metric part.par" bzw.
  "iso metric part.par" im Template-Ordner der Installation (per COM oder unter
  Programme\Siemens\Solid Edge*), sonst wird einmal nach einer Vorlage gefragt }
function TMainForm.SeTemplateFor(const SE: Variant): string;
var
  Ini: TIniFile;
  SePath, PF, Cand: string;
  SR: TSearchRec;
  Dlg: TOpenDialog;
  Dirs: TStringList;
  I, K: Integer;
  Names: array[0..1] of string;
begin
  Names[0] := 'din metric part.par';
  Names[1] := 'iso metric part.par';
  Ini := TIniFile.Create(IniName);
  try
    Result := Trim(Ini.ReadString('SolidEdge', 'VorlageTeil', ''));
  finally
    Ini.Free;
  end;
  if (Result <> '') and FileExists(Result) then Exit;
  Result := '';

  Dirs := TStringList.Create;
  try
    try
      SePath := VarToStr(SE.Path);
    except
      SePath := '';
    end;
    if SePath <> '' then
      Dirs.Add(ExtractFilePath(ExcludeTrailingPathDelimiter(SePath)) + 'Template');
    for K := 0 to 1 do
    begin
      if K = 0 then PF := GetEnvironmentVariable('ProgramFiles')
      else PF := GetEnvironmentVariable('ProgramW6432');
      if PF = '' then Continue;
      PF := IncludeTrailingPathDelimiter(PF) + 'Siemens' + PathDelim;
      if FindFirst(PF + 'Solid Edge*', faDirectory, SR) = 0 then
      begin
        try
          repeat
            if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and (SR.Name <> '..') then
              Dirs.Add(PF + SR.Name + PathDelim + 'Template');
          until FindNext(SR) <> 0;
        finally
          FindClose(SR);
        end;
      end;
    end;
    Dirs.Sort;   // die neueste Version steht zuletzt
    for I := Dirs.Count - 1 downto 0 do
    begin
      if not DirectoryExists(Dirs[I]) then Continue;
      for K := 0 to 1 do
      begin
        Cand := FindFileNamed(Dirs[I], Names[K], 3);
        if Cand <> '' then
        begin
          Result := Cand;
          Break;
        end;
      end;
      if Result <> '' then Break;
    end;
  finally
    Dirs.Free;
  end;
  if Result <> '' then Exit;

  // Nichts gefunden: einmal nachfragen und in der plib.ini merken
  ShowMessage('Die Teilevorlage von Solid Edge wurde nicht gefunden, deshalb fragt Solid Edge ' +
    'beim Öffnen nach Teil oder Baugruppe.' + LineEnding + LineEnding +
    'Bitte wähle einmal eine Teilevorlage aus, zum Beispiel "din metric part.par" oder ' +
    '"iso metric part.par". PLIB merkt sie sich.');
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Title := 'Teilevorlage von Solid Edge wählen';
    Dlg.Filter := 'Solid-Edge-Teilevorlage (*.par)|*.par';
    if Dlg.Execute then
    begin
      Result := Dlg.FileName;
      Ini := TIniFile.Create(IniName);
      try
        Ini.WriteString('SolidEdge', 'VorlageTeil', Result);
      finally
        Ini.Free;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TMainForm.BtnSeOpen(Sender: TObject);
var
  Part: Int64;
  Path, Ext, Par: string;
  SE, Doc: Variant;
  Foreign, LinkChanged: Boolean;
begin
  Part := CurPart;
  if Part = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil in der Teileliste wählen.');
    Exit;
  end;
  Path := CadFullPath(RowStr('part', 'cad_path', Part));
  if Path = '' then
  begin
    ShowMessage('Diesem Teil ist noch keine CAD-Datei zugeordnet.' + LineEnding +
      'Das geht über „Solid Edge, CAD-Datei zuordnen" oder per Rechtsklick auf das Teil.');
    Exit;
  end;
  LinkChanged := False;
  Screen.Cursor := crHourGlass;
  try
    Ext := LowerCase(ExtractFileExt(Path));
    Foreign := (Ext = '.stp') or (Ext = '.step') or (Ext = '.igs') or (Ext = '.iges');
    Par := ChangeFileExt(Path, '.par');
    if Foreign and FileExists(Par) then
    begin
      // Es gibt schon ein Solid-Edge-Teil mit dem Namen der STEP-Datei: das wird geoeffnet
      Path := Par;
      Foreign := False;
      Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d', [QuotedStr(CadStoredPath(Par)), Part]));
      LinkChanged := True;
    end;
    if SeOpenFile(Path, SE, Doc) then
    begin
      if Foreign then
      begin
        // Neues Teil aus STEP: gleich unter dem Namen der Teilenummer speichern
        try
          Doc.SaveAs(Par);
          Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d', [QuotedStr(CadStoredPath(Par)), Part]));
          LinkChanged := True;
          ShowStatus('Als Solid-Edge-Teil gespeichert: ' + Par);
        except
          on E: Exception do
            ShowMessage('Das Teil konnte nicht als ' + ExtractFileName(Par) +
              ' gespeichert werden:' + LineEnding + LineEnding + E.Message);
        end;
      end
      else
        ShowStatus('In Solid Edge geöffnet: ' + ExtractFileName(Path));
    end;
  finally
    Screen.Cursor := crDefault;
  end;
  if LinkChanged then
  begin
    LoadParts;
    SelectPart(Part);
  end;
end;

procedure TMainForm.BtnSeWriteProps(Sender: TObject);
var
  Part: Int64;
  Path, Failed, Std, Desc: string;
  SE, Doc, PropSets, Custom, SetX: Variant;
  Pairs: TStringList;
  i, Ok: Integer;
  Saved: Boolean;
begin
  Part := CurPart;
  if Part = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil in der Teileliste wählen.');
    Exit;
  end;
  Path := CadFullPath(RowStr('part', 'cad_path', Part));
  if Path = '' then
  begin
    ShowMessage('Diesem Teil ist noch keine CAD-Datei zugeordnet.');
    Exit;
  end;
  Pairs := TStringList.Create;
  Screen.Cursor := crHourGlass;
  try
    BuildSeProps(Part, Pairs);
    if not SeOpenFile(Path, SE, Doc) then Exit;
    Ok := 0;
    Failed := '';
    Std := '';
    Saved := False;
    try
      PropSets := Doc.Properties;
      try
        Custom := PropSets.Item('Custom');
        for i := 0 to Pairs.Count - 1 do
          if SeSetProp(Custom, Pairs.Names[i], Pairs.ValueFromIndex[i]) then
            Inc(Ok)
          else
            Failed := Failed + Pairs.Names[i] + ' ';
      except
        Failed := 'Die benutzerdefinierten Eigenschaften sind in dieser Datei nicht verfügbar.';
      end;
      // Standardeigenschaften (Titel, Dokumentnummer), soweit Solid Edge sie zulaesst
      Desc := Pairs.Values['PLIB_Benennung'];
      try
        SetX := PropSets.Item('SummaryInformation');
        if (Desc <> '') and SeSetProp(SetX, 'Title', Desc) then Std := Std + 'Titel ';
      except
        // Satz nicht vorhanden
      end;
      try
        SetX := PropSets.Item('ProjectInformation');
        if SeSetProp(SetX, 'Document Number', Pairs.Values['PLIB_Teilenummer']) then
          Std := Std + 'Dokumentnummer ';
      except
        // Satz nicht vorhanden
      end;
      try
        Doc.Save;
        Saved := True;
      except
        Saved := False;
      end;
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        ShowMessage('Die Eigenschaften konnten nicht geschrieben werden:' + LineEnding +
          LineEnding + SolidEdgeHint(E));
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
    Pairs.Free;
  end;
  Doc := Unassigned;
  SE := Unassigned;
  Desc := 'In ' + ExtractFileName(Path) + ' wurden ' + IntToStr(Ok) +
    ' benutzerdefinierte Eigenschaften (PLIB_...) geschrieben.';
  if Std <> '' then Desc := Desc + LineEnding + 'Standardeigenschaften: ' + Std;
  if Failed <> '' then Desc := Desc + LineEnding + 'Nicht geschrieben: ' + Failed;
  if Saved then
    Desc := Desc + LineEnding + 'Die Datei wurde gespeichert.'
  else
    Desc := Desc + LineEnding + 'Die Datei konnte nicht gespeichert werden (schreibgeschützt?).' +
      ' Speichere sie in Solid Edge von Hand.';
  ShowMessage(Desc);
  ShowStatus('Eigenschaften nach Solid Edge geschrieben.');
end;
{$ELSE}
function TMainForm.SeGetApp(out SE: Variant): Boolean;
begin
  Result := False;
end;

function TMainForm.SeOpenFile(const APath: string; out SE, Doc: Variant): Boolean;
begin
  Result := False;
end;

function TMainForm.SeTemplateFor(const SE: Variant): string;
begin
  Result := '';
end;

procedure TMainForm.BtnSeOpen(Sender: TObject);
begin
  ShowMessage('Die Solid-Edge-Anbindung gibt es nur unter Windows.');
end;

procedure TMainForm.BtnSeWriteProps(Sender: TObject);
begin
  ShowMessage('Die Solid-Edge-Anbindung gibt es nur unter Windows.');
end;
{$ENDIF}

{ ---------- Solid Edge: aktuelles Dokument finden, Teil in Baugruppe einfuegen ---------- }

{$IFDEF WINDOWS}
{ Liest den Wert einer Eigenschaft aus einem Solid-Edge-Eigenschaftssatz }
function SeReadProp(const AProps: Variant; const AName: string): string;
var
  i, n: Integer;
  P: Variant;
begin
  Result := '';
  try
    n := AProps.Count;
    for i := 1 to n do
    begin
      P := AProps.Item(i);
      if SameText(VarToStr(P.Name), AName) then
      begin
        Result := VarToStr(P.Value);
        Exit;
      end;
    end;
  except
    Result := '';
  end;
end;

{ Zeigt in PLIB das Teil zum aktuell aktiven Solid-Edge-Dokument }
procedure TMainForm.BtnSeFind(Sender: TObject);
var
  SE, Docs, Doc, PropSets, Custom: Variant;
  FullName, PartNo: string;
  Q: TSQLQuery;
  FoundId, FoundClass, Cur: Int64;
begin
  try
    SE := GetActiveOleObject('SolidEdge.Application');
  except
    ShowMessage('Solid Edge läuft nicht. Starte Solid Edge und öffne ein Dokument.');
    Exit;
  end;
  PartNo := '';
  try
    Docs := SE.Documents;
    if StrToIntDef(VarToStr(Docs.Count), 0) = 0 then
    begin
      ShowMessage('In Solid Edge ist kein Dokument geöffnet.');
      Exit;
    end;
    Doc := SE.ActiveDocument;
    FullName := VarToStr(Doc.FullName);
    try
      PropSets := Doc.Properties;
      Custom := PropSets.Item('Custom');
      PartNo := SeReadProp(Custom, 'PLIB_Teilenummer');
    except
      PartNo := '';
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Das aktive Dokument lässt sich nicht abfragen:' + LineEnding +
        LineEnding + SolidEdgeHint(E));
      Exit;
    end;
  end;

  // 1. ueber den gespeicherten Pfad
  FoundId := 0;
  FoundClass := 0;
  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := DbCtx.Conn;
    Q.Transaction := DbCtx.Trans;
    Q.SQL.Text := 'SELECT id, class_id, cad_path FROM part ' +
      'WHERE COALESCE(cad_path,'''') <> ''''';
    Q.Open;
    while not Q.EOF do
    begin
      if SameText(CadFullPath(FieldText(Q.Fields[2])), FullName) then
      begin
        FoundId := Q.Fields[0].AsLargeInt;
        FoundClass := Q.Fields[1].AsLargeInt;
        Break;
      end;
      Q.Next;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
  if FoundId <> 0 then
  begin
    SelectClass(FoundClass);
    LoadParts;
    SelectPart(FoundId);
    ShowStatus('Gefunden: ' + RowStr('part', 'part_number', FoundId));
    Exit;
  end;

  // 2. ueber die Eigenschaft PLIB_Teilenummer in der Datei
  if PartNo <> '' then
  begin
    FoundId := ScalarInt('SELECT id FROM part WHERE part_number=' + QuotedStr(PartNo));
    if FoundId <> 0 then
    begin
      FoundClass := ScalarInt('SELECT class_id FROM part WHERE id=' + IntToStr(FoundId));
      if MessageDlg('Die Datei trägt die Eigenschaft PLIB_Teilenummer = ' + PartNo +
        ', ist in PLIB aber unter einem anderen Pfad hinterlegt oder gar nicht ' +
        'zugeordnet.' + LineEnding + LineEnding +
        'Zuordnung auf diese Datei aktualisieren?', mtConfirmation, [mbYes, mbNo], 0) =
        mrYes then
        Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d',
          [QuotedStr(CadStoredPath(FullName)), FoundId]));
      SelectClass(FoundClass);
      LoadParts;
      SelectPart(FoundId);
      ShowStatus('Gefunden über PLIB_Teilenummer: ' + PartNo);
      Exit;
    end;
  end;

  // 3. nicht gefunden: dem gewaehlten Teil zuordnen anbieten
  Cur := CurPart;
  if Cur = 0 then
  begin
    ShowMessage('Zu diesem Solid-Edge-Dokument gibt es noch kein PLIB-Teil:' + LineEnding +
      ExtractFileName(FullName) + LineEnding + LineEnding +
      'Wähle in PLIB ein Teil aus und wiederhole den Befehl, um das Dokument zuzuordnen.');
    Exit;
  end;
  if MessageDlg('Zu diesem Solid-Edge-Dokument gibt es noch kein PLIB-Teil:' + LineEnding +
    ExtractFileName(FullName) + LineEnding + LineEnding +
    'Soll es dem in PLIB gewählten Teil ' + RowStr('part', 'part_number', Cur) +
    ' zugeordnet werden?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Exec(Format('UPDATE part SET cad_path=%s WHERE id=%d',
      [QuotedStr(CadStoredPath(FullName)), Cur]));
    LoadParts;
    SelectPart(Cur);
    ShowStatus('CAD-Datei zugeordnet.');
  end;
end;

{ Fuegt die CAD-Datei des gewaehlten Teils in die aktive Baugruppe ein }
procedure TMainForm.BtnSeInsert(Sender: TObject);
var
  Part: Int64;
  Path: string;
  SE, Docs, Doc, Occs: Variant;
begin
  Part := CurPart;
  if Part = 0 then
  begin
    ShowMessage('Bitte zuerst ein Teil in der Teileliste wählen.');
    Exit;
  end;
  Path := CadFullPath(RowStr('part', 'cad_path', Part));
  if Path = '' then
  begin
    ShowMessage('Diesem Teil ist noch keine CAD-Datei zugeordnet.');
    Exit;
  end;
  if not FileExists(Path) then
  begin
    ShowMessage('Die CAD-Datei wurde nicht gefunden:' + LineEnding + Path);
    Exit;
  end;
  try
    SE := GetActiveOleObject('SolidEdge.Application');
  except
    ShowMessage('Solid Edge läuft nicht. Öffne in Solid Edge die Baugruppe, in die das ' +
      'Teil eingefügt werden soll.');
    Exit;
  end;
  try
    Docs := SE.Documents;
    if StrToIntDef(VarToStr(Docs.Count), 0) = 0 then
    begin
      ShowMessage('In Solid Edge ist keine Baugruppe geöffnet.');
      Exit;
    end;
    Doc := SE.ActiveDocument;
    try
      Occs := Doc.Occurrences;
    except
      ShowMessage('Das aktive Solid-Edge-Dokument ist keine Baugruppe.' + LineEnding +
        'Öffne eine Baugruppe (.asm) und mache sie zum aktiven Fenster.');
      Exit;
    end;
    if SameText(VarToStr(Doc.FullName), Path) then
    begin
      ShowMessage('Ein Teil lässt sich nicht in sich selbst einfügen.');
      Exit;
    end;
    Occs.AddByFilename(Path);
    try
      SE.Activate;
    except
      // Vordergrund ist nicht entscheidend
    end;
    ShowStatus('In die Baugruppe eingefügt: ' + ExtractFileName(Path));
    ShowMessage('Das Teil ' + RowStr('part', 'part_number', Part) +
      ' wurde in die Baugruppe ' + ExtractFileName(VarToStr(Doc.FullName)) +
      ' eingefügt. Positioniere es in Solid Edge.');
  except
    on E: Exception do
      ShowMessage('Das Teil konnte nicht eingefügt werden:' + LineEnding + LineEnding +
        SolidEdgeHint(E));
  end;
end;
{$ELSE}
procedure TMainForm.BtnSeFind(Sender: TObject);
begin
  ShowMessage('Die Solid-Edge-Anbindung gibt es nur unter Windows.');
end;

procedure TMainForm.BtnSeInsert(Sender: TObject);
begin
  ShowMessage('Die Solid-Edge-Anbindung gibt es nur unter Windows.');
end;
{$ENDIF}

{ ---------- Spaltenreihenfolge der Tabellen ---------- }

{ Wird aufgerufen, wenn der Benutzer eine Spalte verschoben hat: Reihenfolge merken }
procedure TMainForm.GridColMoved(Sender: TObject; IsColumn: Boolean; sIndex, tIndex: Integer);
var
  G: TStringGrid;
  Master, Cur: TStringList;
  c: Integer;
begin
  if FApplyingCols or (not IsColumn) then Exit;
  G := Sender as TStringGrid;
  if G = GridParts then Master := ColOrderParts else Master := ColOrderValues;
  Cur := TStringList.Create;
  try
    for c := 0 to G.ColCount - 1 do
      Cur.Add(G.Cells[c, 0]);
    MergeOrder(Master, Cur);
  finally
    Cur.Free;
  end;
  ShowStatus('Spaltenreihenfolge geändert (wird gemerkt).');
end;

{ Stellt die gemerkte Reihenfolge in der frisch gefuellten Tabelle her }
procedure TMainForm.ApplyColOrder(AGrid: TStringGrid; AOrder: TStringList);
var
  k, i, From, Target: Integer;
begin
  if (AOrder.Count = 0) or (AGrid.ColCount < 2) then Exit;
  FApplyingCols := True;
  try
    Target := 0;
    for k := 0 to AOrder.Count - 1 do
    begin
      From := -1;
      for i := Target to AGrid.ColCount - 1 do
        if SameText(AGrid.Cells[i, 0], AOrder[k]) then
        begin
          From := i;
          Break;
        end;
      if From < 0 then Continue;   // Spalte gibt es bei dieser Klasse nicht
      if From <> Target then AGrid.MoveColRow(True, From, Target);
      Inc(Target);
    end;
  finally
    FApplyingCols := False;
  end;
end;

{ Schluessel einer Klasse fuer die gemerkten Spalteneinstellungen (der Klassencode, in allen
  Datenbanken gleich) }
function TMainForm.ClassCodeKey(AClass: Int64): string;
begin
  Result := StringReplace(ScalarStr('SELECT code FROM class WHERE id=' + IntToStr(AClass)),
    '=', '_', [rfReplaceAll]);
  if Result = '' then Result := 'id' + IntToStr(AClass);
end;

{ Ausgeblendete Spalten der Teileliste fuer eine Klasse: gilt die eigene Einstellung der Klasse,
  sonst die der naechsten Oberklasse, sonst der Standard }
procedure TMainForm.PartsHiddenFor(AClass: Int64; AOut: TStringList);
var
  Cls: Int64;
  V: string;
  Guard: Integer;
begin
  AOut.Clear;
  Cls := AClass;
  Guard := 0;
  while (Cls <> 0) and (Guard < 50) do
  begin
    V := ColHiddenByClass.Values[ClassCodeKey(Cls)];
    if V <> '' then
    begin
      SplitBar(Copy(V, 2, Length(V)), AOut);
      Exit;
    end;
    Cls := StrToInt64Def(RowStr('class', 'parent_id', Cls), 0);   // aus dem Zwischenspeicher
    Inc(Guard);
  end;
  AOut.AddStrings(ColHiddenParts);
end;

procedure TMainForm.LoadColHidden(AIni: TIniFile);
var
  Keys: TStringList;
  I: Integer;
begin
  ColHiddenByClass.Clear;
  Keys := TStringList.Create;
  try
    AIni.ReadSection('SpaltenKlasse', Keys);
    for I := 0 to Keys.Count - 1 do
      ColHiddenByClass.Values[Keys[I]] := AIni.ReadString('SpaltenKlasse', Keys[I], '|');
  finally
    Keys.Free;
  end;
end;

procedure TMainForm.SaveColHidden(AIni: TIniFile);
var
  I: Integer;
begin
  AIni.EraseSection('SpaltenKlasse');
  for I := 0 to ColHiddenByClass.Count - 1 do
    AIni.WriteString('SpaltenKlasse', ColHiddenByClass.Names[I],
      ColHiddenByClass.ValueFromIndex[I]);
end;

{ ---------- Rechtsklick auf die Ueberschrift der Teileliste: Spalten aus-/einblenden ---------- }

{ Blendet eine Spalte der Teileliste fuer die gewaehlte Klasse aus oder ein }
procedure TMainForm.SetPartsHidden(const AName: string; AHide: Boolean);
var
  Eff: TStringList;
  I, Vis: Integer;
  Keep: Int64;
begin
  if CurClass = 0 then Exit;
  if AHide then
  begin
    Vis := 0;
    for I := 0 to GridParts.ColCount - 1 do
      if (GridParts.ColWidths[I] > 0) and (not SameText(GridParts.Cells[I, 0], AName)) then
        Inc(Vis);
    if Vis = 0 then
    begin
      ShowStatus('Die letzte sichtbare Spalte bleibt stehen.');
      Exit;
    end;
  end;
  Eff := TStringList.Create;
  try
    PartsHiddenFor(CurClass, Eff);
    for I := Eff.Count - 1 downto 0 do
      if SameText(Eff[I], AName) then Eff.Delete(I);
    if AHide then Eff.Add(AName);
    ColHiddenByClass.Values[ClassCodeKey(CurClass)] := '|' + JoinBar(Eff);
  finally
    Eff.Free;
  end;
  Keep := CurPart;
  LoadParts;
  if Keep <> 0 then SelectPart(Keep);
end;

procedure TMainForm.HeadHide(Sender: TObject);
begin
  SetPartsHidden((Sender as TMenuItem).Hint, True);
  ShowStatus('Spalte "' + (Sender as TMenuItem).Hint +
    '" ausgeblendet. Rechtsklick auf eine Überschrift blendet sie wieder ein.');
end;

procedure TMainForm.HeadToggle(Sender: TObject);
var
  Mi: TMenuItem;
begin
  Mi := Sender as TMenuItem;
  SetPartsHidden(Mi.Hint, Mi.Checked);   // war angehakt: jetzt ausblenden; sonst einblenden
end;

procedure TMainForm.HeadShowAll(Sender: TObject);
var
  Keep: Int64;
begin
  if CurClass = 0 then Exit;
  ColHiddenByClass.Values[ClassCodeKey(CurClass)] := '|';
  Keep := CurPart;
  LoadParts;
  if Keep <> 0 then SelectPart(Keep);
end;

procedure TMainForm.HeadReset(Sender: TObject);
var
  Keep: Int64;
begin
  if CurClass = 0 then Exit;
  ColHiddenByClass.Values[ClassCodeKey(CurClass)] := '';
  Keep := CurPart;
  LoadParts;
  if Keep <> 0 then SelectPart(Keep);
end;

procedure TMainForm.GridPartsContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  C, R, I: Integer;
  Nm: string;
  Eff: TStringList;
  Mi: TMenuItem;
  Pt: TPoint;
begin
  if (MousePos.X < 0) or (MousePos.Y < 0) then Exit;   // Kontextmenue-Taste: Zeilenmenue
  GridParts.MouseToCell(MousePos.X, MousePos.Y, C, R);
  if R <> 0 then Exit;            // normale Zeilen: das vorhandene Menue
  Handled := True;
  if CurClass = 0 then Exit;
  if PopHead = nil then
    PopHead := TPopupMenu.Create(Self);
  PopHead.Items.Clear;
  Eff := TStringList.Create;
  try
    PartsHiddenFor(CurClass, Eff);
    if (C >= 0) and (C < GridParts.ColCount) then
    begin
      Nm := GridParts.Cells[C, 0];
      if (Nm <> '') and (not SameText(Nm, 'Nr')) then
      begin
        Mi := TMenuItem.Create(PopHead);
        Mi.Caption := 'Spalte "' + Nm + '" ausblenden';
        Mi.Hint := Nm;
        Mi.OnClick := @HeadHide;
        PopHead.Items.Add(Mi);
        Mi := TMenuItem.Create(PopHead);
        Mi.Caption := '-';
        PopHead.Items.Add(Mi);
      end;
    end;
    for I := 0 to GridParts.ColCount - 1 do
    begin
      Nm := GridParts.Cells[I, 0];
      if (Nm = '') or SameText(Nm, 'Nr') then Continue;
      Mi := TMenuItem.Create(PopHead);
      Mi.Caption := Nm;
      Mi.Hint := Nm;
      Mi.Checked := Eff.IndexOf(Nm) < 0;
      Mi.OnClick := @HeadToggle;
      PopHead.Items.Add(Mi);
    end;
  finally
    Eff.Free;
  end;
  Mi := TMenuItem.Create(PopHead);
  Mi.Caption := '-';
  PopHead.Items.Add(Mi);
  Mi := TMenuItem.Create(PopHead);
  Mi.Caption := 'Alle Spalten anzeigen';
  Mi.OnClick := @HeadShowAll;
  PopHead.Items.Add(Mi);
  Mi := TMenuItem.Create(PopHead);
  Mi.Caption := 'Für diese Klasse zurücksetzen';
  Mi.OnClick := @HeadReset;
  PopHead.Items.Add(Mi);
  Pt := GridParts.ClientToScreen(MousePos);
  PopHead.PopUp(Pt.X, Pt.Y);
end;

{ Dialog: Spalten der Teileliste (je Klasse) und der Werteliste ein- und ausblenden }
procedure TMainForm.MnuColumns(Sender: TObject);
var
  F: TForm;
  LbP, LbV: TLabel;
  ClP, ClV: TCheckListBox;
  BtOk, BtCancel, BtReset: TButton;
  Keep, Cls: Int64;
  Eff: TStringList;
  Res: Integer;
  Key, ClsName: string;

  procedure FillList(AList: TCheckListBox; AGrid: TStringGrid; AHidden: TStringList);
  var
    c: Integer;
    Nm: string;
  begin
    for c := 0 to AGrid.ColCount - 1 do
    begin
      Nm := AGrid.Cells[c, 0];
      if (Nm = '') or SameText(Nm, 'Nr') then Continue;
      AList.Items.Add(Nm);
      AList.Checked[AList.Items.Count - 1] := AHidden.IndexOf(Nm) < 0;
    end;
  end;

  procedure Collect(AList: TCheckListBox; AGrid: TStringGrid; AHidden: TStringList);
  var
    i, j: Integer;
  begin
    // Eintraege behalten, die es in der aktuellen Tabelle nicht gibt
    for j := AHidden.Count - 1 downto 0 do
      if ColIdx(AGrid, AHidden[j]) >= 0 then AHidden.Delete(j);
    for i := 0 to AList.Items.Count - 1 do
      if not AList.Checked[i] then AHidden.Add(AList.Items[i]);
  end;

begin
  Cls := CurClass;
  if Cls = 0 then
  begin
    ShowMessage('Bitte zuerst eine Klasse im Baum wählen.');
    Exit;
  end;
  Key := ClassCodeKey(Cls);
  ClsName := '';
  if Tree.Selected <> nil then ClsName := Tree.Selected.Text;
  Eff := TStringList.Create;
  try
    PartsHiddenFor(Cls, Eff);
    F := TForm.CreateNew(Self);
    try
      F.Caption := 'Tabellenspalten';
      F.BorderStyle := bsDialog;
      F.Position := poOwnerFormCenter;
      F.ClientWidth := 580;
      F.ClientHeight := 420;
      LbP := TLabel.Create(F);
      LbP.Parent := F;
      LbP.SetBounds(16, 12, 260, 40);
      LbP.AutoSize := False;
      LbP.WordWrap := True;
      LbP.Caption := 'Teileliste der Klasse "' + ClsName + '" und ihrer Unterklassen (Haken = anzeigen):';
      LbV := TLabel.Create(F);
      LbV.Parent := F;
      LbV.SetBounds(300, 12, 260, 40);
      LbV.AutoSize := False;
      LbV.WordWrap := True;
      LbV.Caption := 'Werteliste, für alle Teile gleich (Haken = anzeigen):';
      ClP := TCheckListBox.Create(F);
      ClP.Parent := F;
      ClP.SetBounds(16, 58, 264, 292);
      ClV := TCheckListBox.Create(F);
      ClV.Parent := F;
      ClV.SetBounds(300, 58, 264, 292);
      FillList(ClP, GridParts, Eff);
      FillList(ClV, GridValues, ColHiddenValues);
      BtReset := TButton.Create(F);
      BtReset.Parent := F;
      BtReset.SetBounds(16, 366, 250, 30);
      BtReset.Caption := 'Für diese Klasse zurücksetzen';
      BtReset.ModalResult := mrYes;
      BtOk := TButton.Create(F);
      BtOk.Parent := F;
      BtOk.SetBounds(364, 366, 96, 30);
      BtOk.Caption := 'OK';
      BtOk.Default := True;
      BtOk.ModalResult := mrOk;
      BtCancel := TButton.Create(F);
      BtCancel.Parent := F;
      BtCancel.SetBounds(468, 366, 96, 30);
      BtCancel.Caption := 'Abbrechen';
      BtCancel.Cancel := True;
      BtCancel.ModalResult := mrCancel;
      Res := F.ShowModal;
      if Res = mrYes then
        ColHiddenByClass.Values[Key] := ''       // Einstellung der Klasse entfernen: erbt wieder
      else if Res = mrOk then
      begin
        Collect(ClP, GridParts, Eff);
        ColHiddenByClass.Values[Key] := '|' + JoinBar(Eff);
        Collect(ClV, GridValues, ColHiddenValues);
      end
      else
        Exit;
    finally
      F.Free;
    end;
  finally
    Eff.Free;
  end;
  Keep := CurPart;
  LoadParts;
  if Keep <> 0 then SelectPart(Keep);
  ShowStatus('Tabellenspalten geändert (wird gemerkt).');
end;

procedure TMainForm.MnuResetCols(Sender: TObject);
var
  Keep: Int64;
begin
  Keep := CurPart;
  ColOrderParts.Clear;
  ColOrderValues.Clear;
  ColHiddenParts.Clear;
  ColHiddenParts.Add('Klasse');
  ColHiddenValues.Clear;
  ColHiddenByClass.Clear;
  LoadParts;
  if Keep <> 0 then SelectPart(Keep);
  ShowStatus('Spaltenreihenfolge zurückgesetzt.');
end;

{ Oeffnet die ausfuehrliche Bedienungsanleitung (HTML-Datei neben dem Programm) }
function TMainForm.HelpFileName: string;
begin
  Result := ResDir + 'hilfe' + PathDelim + 'hilfe.html';
end;

procedure TMainForm.EnsureHelpLoaded;
begin
  if FHelpLoaded or (HelpView = nil) or (DockMgr = nil) then Exit;
  if not DockMgr.PaneVisible('help') then Exit;
  if not FileExists(HelpFileName) then Exit;
  try
    HelpView.LoadFromFile(HelpFileName);
    FHelpLoaded := True;
  except
    on E: Exception do
      ShowMessage('Die Anleitung konnte nicht geladen werden:' + LineEnding + E.Message);
  end;
end;

{ Zeigt den Anleitungs-Bereich; AAnchor = Name einer Sprungmarke (leer = Anfang) }
procedure TMainForm.ShowHelpAt(const AAnchor: string);
begin
  if not FileExists(HelpFileName) then
  begin
    ShowMessage('Die Anleitung (hilfe\hilfe.html) wurde nicht gefunden.' +
      LineEnding + LineEnding + 'Kopiere den Ordner "hilfe" neben die plib.exe:' +
      LineEnding + ResDir);
    Exit;
  end;
  if not DockMgr.PaneVisible('help') then DockMgr.SetPaneVisible('help', True);
  EnsureHelpLoaded;
  if FHelpLoaded and (AAnchor <> '') then HelpView.PositionTo(AAnchor);
end;

{ Suche in der Anleitung (THtmlViewer.FindEx). Eine neue Suche beginnt am Anfang
  (Dokument neu laden loescht die Markierung), 'Weiter' laeuft ab der letzten Fundstelle
  und springt am Ende wieder an den Anfang. }
procedure TMainForm.HelpDoFind(AReverse: Boolean);
var
  Q: string;
  Found, NewQuery: Boolean;
begin
  Q := Trim(HelpEdit.Text);
  if Q = '' then
  begin
    HelpInfo.Caption := '';
    Exit;
  end;
  if not FileExists(HelpFileName) then
  begin
    ShowHelpAt('');
    Exit;
  end;
  if not DockMgr.PaneVisible('help') then DockMgr.SetPaneVisible('help', True);
  EnsureHelpLoaded;
  if not FHelpLoaded then Exit;
  NewQuery := (Q <> FHelpQuery);
  if NewQuery and not AReverse then
  begin
    FHelpLoaded := False;      // neu laden: Markierung weg, Anfang des Dokuments
    EnsureHelpLoaded;
    if not FHelpLoaded then Exit;
  end;
  FHelpQuery := Q;
  Found := HelpView.FindEx(UTF8Decode(Q), False, AReverse);
  if (not Found) and (not NewQuery) then
  begin
    if AReverse then
    begin
      HelpInfo.Caption := 'Anfang erreicht.';
      Exit;
    end;
    FHelpLoaded := False;      // am Ende angekommen: von vorn weitersuchen
    EnsureHelpLoaded;
    if not FHelpLoaded then Exit;
    Found := HelpView.FindEx(UTF8Decode(Q), False, False);
    if Found then
      HelpInfo.Caption := 'Von vorn weitergesucht.';
  end
  else if Found then
    HelpInfo.Caption := '';
  if not Found then
    HelpInfo.Caption := 'Nicht gefunden.';
end;

procedure TMainForm.HelpFindNext(Sender: TObject);
begin
  HelpDoFind(False);
end;

procedure TMainForm.HelpFindPrev(Sender: TObject);
begin
  HelpDoFind(True);
end;

{ Suchleiste der Anleitung: Groessen aus der Schrifthoehe, damit sie bei 4K und grosser Schrift
  nicht zu klein ist }
procedure TMainForm.HelpBarResize(Sender: TObject);
var
  TH, EdH, BarH, X: Integer;
  Bn, Bp: TButton;
begin
  if (PHelpBar = nil) or (HelpEdit = nil) then Exit;
  try
    TH := PHelpBar.Canvas.TextHeight('Ag');
    if TH < 12 then TH := 12;
    EdH := TH + 14;
    BarH := EdH + 14;
    if PHelpBar.Height <> BarH then PHelpBar.Height := BarH;
    X := 10;
    HelpLb.Left := X;
    HelpLb.Top := (BarH - HelpLb.Height) div 2;
    X := HelpLb.Left + HelpLb.Width + 10;
    HelpEdit.SetBounds(X, (BarH - EdH) div 2, TH * 20, EdH);
    X := X + HelpEdit.Width + 10;
    Bn := TButton(FindComponent('HelpBtNext'));
    Bp := TButton(FindComponent('HelpBtPrev'));
    if Bn <> nil then
    begin
      Bn.SetBounds(X, (BarH - EdH - 2) div 2, TH * 6, EdH + 2);
      X := X + Bn.Width + 8;
    end;
    if Bp <> nil then
    begin
      Bp.SetBounds(X, (BarH - EdH - 2) div 2, TH * 6, EdH + 2);
      X := X + Bp.Width + 14;
    end;
    HelpInfo.Left := X;
    HelpInfo.Top := (BarH - HelpInfo.Height) div 2;
  except
  end;
end;

procedure TMainForm.HelpEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    HelpDoFind(ssShift in Shift);
    Key := 0;
  end
  else if Key = VK_F3 then
  begin
    HelpDoFind(ssShift in Shift);
    Key := 0;
  end;
end;

procedure TMainForm.HelpViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F3 then
  begin
    HelpDoFind(ssShift in Shift);
    Key := 0;
  end
  else if (Key = Ord('F')) and (ssCtrl in Shift) then
  begin
    HelpEdit.SetFocus;
    HelpEdit.SelectAll;
    Key := 0;
  end;
end;

procedure TMainForm.MnuManual(Sender: TObject);
var
  A: string;
begin
  A := '';
  if ActiveControl = Tree then A := 'baum'
  else if ActiveControl = GridParts then A := 'teileliste'
  else if ActiveControl = GridValues then A := 'werteliste';
  ShowHelpAt(A);
end;

procedure TMainForm.MnuManualBrowser(Sender: TObject);
var
  P: string;
begin
  P := ResDir + 'plib_hilfe.html';
  if FileExists(P) then
  begin
    if not OpenDocument(P) then
      ShowMessage('Die Bedienungsanleitung konnte nicht geöffnet werden:' + LineEnding + P);
  end
  else
    ShowMessage('Die Bedienungsanleitung (plib_hilfe.html) wurde nicht gefunden.' +
      LineEnding + LineEnding + 'Lege die Datei in den Ordner neben der plib.exe:' +
      LineEnding + ResDir);
end;

initialization
  ThemeInit(IniName);

end.
