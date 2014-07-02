# Extension of executable is determined by target operating system,
# that in turn depends on 1. -T options in CASTLE_FPC_OPTIONS and
# 2. current OS, if no -T inside CASTLE_FPC_OPTIONS. It's easiest to just
# use "fpc -iTO", to avoid having to detect OS (or parse CASTLE_FPC_OPTIONS)
# in the Makefile.
TARGET_OS = $(shell fpc -iTO $${CASTLE_FPC_OPTIONS:-})
EXE_EXTENSION = $(shell if '[' '(' $(TARGET_OS) '=' 'win32' ')' -o '(' $(TARGET_OS) '=' 'win64' ')' ']'; then echo '.exe'; else echo ''; fi)

FPC_OPTIONS := -dRELEASE
#FPC_OPTIONS := -dDEBUG

.PHONY: standalone
standalone:
	@echo 'Target OS detected: "'$(TARGET_OS)'"'
	@echo 'Target OS exe extension detected: "'$(EXE_EXTENSION)'"'
	@echo 'Using castle_game_engine in directory: ' $(CASTLE_ENGINE_PATH)
	fpc $(FPC_OPTIONS) $(shell $(CASTLE_ENGINE_PATH)castle_game_engine/scripts/castle_engine_fpc_options) code/mountains_of_fire.lpr
	mv code/mountains_of_fire$(EXE_EXTENSION) .

.PHONY: clean
clean:
	rm -Rf \
	       mountains_of_fire      mountains_of_fire.exe \
	  code/mountains_of_fire code/mountains_of_fire.exe \
	  code/libmountains_of_fire_android.so \
	  code/mountains_of_fire.compiled \
	  code/*.ppu code/build/
	find data/ -iname '*~' -exec rm -f '{}' ';'
	$(MAKE) -C $(CASTLE_ENGINE_PATH)castle_game_engine/ clean
#	$(MAKE) -C android/ clean

#FILES := --exclude *.xcf --exclude '*.blend*' README.txt --exclude seamless2d data/
# Hack since zip doesn't handle --exclude ?
FILES := README.txt data/
WINDOWS_FILES := $(FILES) mountains_of_fire.exe $(CASTLE_ENGINE_PATH)/www/pack/win32_dlls/*.dll
UNIX_FILES    := $(FILES) mountains_of_fire

.PHONY: clean-for-release
clean-for-release:
# Hack: remove not wanted stuff
	rm -Rf data/level1/lava_movie_output/output*.png \
	       data/level1/lava_movie_output/seamless2d/
	find '(' -iname '*.xcf' -or -iname '*.blend*' ')' -exec rm -f '{}' ';'

.PHONY: release-win32
release-win32: clean standalone clean-for-release
	rm -Rf mountains_of_fire-win32.zip
	zip -r mountains_of_fire-win32.zip $(WINDOWS_FILES)

.PHONY: release-linux
release-linux: clean standalone clean-for-release
	rm -Rf mountains_of_fire-linux-i386.tar.gz
	tar czvf mountains_of_fire-linux-i386.tar.gz $(UNIX_FILES)
