{
  Copyright 2014 Michalis Kamburelis.

  This file is part of "Mountains Of Fire".

  "Mountains Of Fire" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Mountains Of Fire" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Implements the game logic, independent from Android / standalone. }
unit Game;

interface

uses CastleLevels, CastlePlayer, CastleCameras, CastleSceneManager;

type
  TMySceneManager = class(TGameSceneManager)
    procedure Render; override;
  end;

var
  SceneManager: TMySceneManager;

  RightHanded: boolean = true;

implementation

uses SysUtils,
  CastleWarnings, CastleProgress, CastleWindowProgress, CastleResources,
  CastleUIControls, CastleKeysMouse, CastleWindow, CastleVectors, Castle3D,
  CastleRenderer, CastleMaterialProperties, CastleFilesUtils, CastleWindowTouch,
  CastleShapes, CastleUtils, CastleSoundEngine, CastleControls, CastleLog,
  CastleImages, CastleColors,
  X3DNodes, X3DFields, X3DTriangles, X3DCameraUtils,
  Game3D, GameWorm, GamePlayer3rdPerson, GameWindow, GameHUD, GamePlayer;

const
  LavaLifeLossSpeed = 5.0;
  RegenerateLifeSpeed = 5.0;

var
  PointLightOverPlayer: TPointLightNode;
  IceEffect: TEffectNode;

procedure TMySceneManager.Render;
begin
  { Player3rdPerson is visible only in WormViewport }
  Player3rdPerson.Disable;
  inherited;
  Player3rdPerson.Enable;
end;

{ One-time initialization. }
procedure ApplicationInitialize;
var
  Background: TCastleSimpleBackground;
begin
//  OnWarning := @OnWarningWrite;
  Progress.UserInterface := WindowProgressInterface;

  { do this before loading level and creating TWarm, as they use named sounds }
  SoundEngine.RepositoryURL := ApplicationData('sounds/index.xml');
  SoundEngine.MusicPlayer.MusicVolume := 0.5;

  MaterialProperties.URL := ApplicationData('material_properties.xml');

  SceneManager := TMySceneManager.Create(Window);
  Window.Controls.InsertFront(SceneManager);

  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  Player.Camera.MouseLook := true;

  PlayerInput_LeftRot.MakeClear(true);
  PlayerInput_RightRot.MakeClear(true);
  PlayerInput_LeftStrafe.MakeClear(true);
  PlayerInput_RightStrafe.MakeClear(true);
  //PlayerInput_Forward.Assign(K_None, K_None, #0, true, mbLeft, mwUp);
  PlayerInput_Forward.MakeClear(true);
  PlayerInput_Backward.MakeClear(true);
  PlayerInput_GravityUp.MakeClear(true);
  PlayerInput_Jump.MakeClear(true);
  PlayerInput_Crouch.MakeClear(true);

  // SceneManager.UseGlobalLights := true;

  ViewportPlayer := SceneManager;
  Window.Container.ForceCaptureInput := ViewportPlayer;

  ViewportWorm := TCastleViewport.Create(Application);
  ViewportWorm.SceneManager := SceneManager;
  Window.Controls.InsertFront(ViewportWorm);

  PlayerHud := TPlayerHud.Create(Window);
  Window.Controls.InsertFront(PlayerHud);

  WormHud := TWormHud.Create(Window);
  Window.Controls.InsertFront(WormHud);

  Background := TCastleSimpleBackground.Create(Window);
  Background.Color := Vector4Single(0.1, 0, 0, 1);
  Window.Controls.InsertBack(Background);

  WormIntroLabel := TCastleLabel.Create(Window);
  WormIntroLabel.Text.Text :=
    'Rotate by moving the mouse.' +LineEnding+
    LineEnding+
    'Click mouse left button to move forward.' +LineEnding+
    'Click again the same button to stop moving.' +LineEnding+
    LineEnding+
    'Likewise, click mouse right button to move backward.' +LineEnding+
    LineEnding+
    'First, find your pet sandworm.' +LineEnding+
    'It will help you to move through lava.' +LineEnding+
    LineEnding+
    'You are hurt when walking on lava.' +LineEnding+
    'You regenerate when you are on rocks,' +LineEnding+
    'or on the blue water very close to the sandworm.';
  WormIntroLabel.Frame := false;
  WormIntroLabel.Color := Red;
  Window.Controls.InsertFront(WormIntroLabel);

  WormLifeLabel := TCastleLabel.Create(Window);
  WormLifeLabel.Text.Text :=
    'Move the sandworm or it will die soon.' +LineEnding+
    LineEnding+
    'Move the sandworm using W/S keys.' +LineEnding+
    'Rotate the sandworm using A/D keys.';
  WormLifeLabel.Frame := false;
  WormLifeLabel.Color := Yellow;
  WormLifeLabel.Exists := false;
  Window.Controls.InsertFront(WormLifeLabel);

  Resources.LoadFromFiles;
  Levels.LoadFromFiles;
end;

procedure WindowOpen(Container: TUIContainer);
begin
  Progress.UserInterface.Image := LoadImage(ApplicationData('level1/skybox/gloomy_preview.jpg'), [TRGBImage]) as TRGBImage;
  try
    Progress.Init(1, 'Loading worm');
    Worm := TWorm.Create(Window);
    Progress.Step;
    Progress.Fini;

    Progress.Init(1, 'Loading player');
    Player3rdPerson := TPlayer3rdPerson.Create(Window);
    Progress.Step;
    Progress.Fini;
  finally
    Progress.UserInterface.Image.Free;
    Progress.UserInterface.Image := nil;
  end;

  if ViewportWorm.Camera = nil then
    ViewportWorm.Camera := SceneManager.CreateDefaultCamera(ViewportWorm);
  Worm.FollowCamera := ViewportWorm.Camera as TUniversalCamera;
  Worm.FollowCamera.NavigationType := ntWalk;
  Worm.FollowCamera.Walk.Gravity := false;
  Worm.FollowCamera.GoToInitial;
  Worm.FollowCamera.Input := [];
  Worm.FollowCamera.Radius := 0.1; // allow near projection plane (calculated based on this radius) be larger
  Worm.FollowCameraUpdateNow;

  SceneManager.LoadLevel('mountains');
  SetAttributes(SceneManager.MainScene.Attributes);

  PointLightOverPlayer := SceneManager.MainScene.RootNode.FindNodeByName(
    TPointLightNode, 'PointLightOverPlayer', false) as TPointLightNode;

  IceEffect := SceneManager.MainScene.RootNode.FindNodeByName(
    TEffectNode, 'IceEffect', false) as TEffectNode;

  SceneManager.Items.Add(Worm);
  SceneManager.Items.Add(Player3rdPerson);

  ViewportWorm.Exists := false;
  WormHud.Exists := false;
  WormIntroLabel.Exists := true;
end;

procedure WindowPress(Container: TUIContainer; const Event: TInputPressRelease);
{$ifdef DEBUG_KEYS}
var
  Pos, Dir, Up, GravityUp: TVector3Single;
{$endif}
begin
  {$ifdef DEBUG_KEYS}
  if Event.IsKey(K_F2) then
  begin
    { debug examine view }
    { make sure camera is TUniversalCamera }
    SceneManager.Camera := SceneManager.CreateDefaultCamera(SceneManager);
    (SceneManager.Camera as TUniversalCamera).NavigationType := ntExamine;
  end;

  if Event.IsKey(K_F3) then
  begin
    InitializeLog;
    Player.Camera.GetView(Pos, Dir, Up, GravityUp);
    WritelnLog('Camera', MakeCameraStr(cvVrml2_X3d, false, Pos, Dir, Up, GravityUp));
  end;
  {$endif}

  if Event.IsKey(K_F5) then
    Window.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(K_Escape) then
    Window.Close;

  if Event.IsMouseButton(mbLeft) and not Player.Dead then
  begin
    Player.Camera.MoveForward := not Player.Camera.MoveForward;
    { make sure only one MoveXxx is true, otherwise it's confusing what is going on }
    if Player.Camera.MoveForward then
      Player.Camera.MoveBackward := false;
  end;
  if Event.IsMouseButton(mbRight) and not Player.Dead then
  begin
    Player.Camera.MoveBackward := not Player.Camera.MoveBackward;
    if Player.Camera.MoveBackward then
      Player.Camera.MoveForward := false;
  end;
end;

procedure WindowRelease(Container: TUIContainer; const Event: TInputPressRelease);
begin
  // if Event.IsMouseButton(mbLeft) then
  //   Player.Camera.MoveForward := false;
  // if Event.IsMouseButton(mbRight) then
  //   Player.Camera.MoveBackward := false;
end;

procedure WindowUpdate(Container: TUIContainer);

  function PlayerOverLava: boolean;
  var
    Collision: TRayCollision;
  begin
    Player.Disable;
    Player3rdPerson.Disable;
    try
      Collision := SceneManager.Items.WorldRay(Player.Position, -SceneManager.GravityUp);
      Result :=
        (Collision <> nil) and
        (Collision.First.Triangle <> nil) and
        (PTriangle(Collision.First.Triangle)^.Shape <> nil) and
        (TShape(PTriangle(Collision.First.Triangle)^.Shape).Node <> nil) and
        (TShape(PTriangle(Collision.First.Triangle)^.Shape).Node.NodeName = 'LavaShape');
      FreeAndNil(Collision);
    finally
      Player.Enable;
      Player3rdPerson.Enable;
    end;
  end;

const
  { How far ice works. Should be synchronized with display in ../data/level1/level1.x3dv }
  IceDistanceMin = 2.5;
  IceDistanceMax = 10.0;
var
  Pos, Dir, Up, GravityUp: TVector3Single;
  Dist: Single;
  IcePosition, PlayerPositionXZ: TVector2Single;
  IceStrength, LifeLoss: Single;
begin
  ViewportPlayer.Camera.GetView(Pos, Dir, Up, GravityUp);
  Up := GravityUp; // make sure that avatar always stands straight on ground
  MakeVectorsOrthoOnTheirPlane(Dir, Up);
  Player3rdPerson.SetView(Pos, Dir, Up);

  PointLightOverPlayer.FdLocation.Send(Pos + Vector3Single(0, 2, 0));

  IcePosition := Worm.Position2D;
  IceStrength := Worm.Stationary;
  (IceEffect.Fields.ByName['ice_position'] as TSFVec2f).Send(IcePosition);
  (IceEffect.Fields.ByName['ice_strength'] as TSFFloat).Send(IceStrength);

  if not Player.Dead then
  begin
    if PlayerOverLava then
    begin
      { This follows algorithm how we calculate ice visualization in level1.x3dv shader }
      PlayerPositionXZ := Vector2Single(Player.Position[0], Player.Position[2]);
      Dist := PointsDistance(PlayerPositionXZ, IcePosition);
      Dist := SmoothStep(IceDistanceMin, IceDistanceMax, Dist);
      LifeLoss := 1.0 - Worm.Stationary * (1.0 - Dist);
      Player.Life := Player.Life - Window.Fps.UpdateSecondsPassed * LavaLifeLossSpeed * LifeLoss;
    end else
      LifeLoss := 0;

    if LifeLoss = 0 then
    begin
      Player.Life := Min(Player.MaxLife, { do not regenerate over MaxLife }
        Player.Life + Window.Fps.UpdateSecondsPassed * RegenerateLifeSpeed);
    end;
  end else
  begin
    { make sure to disallow MoveXxx when dead }
    Player3rdPerson.Exists := false;
    Player.Camera.MoveForward := false;
    Player.Camera.MoveBackward := false;
  end;
end;

procedure WindowRender(Container: TUIContainer);
begin
end;

procedure WindowResize(Container: TUIContainer);
const
  ViewportsMargin = 4;
var
  ViewportLeft, ViewportRight: TCastleAbstractViewport;
begin
  if RightHanded then
  begin
    ViewportRight := ViewportPlayer;
    ViewportLeft := ViewportWorm;
  end else
  begin
    ViewportLeft := ViewportPlayer;
    ViewportRight := ViewportWorm;
  end;

  ViewportLeft.FullSize := false;
  ViewportLeft.Width := Window.Width div 2 - ViewportsMargin;
  ViewportLeft.Height := Window.Height;
  ViewportLeft.Left := 0;
  ViewportLeft.Bottom := 0;

  ViewportRight.FullSize := false;
  ViewportRight.Width := Window.Width - Window.Width div 2 - ViewportsMargin;
  ViewportRight.Height := Window.Height;
  ViewportRight.Left := ViewportLeft.Width + ViewportsMargin;
  ViewportRight.Bottom := 0;

  WormIntroLabel.AlignHorizontal;
  { center horizontally within ViewportWorm }
  if RightHanded then
    WormIntroLabel.Left := WormIntroLabel.Left - Container.Width div 4 else
    WormIntroLabel.Left := WormIntroLabel.Left + Container.Width div 4;
  WormIntroLabel.AlignVertical;

  WormLifeLabel.AlignHorizontal;
  { center horizontally within ViewportWorm }
  if RightHanded then
    WormLifeLabel.Left := WormLifeLabel.Left - Container.Width div 4 else
    WormLifeLabel.Left := WormLifeLabel.Left + Container.Width div 4;
  WormLifeLabel.AlignVertical(prTop, prTop, -10);
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
  Window := TCastleWindowCustom.Create(Application);
  Window.OnOpen := @WindowOpen;
  Window.OnPress := @WindowPress;
  Window.OnRelease := @WindowRelease;
  Window.OnUpdate := @WindowUpdate;
  Window.OnRender := @WindowRender;
  Window.OnResize := @WindowResize;
  Window.FpsShowOnCaption := true;
  Application.MainWindow := Window;
end.
