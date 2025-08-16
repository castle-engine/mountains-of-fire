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

{ Game playing.
  Practically, this is the only view of the game,
  only sometimes we push ViewEndButtons in front of this. }
unit GameViewPlay;

interface

uses CastleLevels, CastlePlayer, CastleCameras, CastleViewport,
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

type
  { View that represents the game. }
  TViewPlay = class(TCastleView)
  public
    procedure GameBegin;
    procedure Start; override;
    function Press(const Event: TInputPressRelease): boolean; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: boolean); override;
    procedure Resize; override;
  end;

var
  ViewPlay: TViewPlay;

implementation

uses SysUtils, Math,
  CastleResources,
  CastleWindow, CastleVectors, CastleTransform,
  CastleRenderOptions, CastleMaterialProperties, CastleFilesUtils,
  CastleUtils, CastleSoundEngine, CastleControls, CastleLog,
  CastleImages, CastleColors,
  X3DNodes, X3DFields, CastleShapes, X3DCameraUtils,
  GameWorm, GamePlayer3rdPerson, GameHUD, GamePlayer,
  GameViewEndButtons;

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
  { Player3rdPerson is visible only in ViewportWorm }
  SavedExists := Player3rdPerson.Exists;
  Player3rdPerson.Exists := false;
  inherited;
  Player3rdPerson.Exists := SavedExists;
end;

procedure TViewPlay.Start;
var
  Background: TCastleSimpleBackground;
begin
  inherited;

  Background := TCastleSimpleBackground.Create(FreeAtStop);
  Background.Color := Vector4(0.1, 0, 0, 1);
  InsertBack(Background);

  GameBegin;
end;

procedure TViewPlay.GameBegin;

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
  end;

const
  UIMargin = 10;
  LifeBarHeight = 40;
begin
  GameEnd;

  SceneManager := TMySceneManager.Create(FreeAtStop);
  InsertFront(SceneManager);

  Player := TPlayer.Create(FreeAtStop);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  Player.WalkNavigation.MouseLook := true;

  // SceneManager.UseGlobalLights := true;

  ViewportPlayer := SceneManager;
  Container.ForceCaptureInput := ViewportPlayer;

  ViewportWorm := TCastleViewport.Create(FreeAtStop);
  ViewportWorm.Items.Remove(ViewportWorm.Camera);
  ViewportWorm.Items := SceneManager.Items;
  // Add ViewportWorm.Camera to proper world, see https://castle-engine.io/multiple_viewports_to_display_one_world
  ViewportWorm.Items.Add(ViewportWorm.Camera);
  InsertFront(ViewportWorm);

  PlayerHud := TPlayerHud.Create(FreeAtStop);
  PlayerHud.WidthFraction := 0.9;
  PlayerHud.Height := LifeBarHeight;
  PlayerHud.Anchor(hpMiddle);
  PlayerHud.Anchor(vpBottom, UIMargin);
  ViewportPlayer.InsertFront(PlayerHud);

  WormHud := TWormHud.Create(FreeAtStop);
  WormHud.WidthFraction := 0.9;
  WormHud.Height := LifeBarHeight;
  WormHud.Anchor(hpMiddle);
  WormHud.Anchor(vpBottom, UIMargin);
  ViewportWorm.InsertFront(WormHud);

  WormIntroLabel := TCastleLabel.Create(FreeAtStop);
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
  InsertFront(WormIntroLabel);

  WormLifeLabel := TCastleLabel.Create(FreeAtStop);
  WormLifeLabel.Text.Text :=
    'Move the sandworm or it will die soon.' +LineEnding+
    LineEnding+
    'Move the sandworm using W/S keys.' +LineEnding+
    'Rotate the sandworm using A/D keys.';
  WormLifeLabel.Frame := false;
  WormLifeLabel.Color := Yellow;
  WormLifeLabel.Exists := false;
  InsertFront(WormLifeLabel);

  { OpenGL context required from now on }

  Worm := TWorm.Create(FreeAtStop);

  Player3rdPerson := TPlayer3rdPerson.Create(FreeAtStop);

  Worm.FollowNav := TCastleWalkNavigation.Create(FreeAtStop);
  Worm.FollowNav.Gravity := false;
  //Worm.FollowNav.GoToInitial; // TODO -- need to do anything?
  Worm.FollowNav.Input := [];
  Worm.FollowNav.Radius := 0.1; // allow near projection plane (calculated based on this radius) be larger

  ViewportWorm.Navigation :=  Worm.FollowNav;
  // ViewportWorm.InsertBack(Worm.FollowNav); // in new-cameras branch, use this
  Worm.FollowNavUpdateNow;

  SceneManager.LoadLevel('mountains');

  if DebugSpeed then
    Player.WalkNavigation.MoveSpeed := 10;

  PointLightOverPlayer := SceneManager.Items.MainScene.RootNode.FindNodeByName(
    TPointLightNode, 'PointLightOverPlayer', false) as TPointLightNode;

  IcePositionField := SceneManager.Items.MainScene.Field('IceEffect', 'ice_position') as TSFVec2f;
  IceStrengthField := SceneManager.Items.MainScene.Field('IceEffect', 'ice_strength') as TSFFloat;

  SceneManager.Items.Add(Worm);
  SceneManager.Items.Add(Player3rdPerson);

  ViewportWorm.Exists := false;
  WormHud.Exists := false;
  WormIntroLabel.Exists := true;
end;

function TViewPlay.Press(const Event: TInputPressRelease): Boolean;
{ $define DEBUG_KEYS}
{$ifdef DEBUG_KEYS}
var
  Pos, Dir, Up, GravityUp: TVector3;
{$endif}
begin
  Result := inherited;
  if Result then Exit;

  {$ifdef DEBUG_KEYS}
  if Event.IsKey(keyF2) then
  begin
    { debug examine view }
    SceneManager.NavigationType := ntExamine;
  end;

  if Event.IsKey(keyF3) then
  begin
    InitializeLog;
    Player.WalkNavigation.GetView(Pos, Dir, Up, GravityUp);
    WritelnLog('Camera', MakeCameraStr(cvVrml2_X3d, false, Pos, Dir, Up, GravityUp));
  end;
  {$endif}

  if Event.IsKey(keyF5) then
    Container.SaveScreen(FileNameAutoInc(ApplicationName + '_screen_%d.png'));
  if Event.IsKey(keyEscape) then
    Application.MainWindow.Close;

  if Event.IsMouseButton(buttonLeft) and not Player.Dead then
  begin
    Player.WalkNavigation.MoveForward := not Player.WalkNavigation.MoveForward;
    { make sure only one MoveXxx is true, otherwise it's confusing what is going on }
    if Player.WalkNavigation.MoveForward then
      Player.WalkNavigation.MoveBackward := false;
  end;
  if Event.IsMouseButton(buttonRight) and not Player.Dead then
  begin
    Player.WalkNavigation.MoveBackward := not Player.WalkNavigation.MoveBackward;
    if Player.WalkNavigation.MoveBackward then
      Player.WalkNavigation.MoveForward := false;
  end;
end;

procedure TViewPlay.Update(const SecondsPassed: Single; var HandleInput: Boolean);

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
      Collision := SceneManager.Items.WorldRay(Player.Translation, -SceneManager.Camera.GravityUp);
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
  inherited;

  ViewportPlayer.Camera.GetView(Pos, Dir, Up);
  GravityUp := ViewportPlayer.Camera.GravityUp;
  Up := GravityUp; // make sure that avatar always stands straight on ground
  MakeVectorsOrthoOnTheirPlane(Dir, Up);
  Player3rdPerson.SetView(Pos, Dir, Up);

  PointLightOverPlayer.FdLocation.Send(Pos + Vector3(0, 2, 0));

  IcePosition := Worm.Translation2D;
  IceStrength := Worm.Stationary;
  IcePositionField.Send(IcePosition);
  IceStrengthField.Send(IceStrength);

  if not Player.Dead then
  begin
    if PlayerOverLava then
    begin
      { This follows algorithm how we calculate ice visualization in level1.x3dv shader }
      PlayerPositionXZ := Vector2(Player.Translation.X, Player.Translation.Z);
      Dist := PointsDistance(PlayerPositionXZ, IcePosition);
      Dist := SmoothStep(IceDistanceMin, IceDistanceMax, Dist);
      LifeLoss := 1.0 - Worm.Stationary * (1.0 - Dist);
      Player.Life := Player.Life - SecondsPassed * LavaLifeLossSpeed * LifeLoss;
    end else
      LifeLoss := 0;

    if LifeLoss = 0 then
    begin
      Player.Life := Min(Player.MaxLife, { do not regenerate over MaxLife }
        Player.Life + SecondsPassed * RegenerateLifeSpeed);
    end;
  end else
  begin
    { make sure to disallow MoveXxx when dead }
    Player3rdPerson.Exists := false;
    Player.WalkNavigation.MoveForward := false;
    Player.WalkNavigation.MoveBackward := false;
  end;

  GameEndButtons := GameWin or Player.Dead;
  if GameEndButtons then
    Player.WalkNavigation.MouseLook := false;
  if GameEndButtons and (Container.FrontView <> ViewEndButtons) then
    Container.PushView(ViewEndButtons);
  if (not GameEndButtons) and (Container.FrontView = ViewEndButtons) then
    Container.PopView(ViewEndButtons);
end;

procedure TViewPlay.Resize;
const
  ViewportsMargin = 4;
var
  ViewportLeft, ViewportRight: TCastleViewport;
begin
  inherited;

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
  ViewportLeft.Width := Container.Width div 2 - ViewportsMargin;
  ViewportLeft.Height := Container.Height;
  ViewportLeft.Left := 0;
  ViewportLeft.Bottom := 0;

  ViewportRight.FullSize := false;
  ViewportRight.Width := Container.Width - Container.Width div 2 - ViewportsMargin;
  ViewportRight.Height := Container.Height;
  ViewportRight.Left := ViewportLeft.Width + ViewportsMargin;
  ViewportRight.Bottom := 0;

  WormIntroLabel.MaxWidth := ViewportWorm.Width;
  WormIntroLabel.Align(hpMiddle, hpMiddle);
  { center horizontally within ViewportWorm }
  if RightHanded then
    WormIntroLabel.Left := WormIntroLabel.Left - Container.PixelsWidth div 4 else
    WormIntroLabel.Left := WormIntroLabel.Left + Container.PixelsWidth div 4;
  WormIntroLabel.Align(vpMiddle, vpMiddle);

  WormLifeLabel.Align(hpMiddle, hpMiddle);
  { center horizontally within ViewportWorm }
  if RightHanded then
    WormLifeLabel.Left := WormLifeLabel.Left - Container.PixelsWidth div 4 else
    WormLifeLabel.Left := WormLifeLabel.Left + Container.PixelsWidth div 4;
  WormLifeLabel.Align(vpTop, vpTop, -10);
end;

end.
