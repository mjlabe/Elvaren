GODOT ?= $(shell which godot 2>/dev/null)
ifeq ($(GODOT),)
GODOT = godot
endif

.PHONY: build run

build:
	$(GODOT) --headless --editor --quit
	$(GODOT) --headless --path . --quit-after 2 --scene res://scenes/world/world.tscn
	$(GODOT) --headless --path . --quit-after 2 --scene res://scenes/dungeons/thornveil_room_1.tscn

run:
	$(GODOT) --path .
