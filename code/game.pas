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
  CastleSoundEngine, CastleFilesUtils, CastleMaterialProperties, CastlePlayer,
  CastleLevels, CastleImages, CastleKeysMouse,
  GameLevels, GamePlay, GameWindow;

{ One-time initialization. }
procedure ApplicationInitialize;
var
  Background: TCastleSimpleBackground;
begin
  { do this before loading level and creating TWarm, as they use named sounds }
  SoundEngine.RepositoryURL := 'castle-data:/sounds/index.xml';
  SoundEngine.LoopingChannel[0].Volume := 0.5;

  MaterialProperties.URL := 'castle-data:/material_properties.xml';

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

  GameBegin;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  GamePress(Container, Event);
end;

procedure WindowUpdate(Container: TUIContainer);
begin
  GameUpdate(Container);
end;

procedure WindowResize(Container: TUIContainer);
begin
  GameResize(Container);
end;

function MyGetApplicationName: string;
begin
  Result := 'mountains_of_fire';
end;

initialization
  { This should be done as early as possible to mark our log lines correctly. }
  OnGetApplicationName := @MyGetApplicationName;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window and initialize Window callbacks }
  Window := TCastleWindowBase.Create(Application);
  Window.OnPress := @WindowPress;
  Window.OnUpdate := @WindowUpdate;
  Window.OnResize := @WindowResize;
  Window.FpsShowOnCaption := true;
  Application.MainWindow := Window;
end.
