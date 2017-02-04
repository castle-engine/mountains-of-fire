{
  Copyright 2014-2017 Michalis Kamburelis.

  This file is part of "Mountains Of Fire".

  "Mountains Of Fire" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Mountains Of Fire" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Game buttons on play screen. }
unit GameButtons;

interface

uses CastleControls;

type
  TRestartButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

  TQuitButton = class(TCastleButton)
  public
    procedure DoClick; override;
  end;

var
  RestartButton: TRestartButton;
  QuitButton: TQuitButton;

procedure ButtonsAdd;
procedure ButtonsRemove;
procedure ButtonsResize;

implementation

uses SysUtils,
  CastleWindow, CastleUIControls,
  Game, GameWindow, GamePlay;

procedure TRestartButton.DoClick;
begin
  GameBegin;
end;

procedure TQuitButton.DoClick;
begin
  Window.Close;
end;

procedure ButtonsAdd;
begin
  RestartButton := TRestartButton.Create(Application);
  RestartButton.Caption := 'RESTART';
  RestartButton.Exists := false; // good default
  RestartButton.MinWidth := 200;
  RestartButton.MinHeight := 100;
  Window.Controls.InsertFront(RestartButton);

  QuitButton := TQuitButton.Create(Application);
  QuitButton.Caption := 'QUIT';
  QuitButton.Exists := false; // good default
  QuitButton.MinWidth := RestartButton.MinWidth;
  QuitButton.MinHeight := RestartButton.MinHeight;
  Window.Controls.InsertFront(QuitButton);
end;

procedure ButtonsRemove;
begin
  FreeAndNil(RestartButton);
  FreeAndNil(QuitButton);
end;

procedure ButtonsResize;
const
  Margin = 16;
begin
  RestartButton.Align(hpMiddle, hpMiddle);
  RestartButton.Align(vpBottom, vpMiddle, Margin div 2);
  QuitButton.Align(hpMiddle, hpMiddle);
  QuitButton.Align(vpTop, vpMiddle, -Margin div 2);
end;

end.
