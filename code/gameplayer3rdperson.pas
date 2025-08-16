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
  CastleFilesUtils, CastleGLUtils, CastleKeysMouse,
  CastleUtils, CastlePlayer, CastleSceneCore, CastleWindow,
  GamePlayer;

const
  AnimPlayingSpeed = 1.0;

constructor TPlayer3rdPerson.Create(AOwner: TComponent);
begin
  inherited;

  Anim[asIdle] := TCastleScene.Create(Self);
  Anim[asIdle].Load('castle-data:/player/idle.kanim');
  Anim[asIdle].ProcessEvents := true;
  Anim[asIdle].PlayAnimation('animation', true);
  Anim[asIdle].TimePlayingSpeed := AnimPlayingSpeed;
  Add(Anim[asIdle]);

{
  Anim[asWalk] := TCastlePrecalculatedAnimation.Create(Self);
  Anim[asWalk].LoadFromFile('castle-data:/player/walk.kanim', false, false, 1);
  Anim[asWalk].TimeLoop := true;
  Anim[asWalk].TimePlayingSpeed := AnimPlayingSpeed;
  Add(Anim[asWalk]);
}

  Anim[asRun] := TCastleScene.Create(Self);
  Anim[asRun].Load('castle-data:/player/run.kanim');
  Anim[asRun].ProcessEvents := true;
  Anim[asRun].PlayAnimation('animation', true);
  Anim[asRun].TimePlayingSpeed := AnimPlayingSpeed;
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
  if PlayerInput_Forward.IsPressed(Application.MainWindow.Container) or
     PlayerInput_Backward.IsPressed(Application.MainWindow.Container) or
     Player.WalkNavigation.MoveForward or
     Player.WalkNavigation.MoveBackward then
    AnimationState := asRun else
    AnimationState := asIdle;
end;

end.
