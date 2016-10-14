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

{ General 3D stuff. }
unit Game3D;

interface

uses CastleRenderer;

procedure SetAttributes(const Attributes: TRenderingAttributes);

implementation

procedure SetAttributes(const Attributes: TRenderingAttributes);
begin
  Attributes.Shaders := srAlways;
end;

end.
