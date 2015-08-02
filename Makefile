# This Makefile uses "castle-engine" build tool for most operations
# (like compilation).
# See https://sourceforge.net/p/castle-engine/wiki/Build%20tool/
# for instructions how to install/use this build tool.

.PHONY: standalone
standalone:
	castle-engine compile $(CASTLE_ENGINE_TOOL_OPTIONS)

.PHONY: clean
clean:
	castle-engine clean

.PHONY: release-win32
release-win32:
	castle-engine package --os=win32 --cpu=i386

.PHONY: release-linux
release-linux:
	castle-engine package --os=linux --cpu=i386

.PHONY: release-linux-64
release-linux-64:
	castle-engine package --os=linux --cpu=x86_64

.PHONY: release-src
release-src:
	castle-engine package-source
