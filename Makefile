
EXE := grthrexe

BUILD_DIR := ./build
SRC_DIRS := ./src

.PHONY: build run clean

build:
	$(ZIG) build

run:
	$(ZIG) build run

test:
	$(ZIG) build test

clean:
	rm -Rf zig-cache zig-out