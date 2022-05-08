{
  Copyright 2014-2022 Michalis Kamburelis.

  This file is part of "Mountains Of Fire".

  "Mountains Of Fire" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Mountains Of Fire" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Game playing (as opposed to game options screen, that may be added in the future). }
unit GamePlay;

interface

uses CastleLevels, CastlePlayer, CastleCameras, CastleSceneManager,
  CastleUIControls, CastleKeysMouse;

type
  TMySceneManager = class(TGameSceneManager)
    procedure Render; override;
  end;

var
  SceneManager: TMySceneManager;

  RightHanded: boolean = true;
  DebugSpeed: boolean = false;

  GameWin: boolean = false;

procedure GameBegin;

procedure GamePress(Container: TUIContainer; const Event: TInputPressRelease);
procedure GameUpdate(Container: TUIContainer);
procedure GameResize(Container: TUIContainer);

implementation

uses SysUtils, Math,
  CastleProgress, CastleWindowProgress, CastleResources,
  CastleWindow, CastleVectors, CastleTransform,
  CastleRenderer, CastleMaterialProperties, CastleFilesUtils,
  CastleUtils, CastleSoundEngine, CastleControls, CastleLog,
  CastleImages, CastleColors,
  X3DNodes, X3DFields, CastleShapes, X3DCameraUtils,
  Game3D, GameWorm, GamePlayer3rdPerson, GameWindow, GameHUD, GamePlayer,
  GameButtons;

const
  LavaLifeLossSpeed = 5.0;
  RegenerateLifeSpeed = 5.0;

var
  PointLightOverPlayer: TPointLightNode;
  IcePositionField: TSFVec2f;
  IceStrengthField: TSFFloat;

procedure TMySceneManager.Render;
var
  SavedExists: Boolean;
begin
  { Player3rdPerson is visible only in WormViewport }
  SavedExists := Player3rdPerson.Exists;
  Player3rdPerson.Exists := false;
  inherited;
  Player3rdPerson.Exists := SavedExists;
end;

procedure GameBegin;

  { Make sure to free and clear all stuff started during the game. }
  procedure GameEnd;
  begin
    { free 3D stuff (inside SceneManager) }
    FreeAndNil(Player);
    FreeAndNil(Player3rdPerson);
    FreeAndNil(Worm);

    { free 2D stuff (including SceneManager and viewports) }
    FreeAndNil(SceneManager);
    ViewportPlayer := nil; // this is equal to SceneManager, so already freed
    FreeAndNil(ViewportWorm);
    FreeAndNil(PlayerHud);
    FreeAndNil(WormHud);
    FreeAndNil(WormIntroLabel);
    FreeAndNil(WormLifeLabel);

    PointLightOverPlayer := nil; // already freed when freeing SceneManager
    IcePositionField := nil; // already freed when freeing SceneManager
    IceStrengthField := nil;
    GameWin := false;

    ButtonsRemove;
  end;

const
  UIMargin = 10;
  LifeBarHeight = 40;
begin
  GameEnd;

  SceneManager := TMySceneManager.Create(Window);
  Window.Controls.InsertFront(SceneManager);

  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  Player.Camera.MouseLook := true;

  // SceneManager.UseGlobalLights := true;

  ViewportPlayer := SceneManager;
  Window.Container.ForceCaptureInput := ViewportPlayer;

  ViewportWorm := TCastleViewport.Create(Application);
  ViewportWorm.SceneManager := SceneManager;
  Window.Controls.InsertFront(ViewportWorm);

  PlayerHud := TPlayerHud.Create(Window);
  PlayerHud.WidthFraction := 0.9;
  PlayerHud.Height := LifeBarHeight;
  PlayerHud.Anchor(hpMiddle);
  PlayerHud.Anchor(vpBottom, UIMargin);
  ViewportPlayer.InsertFront(PlayerHud);

  WormHud := TWormHud.Create(Window);
  WormHud.WidthFraction := 0.9;
  WormHud.Height := LifeBarHeight;
  WormHud.Anchor(hpMiddle);
  WormHud.Anchor(vpBottom, UIMargin);
  ViewportWorm.InsertFront(WormHud);

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

  { OpenGL context required from now on }

  Progress.Init(1, 'Loading worm');
  Worm := TWorm.Create(Window);
  Progress.Step;
  Progress.Fini;

  Progress.Init(1, 'Loading player');
  Player3rdPerson := TPlayer3rdPerson.Create(Window);
  Progress.Step;
  Progress.Fini;

  Worm.FollowNav := TCastleWalkNavigation.Create(Window);
  Worm.FollowNav.Gravity := false;
  //Worm.FollowNav.GoToInitial; // TODO -- need to do anything?
  Worm.FollowNav.Input := [];
  Worm.FollowNav.Radius := 0.1; // allow near projection plane (calculated based on this radius) be larger

  ViewportWorm.InsertBack(Worm.FollowNav);
  Worm.FollowNavUpdateNow;

  SceneManager.LoadLevel('mountains');
  SetAttributes(SceneManager.MainScene.Attributes);

  if DebugSpeed then
    Player.Camera.MoveSpeed := 10;

  PointLightOverPlayer := SceneManager.MainScene.RootNode.FindNodeByName(
    TPointLightNode, 'PointLightOverPlayer', false) as TPointLightNode;

  IcePositionField := SceneManager.MainScene.Field('IceEffect', 'ice_position') as TSFVec2f;
  IceStrengthField := SceneManager.MainScene.Field('IceEffect', 'ice_strength') as TSFFloat;

  SceneManager.Items.Add(Worm);
  SceneManager.Items.Add(Player3rdPerson);

  ViewportWorm.Exists := false;
  WormHud.Exists := false;
  WormIntroLabel.Exists := true;

  ButtonsAdd;

  { initial resize to set size of everything }
  GameResize(Window.Container);
end;

procedure GamePress(Container: TUIContainer; const Event: TInputPressRelease);
{ $define DEBUG_KEYS}
{$ifdef DEBUG_KEYS}
var
  Pos, Dir, Up, GravityUp: TVector3;
{$endif}
begin
  {$ifdef DEBUG_KEYS}
  if Event.IsKey(K_F2) then
  begin
    { debug examine view }
    SceneManager.NavigationType := ntExamine;
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

procedure GameUpdate(Container: TUIContainer);

  function PlayerOverLava: boolean;
  var
    Collision: TRayCollision;
    SavedPlayerExists, SavedPlayer3rdPersonExists: Boolean;
  begin
    SavedPlayerExists := Player.Exists;
    SavedPlayer3rdPersonExists := Player3rdPerson.Exists;
    Player.Exists := false;
    Player3rdPerson.Exists := false;
    try
      Collision := SceneManager.Items.WorldRay(Player.Position, -SceneManager.GravityUp);
      Result :=
        (Collision <> nil) and
        (Collision.First.Triangle <> nil) and
        (Collision.First.Triangle^.Shape <> nil) and
        (Collision.First.Triangle^.Shape.Node <> nil) and
        (Collision.First.Triangle^.Shape.Node.X3DName = 'LavaShape');
      FreeAndNil(Collision);
    finally
      Player.Exists := SavedPlayerExists;
      Player3rdPerson.Exists := SavedPlayer3rdPersonExists;
    end;
  end;

const
  { How far ice works. Should be synchronized with display in ../data/level1/level1.x3dv }
  IceDistanceMin = 2.5;
  IceDistanceMax = 10.0;
var
  Pos, Dir, Up, GravityUp: TVector3;
  Dist: Single;
  IcePosition, PlayerPositionXZ: TVector2;
  IceStrength, LifeLoss: Single;
  GameEndButtons: boolean;
begin
  ViewportPlayer.Camera.GetView(Pos, Dir, Up);
  GravityUp := ViewportPlayer.Camera.GravityUp;
  Up := GravityUp; // make sure that avatar always stands straight on ground
  MakeVectorsOrthoOnTheirPlane(Dir, Up);
  Player3rdPerson.SetView(Pos, Dir, Up);

  PointLightOverPlayer.FdLocation.Send(Pos + Vector3(0, 2, 0));

  IcePosition := Worm.Position2D;
  IceStrength := Worm.Stationary;
  IcePositionField.Send(IcePosition);
  IceStrengthField.Send(IceStrength);

  if not Player.Dead then
  begin
    if PlayerOverLava then
    begin
      { This follows algorithm how we calculate ice visualization in level1.x3dv shader }
      PlayerPositionXZ := Vector2(Player.Position[0], Player.Position[2]);
      Dist := PointsDistance(PlayerPositionXZ, IcePosition);
      Dist := SmoothStep(IceDistanceMin, IceDistanceMax, Dist);
      LifeLoss := 1.0 - Worm.Stationary * (1.0 - Dist);
      Player.Life := Player.Life - Window.Fps.SecondsPassed * LavaLifeLossSpeed * LifeLoss;
    end else
      LifeLoss := 0;

    if LifeLoss = 0 then
    begin
      Player.Life := Min(Player.MaxLife, { do not regenerate over MaxLife }
        Player.Life + Window.Fps.SecondsPassed * RegenerateLifeSpeed);
    end;
  end else
  begin
    { make sure to disallow MoveXxx when dead }
    Player3rdPerson.Exists := false;
    Player.Camera.MoveForward := false;
    Player.Camera.MoveBackward := false;
  end;

  GameEndButtons := GameWin or Player.Dead;
  if GameEndButtons then
    Player.Camera.MouseLook := false;
  RestartButton.Exists := GameEndButtons;
  QuitButton.Exists := GameEndButtons;
end;

procedure GameResize(Container: TUIContainer);
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

  WormIntroLabel.MaxWidth := ViewportWorm.Width;
  WormIntroLabel.Align(hpMiddle, hpMiddle);
  { center horizontally within ViewportWorm }
  if RightHanded then
    WormIntroLabel.Left := WormIntroLabel.Left - Container.Width div 4 else
    WormIntroLabel.Left := WormIntroLabel.Left + Container.Width div 4;
  WormIntroLabel.Align(vpMiddle, vpMiddle);

  WormLifeLabel.Align(hpMiddle, hpMiddle);
  { center horizontally within ViewportWorm }
  if RightHanded then
    WormLifeLabel.Left := WormLifeLabel.Left - Container.Width div 4 else
    WormLifeLabel.Left := WormLifeLabel.Left + Container.Width div 4;
  WormLifeLabel.Align(vpTop, vpTop, -10);

  ButtonsResize;
end;

end.
