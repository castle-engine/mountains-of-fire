{
  Copyright 2013-2016 Michalis Kamburelis.

  This file is part of "Darkest Before Dawn".

  "Darkest Before Dawn" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Darkest Before Dawn" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Level-specific logic. }
unit GameLevels;

interface

uses CastleLevels, CastleShapes, CastleBoxes, Castle3D;

type
  TLevel1 = class(TLevelLogic)
  strict private
  var
    GameWinBox: TBox3D;
  public
    function Placeholder(const Shape: TShape;
      const PlaceholderName: string): boolean; override;
    procedure Update(const SecondsPassed: Single; var RemoveMe: TRemoveType); override;
  end;

implementation

uses GamePlayer, GamePlay;

{ TLevel1 -------------------------------------------------------------------- }

procedure TLevel1.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
begin
  inherited;
  if Player = nil then Exit;

  if GameWinBox.PointInside(Player.Position) then
    GameWin := true;
end;

function TLevel1.Placeholder(const Shape: TShape;
  const PlaceholderName: string): boolean;
begin
  Result := inherited;
  if Result then Exit;

  if PlaceholderName = 'GameWin' then
  begin
    GameWinBox := Shape.BoundingBox;
    Exit(true);
  end;
end;

initialization
  { register our level logic classes }
  LevelLogicClasses['Level1'] := TLevel1;
end.
