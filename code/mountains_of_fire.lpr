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

{$apptype GUI}

{ "Mountains Of Fire" standalone game binary. }
program mountains_of_fire;

{$ifdef MSWINDOWS}
  {$R ../automatic-windows-resources.res}
{$endif MSWINDOWS}

uses CastleWindow, CastleConfig, CastleParameters, CastleLog, CastleUtils,
  CastleSoundEngine, CastleClassUtils,
  Game, GamePlay, GameWindow;

const
  Version = '1.1.0';
  Options: array [0..3] of TOption =
  (
    (Short:  #0; Long: 'debug-log'; Argument: oaNone),
    (Short:  #0; Long: 'left-handed'; Argument: oaNone),
    (Short:  #0; Long: 'debug-speed'; Argument: oaNone),
    (Short: 'v'; Long: 'version'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0: InitializeLog;
    1: RightHanded := false;
    2: DebugSpeed := true;
    3: begin
         WritelnStr(Version);
         Halt;
       end;
    else raise EInternalError.Create('OptionProc');
  end;
end;

begin
  UserConfig.Load;
  SoundEngine.LoadFromConfig(UserConfig); // before SoundEngine.ParseParameters

  SoundEngine.ParseParameters;
  Window.FullScreen := true;
  Window.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  Window.OpenAndRun;
  UserConfig.Save;
end.
