# Mountains Of Fire

Cooperative game where human and worm try to survive in deadly lava world. For single player or 2 players.

The game website is http://castle-engine.sourceforge.net/mountains_of_fire.php . You can also download it from itch.io: http://michaliskambi.itch.io/mountains-of-fire .

## Instructions how to play

There are 2 playable things: human and sandworm. Together, they try to reach a safe place within the mountains flooded with lava.

The game can be played by 2 players, or by a single player controlling both human and sandworm simultaneously. The controls were designed to be reachable by a single player.

- Human views the world in 1st person. It walks over the terrain.
  In right-handed mode, human view is the right one.

  Human is controlled only with mouse.
  Move mouse to look around.
  Click mouse left button to start/stop moving forward (no need to hold the button pressed),
  Click mouse right button to start/stop moving backward (no need to hold the button pressed).

  Human is hurt by hot lava.
  Stand on a neutral ground (rocks) to regenerate,
  or very close to the worm when it freezes the lava (on blueish fluid).

  When the human dies, game ends.

- Worm views the world from the top. It can swim in lava.
  In right-handed mode, worm view is the left one.

  Move the worm with AWSD.

  Worm freezes lava into a water that is not harmful for player.
  Worm is hurt when it stays stationary for too long, as the heat
  is too much even for a sandworm.
  You have to move the worm to regenerate.

  When the worm dies, human can still try to continue the game.

Hints:
- Worm is visible in both views, even when it's obscured by a wall etc.
  If you're lost, human can look around, and see where the worm is.
- There's no restart, just run the game again :)

Misc keys:
- F5 takes a screenshot.
- Escape exit.

## Command-line options:

- --left-handed
  Run the game swapping the split screen order. This is useful if the mouse
  is on the left of the keyboard, then you want the left screen part
  to show human view (as human is controlled by mouse).

- Window size and fullscreen options:
  http://castle-engine.sourceforge.net/opengl_options.php
  By default we start in fullscreen.

- Sound options, like --no-sound:
  http://castle-engine.sourceforge.net/openal.php#section_options

- --debug-log, --debug-speed

## Compiling:

- Download Castle Game Engine
  http://castle-engine.sourceforge.net/engine.php

- Set the environment variable $CASTLE_ENGINE_PATH to the directory that contains
  (as a child) castle_game_engine/ directory.

  Or make sure that compiled engine unis are in ~/.fpc.cfg,
  see https://sourceforge.net/p/castle-engine/wiki/Build%20tool/
  for more info about using the build tool.

- Compile by simple "make" in this directory.

## License

GNU GPL >= 2.

## Author

Michalis Kamburelis
