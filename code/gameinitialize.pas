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

{ Cross-platform application initialization. }
unit GameInitialize;

interface

implementation

uses SysUtils,
  CastleResources,
  CastleUIControls, CastleWindow, CastleVectors, CastleControls,
  CastleSoundEngine, CastleFilesUtils, CastlePlayer,
  CastleApplicationProperties,
  CastleLevels, CastleImages, CastleKeysMouse,
  GameLevels, GameViewPlay, GameViewEndButtons;

{ initialization ------------------------------------------------------------- }

var
  Window: TCastleWindow;

{ One-time initialization. }
procedure ApplicationInitialize;
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

  Resources.LoadFromFiles;
  Levels.LoadFromFiles;

  ViewPlay := TViewPlay.Create(Application);
  ViewEndButtons := TViewEndButtons.Create(Application);
  Window.Container.View := ViewPlay;
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
