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

{$apptype GUI}

{ "Mountains Of Fire" standalone game binary. }
program mountains_of_fire;
uses CastleWindow, CastleConfig, CastleParameters, CastleLog, CastleUtils,
  CastleSoundEngine,
  Game, GameWindow;

const
  Options: array [0..2] of TOption =
  (
    (Short:  #0; Long: 'debug-log'; Argument: oaNone),
    (Short:  #0; Long: 'left-handed'; Argument: oaNone),
    (Short:  #0; Long: 'debug-speed'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0: InitializeLog;
    1: RightHanded := false;
    2: DebugSpeed := true;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  Config.Load;

  SoundEngine.ParseParameters; { after Config.Load, to be able to turn off sound }
  Window.FullScreen := true;
  Window.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  Application.Initialize;
  Window.OpenAndRun;
  Config.Save;
end.
