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
	fpc $(FPC_OPTIONS) $(shell $(CASTLE_ENGINE_PATH)castle_game_engine/tools/castle_engine_fpc_options) code/mountains_of_fire.lpr
	mv code/mountains_of_fire$(EXE_EXTENSION) .

.PHONY: clean
clean:
	castle-engine clean --verbose

.PHONY: release-win32
release-win32: clean standalone
	castle-engine package --os=win32 --cpu=i386

.PHONY: release-linux
release-linux: clean standalone
	castle-engine package --os=linux --cpu=i386
