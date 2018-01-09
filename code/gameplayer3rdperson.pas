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

{ Player in 3rd person display. }
unit GamePlayer3rdPerson;

interface

uses Classes,
  CastleTransform, CastleCameras, CastleVectors, CastleScene;

type
  TPlayer3rdPerson = class(TCastleTransform)
  private
    type
      TAnimationState = (asIdle, {asWalk, }asRun);
    var
    Anim: array [TAnimationState] of TCastleScene;
    FAnimationState: TAnimationState;
    procedure SetAnimationState(const Value: TAnimationState);
    property AnimationState: TAnimationState read FAnimationState write SetAnimationState;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

var
  Player3rdPerson: TPlayer3rdPerson;

implementation

uses Math,
  CastleFilesUtils, CastleRenderingCamera, CastleGLUtils, CastleKeysMouse,
  CastleUtils, CastlePlayer, CastleSceneCore,
  Game3D, GameWindow, GamePlayer;

const
  AnimPlayingSpeed = 1.0;

constructor TPlayer3rdPerson.Create(AOwner: TComponent);
begin
  inherited;

  Anim[asIdle] := TCastleScene.Create(Self);
  Anim[asIdle].Load(ApplicationData('player/idle.kanim'));
  Anim[asIdle].ProcessEvents := true;
  Anim[asIdle].PlayAnimation('animation', paForceLooping);
  Anim[asIdle].TimePlayingSpeed := AnimPlayingSpeed;
  SetAttributes(Anim[asIdle].Attributes);
  Add(Anim[asIdle]);

{
  Anim[asWalk] := TCastlePrecalculatedAnimation.Create(Self);
  Anim[asWalk].LoadFromFile(ApplicationData('player/walk.kanim'), false, false, 1);
  Anim[asWalk].TimeLoop := true;
  Anim[asWalk].TimePlayingSpeed := AnimPlayingSpeed;
  SetAttributes(Anim[asWalk].Attributes);
  Add(Anim[asWalk]);
}

  Anim[asRun] := TCastleScene.Create(Self);
  Anim[asRun].Load(ApplicationData('player/run.kanim'));
  Anim[asRun].ProcessEvents := true;
  Anim[asRun].PlayAnimation('animation', paForceLooping);
  Anim[asRun].TimePlayingSpeed := AnimPlayingSpeed;
  SetAttributes(Anim[asRun].Attributes);
  Add(Anim[asRun]);

  AnimationState := asIdle;

  Collides := false;
end;

procedure TPlayer3rdPerson.SetAnimationState(const Value: TAnimationState);
var
  AnimState: TAnimationState;
begin
  FAnimationState := Value;
  for AnimState in TAnimationState do
    Anim[AnimState].Exists := Value = AnimState;
end;

procedure TPlayer3rdPerson.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
begin
  inherited;
  if PlayerInput_Forward.IsPressed(Window.Container) or
     PlayerInput_Backward.IsPressed(Window.Container) or
     Player.Camera.MoveForward or
     Player.Camera.MoveBackward then
    AnimationState := asRun else
    AnimationState := asIdle;
end;

end.
