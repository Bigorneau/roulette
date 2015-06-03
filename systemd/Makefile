XDG_CONFIG_HOME ?= $(HOME)/.config
CURRENT_DIR = $(shell pwd)

SYSTEMD_USER_DIR = user

all: user-services

.PHONY: all clean user-services

user-services:
	-mkdir --parents --verbose $(XDG_CONFIG_HOME)/systemd/user
	-ln --symbolic $(CURRENT_DIR)/$(SYSTEMD_USER_DIR)/ddproulette-fetch.service $(XDG_CONFIG_HOME)/systemd/user
	-ln --symbolic $(CURRENT_DIR)/$(SYSTEMD_USER_DIR)/ddproulette-fetch.timer $(XDG_CONFIG_HOME)/systemd/user
	-ln --symbolic $(CURRENT_DIR)/$(SYSTEMD_USER_DIR)/ddproulette-roulette.service $(XDG_CONFIG_HOME)/systemd/user
	-ln --symbolic $(CURRENT_DIR)/$(SYSTEMD_USER_DIR)/ddproulette-roulette.timer $(XDG_CONFIG_HOME)/systemd/user
	-ln --symbolic $(CURRENT_DIR)/$(SYSTEMD_USER_DIR)/ddproulette.service $(XDG_CONFIG_HOME)/systemd/user

clean:
	-rm --recursive --force $(XDG_CONFIG_HOME)/systemd/user/ddproulette-fetch.service
	-rm --recursive --force $(XDG_CONFIG_HOME)/systemd/user/ddproulette-fetch.timer
	-rm --recursive --force $(XDG_CONFIG_HOME)/systemd/user/ddproulette-roulette.service
	-rm --recursive --force $(XDG_CONFIG_HOME)/systemd/user/ddproulette-roulette.timer
	-rm --recursive --force $(XDG_CONFIG_HOME)/systemd/user/ddproulette.service
