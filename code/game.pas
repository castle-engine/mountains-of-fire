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

{ Implements the game application logic, independent from Android / standalone. }
unit Game;

interface

implementation

uses SysUtils,
  CastleResources,
  CastleUIControls, CastleWindow, CastleVectors, CastleControls,
  CastleSoundEngine, CastleFilesUtils, CastlePlayer,
  CastleApplicationProperties,
  CastleLevels, CastleImages, CastleKeysMouse,
  GameLevels, GamePlay, GameWindow;


{ TMyView -------------------------------------------------------------------- }

type
  { View that passes events to GameXxx global routines.

    TODO: This is a weird usage of TCastleView, caused by history
    (this code was originally written before TCastleView existed),
    should be refactored to follow more standard approach,
    see https://castle-engine.io/views .
    The GameXxx global routines should be remade to implement sthg like
    TGameView in GamePlay unit. }
  TMyView = class(TCastleView)
  public
    function Press(const Event: TInputPressRelease): boolean; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    procedure Resize; override;
  end;

function TMyView.Press(const Event: TInputPressRelease): boolean;
begin
  Result := inherited;
  GamePress(Container, Event);
end;

procedure TMyView.Update(const SecondsPassed: Single; var HandleInput: boolean);
begin
  inherited;
  GameUpdate(Container);
end;

procedure TMyView.Resize;
begin
  inherited;
  GameResize(Container);
end;

var
  MyView: TMyView;

{ initialization ------------------------------------------------------------- }

{ One-time initialization. }
procedure ApplicationInitialize;
var
  Background: TCastleSimpleBackground;
begin
  { do this before loading level and creating TWarm, as they use named sounds }
  SoundEngine.RepositoryURL := 'castle-data:/sounds/index.xml';
  SoundEngine.LoopingChannel[0].Volume := 0.5;

  PlayerInput_LeftRotate.MakeClear(true);
  PlayerInput_RightRotate.MakeClear(true);
  PlayerInput_LeftStrafe.MakeClear(true);
  PlayerInput_RightStrafe.MakeClear(true);
  //PlayerInput_Forward.Assign(K_None, K_None, #0, true, mbLeft, mwUp);
  PlayerInput_Forward.MakeClear(true);
  PlayerInput_Backward.MakeClear(true);
  PlayerInput_GravityUp.MakeClear(true);
  PlayerInput_Jump.MakeClear(true);
  PlayerInput_Crouch.MakeClear(true);

  Background := TCastleSimpleBackground.Create(Window);
  Background.Color := Vector4(0.1, 0, 0, 1);
  Window.Controls.InsertBack(Background);

  Resources.LoadFromFiles;
  Levels.LoadFromFiles;

  // TODO: GameBegin should change to TGamePlay.Start, https://castle-engine.io/views
  GameBegin;

  MyView := TMyView.Create(Application);
  Window.Container.View := MyView;
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  ApplicationProperties.ApplicationName := 'mountains_of_fire';

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindow.Create(Application);
  Window.FpsShowOnCaption := true;
  Application.MainWindow := Window;
end.
