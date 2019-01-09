program PTP;

uses
  Forms,
  UPTP in 'UPTP.pas' {FrmPTPPrincipal};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'PinBall Trainer Plus';
  Application.CreateForm(TFrmPTPPrincipal, FrmPTPPrincipal);
  Application.Run;
end.
