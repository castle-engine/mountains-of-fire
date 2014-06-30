#!/bin/bash
set -eu

gimp -i -b '(load "process_textures.scm") (kam-batch-seamless2d)' -b '(gimp-quit 0)'
