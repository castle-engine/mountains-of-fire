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

{ Worm logic. }
unit GameWorm;

interface

uses Classes,
  CastleTransform, CastleCameras, CastleVectors, CastleScene, CastleBehaviors,
  CastleSceneManager, CastleSoundEngine, CastleControls, CastleTimeUtils;

type
  TWorm = class(TCastleTransform)
  private
    type
      TAnimationState = (asIdle, asVertical);
    var
    Anim: array [TAnimationState] of TCastleScene;
    AnimationTime: TFloatTime;
    FAnimationState: TAnimationState;
    FStationary: Single;
    SoundSource: TCastleSoundSource;
    CurrentMoveSound: TCastlePlayingSoundSource;
    MoveSounds: array [0..3] of TSoundType;
    TimeToStationaryLifeLoss: Single;
    function TargetCameraTranslation: TVector3;
    procedure SetAnimationState(const Value: TAnimationState);
    property AnimationState: TAnimationState read FAnimationState write SetAnimationState;
  public
    const
      DefaultAltitude = 0;
    var
    { Camera following worm. }
    FollowNav: TCastleWalkNavigation;
    Life, MaxLife: Single;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure FollowNavUpdateNow;
    procedure LocalRender(const RenderParams: TRenderParams); override;
    // function Press(const Event: TInputPressRelease): boolean; override;
    // function Release(const Event: TInputPressRelease): boolean; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
    { How long is worm stationary. }
    property Stationary: Single read FStationary;
    function Translation2D: TVector2;
    function Dead: boolean;
  end;

var
  Worm: TWorm;

  ViewportWorm: TCastleViewport;

  WormIntroLabel: TCastleLabel;
  WormLifeLabel: TCastleLabel;

implementation

uses Math,
  CastleFilesUtils, CastleGLUtils, CastleKeysMouse,
  CastleUtils, CastleSceneCore, X3DNodes, CastleRenderContext, CastleRenderOptions,
  GameWindow, GamePlayer, GameHUD;

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
  DistanceToFinishTutorial = 6; // hint for debugging: just increase it to finish tutorial immediately
  StationaryLifeLossTime = 2.0;
  StationaryLifeLossSpeed = 5.0;
  RegenerateLifeSpeed = 2.0;
  RegainTimeToStationaryLifeLoss = 0.1;

constructor TWorm.Create(AOwner: TComponent);
var
  // debug sphere
  //S: TCastleSphere;
  Light: TCastlePointLight;
begin
  inherited;

  Anim[asVertical] := TCastleScene.Create(Self);
  Anim[asVertical].Load('castle-data:/worm/worm_vertical_move.kanim');
  Anim[asVertical].ProcessEvents := true;
  Anim[asVertical].PlayAnimation('animation', true);
  Anim[asVertical].TimePlayingSpeed := AnimPlayingSpeed;
  Add(Anim[asVertical]);

  Anim[asIdle] := TCastleScene.Create(Self);
  Anim[asIdle].Load('castle-data:/worm/worm_idle.kanim');
  Anim[asIdle].ProcessEvents := true;
  Anim[asIdle].PlayAnimation('animation', true);
  Anim[asIdle].TimePlayingSpeed := AnimPlayingSpeed;
  Add(Anim[asIdle]);

  { Hacky way to make worm brighter.
    Non-hacky way would be to make new worm model, in Blender,
    using glTF morph targets instead of kanim. }
  Light := TCastlePointLight.Create(Self);
  Light.Translation := Vector3(0, 2, 0);
  Light.Radius := 2;
  Light.Intensity := 2;
  Add(Light);

  // S := TCastleSphere.Create(Self) { for debug };
  // S.Color := Vector4(1, 0, 0, 0.25);
  // //S.Material := pmUnlit;
  // S.Radius := 2;
  // Add(S);

  AnimationState := asIdle;

  MoveSounds[0] := SoundEngine.SoundFromName('worm_move_0');
  MoveSounds[1] := SoundEngine.SoundFromName('worm_move_1');
  MoveSounds[2] := SoundEngine.SoundFromName('worm_move_2');
  MoveSounds[3] := SoundEngine.SoundFromName('worm_move_3');

  Translation := Vector3(6.1283283233642578, Worm.DefaultAltitude, 5.9467759132385254); // initial worm Translation

  MaxLife := 100;
  Life := MaxLife;

  SoundSource := TCastleSoundSource.Create(Self);
  AddBehavior(SoundSource);
  CurrentMoveSound := TCastlePlayingSoundSource.Create(Self);
end;

destructor TWorm.Destroy;
begin
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

procedure TWorm.FollowNavUpdateNow;
begin
  FollowNav.Camera.SetView(
    { Translation } TargetCameraTranslation,
//    { direction } Vector3(0.05, -1, 0.05),
    { direction } Vector3(0, -1, 0),
    { up } Vector3(0, 0, -1), false
  );
end;

procedure TWorm.LocalRender(const RenderParams: TRenderParams);
begin
  { use similar trick as TPLayer.RenderOnTop to render over the rest }
  if RenderParams.RenderingCamera.Target <> rtShadowMap then
    RenderContext.DepthRange := drNear;
  inherited;
  if RenderParams.RenderingCamera.Target <> rtShadowMap then
    RenderContext.DepthRange := drFar;
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

function TWorm.TargetCameraTranslation: TVector3;
begin
  Result := Worm.Translation;
  Result.Y := CameraAltitude;
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
        Anim[asVertical].PlayAnimation('animation', true);
      end else
        Exit; { abort movement, wait for idle anim finish }
    end;

    Translation := Translation + Direction * MoveForward * SecondsPassed * WormMoveSpeed;
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
  function MoveCloser(const Vector, Destination: TVector3;
    const Speed: Single; const EpsilonDistanceToSleep: Single): TVector3;
  begin
    Result.X := MoveCloser(Vector.X, Destination.X, Speed, EpsilonDistanceToSleep);
    Result.Y := MoveCloser(Vector.Y, Destination.Y, Speed, EpsilonDistanceToSleep);
    Result.Z := MoveCloser(Vector.Z, Destination.Z, Speed, EpsilonDistanceToSleep);
  end;

  procedure Rotate(const RotateRight: Single);
  begin
    Direction := RotatePointAroundAxisDeg(RotationSpeed * RotateRight,
      Direction, Vector3(0, -1, 0));
  end;

var
  PlayerTranslationXZ: TVector2;
begin
  inherited;

  AnimationTime := AnimationTime + (SecondsPassed * AnimPlayingSpeed);

  if (not Player.Dead) and (not Dead) and
    { not before "tutorial" finished } ViewportWorm.Exists then
  begin
    if Window.Container.Pressed[keyA] then
      Rotate(-1);
    if Window.Container.Pressed[keyD] then
      Rotate(+1);
    if Window.Container.Pressed[keyW] then
      Move(+1);
    if Window.Container.Pressed[keyS] then
      Move(-1);
  end;

  FollowNav.Camera.Translation := MoveCloser(FollowNav.Camera.Translation, TargetCameraTranslation, CameraMoveSpeed, 0.01);
  FollowNav.Camera.Up       := MoveCloser(FollowNav.Camera.Up      , Direction           , CameraMoveDirectionSpeed, 0.01);

  case AnimationState of
    asVertical:
      if AnimationTime > Anim[asVertical].AnimationDuration('animation') then
      begin
        AnimationState := asIdle;
        AnimationTime := 0;
        Anim[asIdle].PlayAnimation('animation', true);
      end;
  end;

  if AnimationState <> asIdle then
    FStationary := MoveCloser(FStationary, 0.0, StationaryFallSpeed, 0.0)
  else
    FStationary := MoveCloser(FStationary, 1.0, StationaryRaiseSpeed, 0.0);

  { run new move sound, if needed }
  if (AnimationState <> asIdle) and (not CurrentMoveSound.Playing) then
  begin
    CurrentMoveSound.Sound := MoveSounds[Random(High(MoveSounds) + 1)];
    SoundSource.Play(CurrentMoveSound);
  end;

  PlayerTranslationXZ := Vector2(Player.Translation.X, Player.Translation.Z);
  if PointsDistance(PlayerTranslationXZ, Translation2D) <= DistanceToFinishTutorial then
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
      Life := Life - (StationaryLifeLossSpeed * SecondsPassed);
      WormLifeLabel.Exists := true;
    end else
      TimeToStationaryLifeLoss := TimeToStationaryLifeLoss - SecondsPassed
  end;
end;

function TWorm.Translation2D: TVector2;
begin
  Result := Vector2(Translation.X, Translation.Z);
end;

function TWorm.Dead: boolean;
begin
  Result := Life <= 0;
end;

end.
