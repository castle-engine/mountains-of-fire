{
  Copyright 2014-2016 Michalis Kamburelis.

  This file is part of "Mountains Of Fire".

  "Mountains Of Fire" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Mountains Of Fire" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Worm logic. }
unit GameWorm;

interface

uses Classes,
  Castle3D, CastleCameras, CastleFrustum, CastleVectors, CastleScene,
  CastleSceneManager, CastleSoundEngine, CastleControls, CastleTimeUtils;

type
  TWorm = class(T3DOrient)
  private
    type
      TAnimationState = (asIdle, asVertical);
    var
    Anim: array [TAnimationState] of TCastleScene;
    AnimationTime: TFloatTime;
    FAnimationState: TAnimationState;
    FStationary: Single;
    CurrentMoveSound: TSound;
    MoveSounds: array [0..3] of TSoundType;
    TimeToStationaryLifeLoss: Single;
    function TargetCameraPosition: TVector3Single;
    procedure SetAnimationState(const Value: TAnimationState);
    property AnimationState: TAnimationState read FAnimationState write SetAnimationState;
    procedure CurrentMoveSoundRelease(Sender: TSound);
  public
    const
      DefaultAltitude = -1;
    var
    { Camera following worm. }
    FollowCamera: TUniversalCamera;
    Life, MaxLife: Single;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure FollowCameraUpdateNow;
    procedure Render(const Frustum: TFrustum; const Params: TRenderParams); override;
    // function Press(const Event: TInputPressRelease): boolean; override;
    // function Release(const Event: TInputPressRelease): boolean; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
    { How long is worm stationary. }
    property Stationary: Single read FStationary;
    function Position2D: TVector2Single;
    function Dead: boolean;
  end;

var
  Worm: TWorm;

  ViewportWorm: TCastleViewport;

  WormIntroLabel: TCastleLabel;
  WormLifeLabel: TCastleLabel;

implementation

uses Math,
  CastleFilesUtils, CastleRenderingCamera, CastleGLUtils, CastleKeysMouse,
  CastleUtils, CastleSceneCore, X3DNodes,
  Game3D, GameWindow, GamePlayer, GameHUD;

const
  NeutralPoseTolerance = 0.33; // in seconds
  AnimPlayingSpeed = 2;
  WormMoveSpeed = 2;
  CameraMoveSpeed = 1.75; //< should be < WormMoveSpeed to have camera visibly drag behind worm
  CameraMoveDirectionSpeed = 10.0;
  CameraAltitude = 15;
  StationaryRaiseSpeed = 0.5;
  StationaryFallSpeed = 2;
  RotationSpeed = 2; //< in degreees/sec
  DistanceToFinishTutorial = 6;
  StationaryLifeLossTime = 2.0;
  StationaryLifeLossSpeed = 5.0;
  RegenerateLifeSpeed = 2.0;
  RegainTimeToStationaryLifeLoss = 0.1;

constructor TWorm.Create(AOwner: TComponent);
begin
  inherited;

  Anim[asVertical] := TCastleScene.Create(Self);
  Anim[asVertical].Load(ApplicationData('worm/worm_vertical_move.kanim'));
  Anim[asVertical].ProcessEvents := true;
  Anim[asVertical].PlayAnimation('animation', paForceLooping);
  Anim[asVertical].TimePlayingSpeed := AnimPlayingSpeed;
  SetAttributes(Anim[asVertical].Attributes);
  Add(Anim[asVertical]);

  Anim[asIdle] := TCastleScene.Create(Self);
  Anim[asIdle].Load(ApplicationData('worm/worm_idle.kanim'));
  Anim[asIdle].ProcessEvents := true;
  Anim[asIdle].PlayAnimation('animation', paForceLooping);
  Anim[asIdle].TimePlayingSpeed := AnimPlayingSpeed;
  SetAttributes(Anim[asIdle].Attributes);
  Add(Anim[asIdle]);

  AnimationState := asIdle;

  MoveSounds[0] := SoundEngine.SoundFromName('worm_move_0');
  MoveSounds[1] := SoundEngine.SoundFromName('worm_move_1');
  MoveSounds[2] := SoundEngine.SoundFromName('worm_move_2');
  MoveSounds[3] := SoundEngine.SoundFromName('worm_move_3');

  Position := Vector3Single(6.1283283233642578, Worm.DefaultAltitude, 5.9467759132385254); // initial worm position

  MaxLife := 100;
  Life := MaxLife;
end;

destructor TWorm.Destroy;
begin
  if CurrentMoveSound <> nil then
    CurrentMoveSoundRelease(CurrentMoveSound);
  inherited;
end;

procedure TWorm.SetAnimationState(const Value: TAnimationState);
var
  AnimState: TAnimationState;
begin
  FAnimationState := Value;
  for AnimState in TAnimationState do
    Anim[AnimState].Exists := Value = AnimState;
end;

procedure TWorm.FollowCameraUpdateNow;
begin
  FollowCamera.SetView(
    { position } TargetCameraPosition,
//    { direction } Vector3Single(0.05, -1, 0.05),
    { direction } Vector3Single(0, -1, 0),
    { up } Vector3Single(0, 0, -1), false
  );
end;

procedure TWorm.Render(const Frustum: TFrustum; const Params: TRenderParams);
begin
  { use similar trick as TPLayer.RenderOnTop to render over the rest }
  if RenderingCamera.Target <> rtShadowMap then
    DepthRange := drNear;
  inherited;
  if RenderingCamera.Target <> rtShadowMap then
    DepthRange := drFar;
end;

// function TWorm.Press(const Event: TInputPressRelease): boolean;
// begin
//   Result := inherited;
//   if Result then Exit;
// end;

// function TWorm.Release(const Event: TInputPressRelease): boolean; override;
// begin
//   Result := inherited;
//   if Result then Exit;
// end;

function TWorm.TargetCameraPosition: TVector3Single;
begin
  Result := Worm.Position;
  Result[1] := CameraAltitude;
end;

procedure TWorm.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);

  function AnimationNeutralPose(const Anim: TCastleScene): boolean;
  begin
    Result := FloatModulo(AnimationTime, Anim.AnimationDuration('animation'))
      < NeutralPoseTolerance;
  end;

  procedure Move(const MoveForward: Single);
  begin
    if AnimationState = asIdle then
    begin
      if AnimationNeutralPose(Anim[asIdle]) then
      begin
        AnimationState := asVertical;
        AnimationTime := 0;
        Anim[asVertical].PlayAnimation('animation', paForceLooping);
      end else
        Exit; { abort movement, wait for idle anim finish }
    end;

    Position := Position + Direction * MoveForward * SecondsPassed * WormMoveSpeed;
  end;

  function MoveCloser(const Value, Destination: Single;
    const Speed: Single; const EpsilonDistanceToSleep: Single): Single;
  begin
    Assert(Speed >= 0);
    Result := Value;
    if Abs(Value - Destination) > EpsilonDistanceToSleep then
    begin
      if Value < Destination then
        Result := Min(Value + Speed * SecondsPassed, Destination) else
      if Value > Destination then
        Result := Max(Value - Speed * SecondsPassed, Destination);
    end;
  end;

  { Move Value closer to Destination, but do not overshoot. }
  function MoveCloser(const Vector, Destination: TVector3Single;
    const Speed: Single; const EpsilonDistanceToSleep: Single): TVector3Single;
  begin
    Result[0] := MoveCloser(Vector[0], Destination[0], Speed, EpsilonDistanceToSleep);
    Result[1] := MoveCloser(Vector[1], Destination[1], Speed, EpsilonDistanceToSleep);
    Result[2] := MoveCloser(Vector[2], Destination[2], Speed, EpsilonDistanceToSleep);
  end;

  procedure Rotate(const RotateRight: Single);
  begin
    Direction := RotatePointAroundAxisDeg(RotationSpeed * RotateRight,
      Direction, Vector3Single(0, -1, 0));
  end;

var
  PlayerPositionXZ: TVector2Single;
begin
  inherited;

  AnimationTime += SecondsPassed * AnimPlayingSpeed;

  if (not Player.Dead) and (not Dead) and
    { not before "tutorial" finished } ViewportWorm.Exists then
  begin
    if Window.Container.Pressed[K_A] then
      Rotate(-1);
    if Window.Container.Pressed[K_D] then
      Rotate(+1);
    if Window.Container.Pressed[K_W] then
      Move(+1);
    if Window.Container.Pressed[K_S] then
      Move(-1);
  end;

  FollowCamera.Walk.Position := MoveCloser(FollowCamera.Walk.Position, TargetCameraPosition, CameraMoveSpeed, 0.01);
  FollowCamera.Walk.Up := MoveCloser(FollowCamera.Walk.Up, Direction, CameraMoveDirectionSpeed, 0.01);

  case AnimationState of
    asVertical:
      if AnimationTime > Anim[asVertical].AnimationDuration('animation') then
      begin
        AnimationState := asIdle;
        AnimationTime := 0;
        Anim[asIdle].PlayAnimation('animation', paForceLooping);
      end;
  end;

  if AnimationState <> asIdle then
    FStationary := MoveCloser(FStationary, 0.0, StationaryFallSpeed, 0.0)
  else
    FStationary := MoveCloser(FStationary, 1.0, StationaryRaiseSpeed, 0.0);

  { run new move sound, if needed }
  if (AnimationState <> asIdle) and (CurrentMoveSound = nil) then
  begin
    CurrentMoveSound := SoundEngine.Sound(MoveSounds[Random(High(MoveSounds) + 1)], false);
    if CurrentMoveSound <> nil then
      CurrentMoveSound.OnRelease := @CurrentMoveSoundRelease;
  end;

  { update CurrentMoveSound.Position }
  if CurrentMoveSound <> nil then
    CurrentMoveSound.Position := Position;

  PlayerPositionXZ := Vector2Single(Player.Position[0], Player.Position[2]);
  if PointsDistance(PlayerPositionXZ, Position2D) <= DistanceToFinishTutorial then
  begin
    WormIntroLabel.Exists := false;
    ViewportWorm.Exists := true;
    WormHud.Exists := true;
  end;

  WormLifeLabel.Exists := false;
  if (not Player.Dead) and (not Dead) and { not before "tutorial" finished } ViewportWorm.Exists then
  begin
    if FStationary < 1 then
    begin
      TimeToStationaryLifeLoss := Min(StationaryLifeLossTime, TimeToStationaryLifeLoss + RegainTimeToStationaryLifeLoss * SecondsPassed); // reset timer if not completely stationary
      Life := Min(MaxLife, Life + RegenerateLifeSpeed * SecondsPassed);
    end else
    if TimeToStationaryLifeLoss <= 0 then
    begin
      Life -= StationaryLifeLossSpeed * SecondsPassed;
      WormLifeLabel.Exists := true;
    end else
      TimeToStationaryLifeLoss -= SecondsPassed
  end;
end;

procedure TWorm.CurrentMoveSoundRelease(Sender: TSound);
begin
  Assert(Sender = CurrentMoveSound);
  CurrentMoveSound.OnRelease := nil;
  CurrentMoveSound := nil;
end;

function TWorm.Position2D: TVector2Single;
begin
  Result := Vector2Single(Position[0], Position[2]);
end;

function TWorm.Dead: boolean;
begin
  Result := Life <= 0;
end;

end.
