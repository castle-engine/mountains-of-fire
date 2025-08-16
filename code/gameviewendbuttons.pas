{
  Copyright 2014-2025 Michalis Kamburelis.

  This file is part of "Mountains Of Fire".

  "Mountains Of Fire" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Mountains Of Fire" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Game buttons on play screen. }
unit GameViewEndButtons;

interface

uses CastleControls, CastleUiControls;

type
  { Show buttons to restart/quit. }
  TViewEndButtons = class(TCastleView)
  private
    RestartButton, QuitButton: TCastleButton;
    procedure ClickQuit(Sender: TObject);
    procedure ClickRestart(Sender: TObject);
  public
    procedure Start; override;
    procedure Resize; override;
  end;

var
  ViewEndButtons: TViewEndButtons;

implementation

uses SysUtils,
  CastleWindow,
  GameInitialize, GameViewPlay;

procedure TViewEndButtons.ClickRestart(Sender: TObject);
begin
  Container.PopView(Self);
  ViewPlay.GameBegin;
end;

procedure TViewEndButtons.ClickQuit(Sender: TObject);
begin
  Application.MainWindow.Close;
end;

procedure TViewEndButtons.Start;
begin
  inherited;

  RestartButton := TCastleButton.Create(FreeAtStop);
  RestartButton.Caption := 'RESTART';
  RestartButton.Exists := false; // good default
  RestartButton.MinWidth := 200;
  RestartButton.MinHeight := 100;
  RestartButton.OnClick := {$ifdef FPC}@{$endif} ClickRestart;
  InsertFront(RestartButton);

  QuitButton := TCastleButton.Create(FreeAtStop);
  QuitButton.Caption := 'QUIT';
  QuitButton.Exists := false; // good default
  QuitButton.MinWidth := RestartButton.MinWidth;
  QuitButton.MinHeight := RestartButton.MinHeight;
  QuitButton.OnClick := {$ifdef FPC}@{$endif} ClickQuit;
  InsertFront(QuitButton);
end;

procedure TViewEndButtons.Resize;
const
  Margin = 16;
begin
  inherited;
  RestartButton.Align(hpMiddle, hpMiddle);
  RestartButton.Align(vpBottom, vpMiddle, Margin div 2);
  QuitButton.Align(hpMiddle, hpMiddle);
  QuitButton.Align(vpTop, vpMiddle, -Margin div 2);
end;

end.
