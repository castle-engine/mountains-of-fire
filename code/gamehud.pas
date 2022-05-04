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

{ HUD. }
unit GameHUD;

interface

uses Classes,
  CastleUIControls, CastleRectangles, CastleVectors,
  GamePlayer;

type
  THud = class(TUIControl)
  public
    BarBackground: array [boolean] of TVector4;
    BarForeground: array [boolean] of TVector4;
    constructor Create(AOwner: TComponent); override;
    function BadlyHurt(const Life, MaxLife: Single): boolean;
  end;

  TPlayerHud = class(THud)
  public
    procedure Render; override;
  end;

  TWormHud = class(THud)
  public
    procedure Render; override;
  end;

var
  PlayerHud: TPlayerHud;
  WormHud: TWormHud;

implementation

uses CastleGLUtils, CastleColors, CastleUtils,
  GameWorm;

{ THud ----------------------------------------------------------------------- }

constructor THud.Create(AOwner: TComponent);
begin
  inherited;
  BarBackground[false] := Vector4(0.5, 1.0, 0.5, 0.2); // BadlyHurt = false => greenish
  BarBackground[true ] := Vector4(1.0, 0.5, 0.5, 0.2); // BadlyHurt = true  => reddish
  BarForeground[false] := Vector4(0, 1, 0, 0.9); // BadlyHurt = false => greenish
  BarForeground[true ] := Vector4(1, 0, 0, 0.9); // BadlyHurt = true  => reddish
end;

function THud.BadlyHurt(const Life, MaxLife: Single): boolean;
begin
  Result := Life < MaxLife / 2.0;
end;

{ TPlayerHud ----------------------------------------------------------------- }

procedure TPlayerHud.Render;
var
  R: TFloatRectangle;
  Badly: boolean;
begin
  inherited;

  if Player.Dead then
    GLFadeRectangleDark(ViewportPlayer.RenderRect, Red, 1.0)
  else
    GLFadeRectangleDark(ViewportPlayer.RenderRect, Player.FadeOutColor, Player.FadeOutIntensity);

  Badly := BadlyHurt(Player.Life, Player.MaxLife);
  R := RenderRect;
  DrawRectangle(R, BarBackground[Badly]);
  R := R.Grow(-2);
  if not Player.Dead then
  begin
    R.Width := Clamped(Round(
      MapRange(Player.Life, 0, Player.MaxLife, 0, R.Width)), 0, R.Width);
    DrawRectangle(R, BarForeground[Badly]);
  end;
end;

{ TWormHud ------------------------------------------------------------------- }

procedure TWormHud.Render;
var
  R: TFloatRectangle;
  NewWidth: Single;
  Badly: boolean;
begin
  inherited;

  if Worm.Dead then
    GLFadeRectangleDark(ViewportWorm.RenderRect, Red, 1.0);

  Badly := BadlyHurt(Worm.Life, Worm.MaxLife);
  R := RenderRect;
  DrawRectangle(R, BarBackground[Badly]);
  R := R.Grow(-2);
  if not Worm.Dead then
  begin
    NewWidth := Clamped(
      MapRange(Worm.Life, 0, Worm.MaxLife, 0, R.Width), 0, R.Width);
    R.Left := R.Left + (R.Width - NewWidth);
    R.Width := NewWidth;
    DrawRectangle(R, BarForeground[Badly]);
  end;
end;

end.
