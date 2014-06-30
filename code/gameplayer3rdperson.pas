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

{ Player in 3rd person display. }
unit GamePlayer3rdPerson;

interface

uses Classes,
  Castle3D, CastleCameras, CastlePrecalculatedAnimation, CastleFrustum, CastleVectors;

type
  TPlayer3rdPerson = class(T3DOrient)
  private
    type
      TAnimationState = (asIdle, {asWalk, }asRun);
    var
    Anim: array [TAnimationState] of TCastlePrecalculatedAnimation;
    FAnimationState: TAnimationState;
    procedure SetAnimationState(const Value: TAnimationState);
    property AnimationState: TAnimationState read FAnimationState write SetAnimationState;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Render(const Frustum: TFrustum; const Params: TRenderParams); override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

var
  Player3rdPerson: TPlayer3rdPerson;

implementation

uses Math,
  CastleFilesUtils, CastleRenderingCamera, CastleGLUtils, CastleKeysMouse, CastleUtils,
  CastlePlayer,
  Game3D, GameWindow, GamePlayer;

const
  AnimPlayingSpeed = 1.0;

constructor TPlayer3rdPerson.Create(AOwner: TComponent);
begin
  inherited;

  Anim[asIdle] := TCastlePrecalculatedAnimation.Create(Self);
  Anim[asIdle].LoadFromFile(ApplicationData('player/idle.kanim'), false, false, 1);
  Anim[asIdle].TimeLoop := true;
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

  Anim[asRun] := TCastlePrecalculatedAnimation.Create(Self);
  Anim[asRun].LoadFromFile(ApplicationData('player/run.kanim'), false, false, 1);
  Anim[asRun].TimeLoop := true;
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

procedure TPlayer3rdPerson.Render(const Frustum: TFrustum; const Params: TRenderParams);
begin
  inherited;
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
