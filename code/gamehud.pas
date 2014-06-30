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

{ HUD. }
unit GameHUD;

interface

uses Classes,
  CastleUIControls, CastleRectangles, CastleVectors,
  GamePlayer;

type
  THud = class(TUIRectangularControl)
  public
    BarBackground: array [boolean] of TVector4Single;
    BarForeground: array [boolean] of TVector4Single;
    constructor Create(AOwner: TComponent); override;
    function BadlyHurt(const Life, MaxLife: Single): boolean;
  end;

  TPlayerHud = class(THud)
  public
    function Rect: TRectangle; override;
    procedure Render; override;
  end;

  TWormHud = class(THud)
  public
    function Rect: TRectangle; override;
    procedure Render; override;
  end;

var
  PlayerHud: TPlayerHud;
  WormHud: TWormHud;

implementation

uses CastleGLUtils, CastleColors, CastleUtils,
  GameWorm;

const
  UIMargin = 10;
  LifeBarHeight = 40;

{ THud ----------------------------------------------------------------------- }

constructor THud.Create(AOwner: TComponent);
begin
  inherited;
  BarBackground[false] := Vector4Single(0.5, 1.0, 0.5, 0.2); // BadlyHurt = false => greenish
  BarBackground[true ] := Vector4Single(1.0, 0.5, 0.5, 0.2); // BadlyHurt = true  => reddish
  BarForeground[false] := Vector4Single(0, 1, 0, 0.9); // BadlyHurt = false => greenish
  BarForeground[true ] := Vector4Single(1, 0, 0, 0.9); // BadlyHurt = true  => reddish
end;

function THud.BadlyHurt(const Life, MaxLife: Single): boolean;
begin
  Result := Life < MaxLife / 2.0;
end;

{ TPlayerHud ----------------------------------------------------------------- }

function TPlayerHud.Rect: TRectangle;
begin
  { horizontal bar, good for both left and right-handed }
  Result := ViewportPlayer.Rect.Grow(-UIMargin);
  Result.Height := LifeBarHeight;
end;

procedure TPlayerHud.Render;
var
  R: TRectangle;
  Badly: boolean;
begin
  if Player.Dead then
    GLFadeRectangle(ViewportPlayer.Rect, Red, 1.0) else
    GLFadeRectangle(ViewportPlayer.Rect, Player.FadeOutColor, Player.FadeOutIntensity);

  Badly := BadlyHurt(Player.Life, Player.MaxLife);
  R := Rect;
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

function TWormHud.Rect: TRectangle;
begin
  { horizontal bar, good for both left and right-handed }
  Result := ViewportWorm.Rect.Grow(-UIMargin);
  Result.Height := LifeBarHeight;
end;

procedure TWormHud.Render;
var
  R: TRectangle;
  NewWidth: Integer;
  Badly: boolean;
begin
  if Worm.Dead then
    GLFadeRectangle(ViewportWorm.Rect, Red, 1.0);

  Badly := BadlyHurt(Worm.Life, Worm.MaxLife);
  R := Rect;
  DrawRectangle(R, BarBackground[Badly]);
  R := R.Grow(-2);
  if not Worm.Dead then
  begin
    NewWidth := Clamped(Round(
      MapRange(Worm.Life, 0, Worm.MaxLife, 0, R.Width)), 0, R.Width);
    R.Left += (R.Width - NewWidth);
    R.Width := NewWidth;
    DrawRectangle(R, BarForeground[Badly]);
  end;
end;

end.
