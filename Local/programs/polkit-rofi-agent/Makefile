PREFIX ?= $(HOME)/.local
BINDIR = $(PREFIX)/bin
CFLAGS = -O2 -s -Wno-deprecated-declarations
LIBS = $(shell pkg-config --cflags --libs glib-2.0 polkit-agent-1 polkit-gobject-1)

all: polkit-rofi-agent

polkit-rofi-agent: polkit-rofi-agent.c
	gcc $(CFLAGS) $< -o $@ $(LIBS)

install: polkit-rofi-agent
	mkdir -p $(DESTDIR)$(BINDIR)
	cp polkit-rofi-agent $(DESTDIR)$(BINDIR)/

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/polkit-rofi-agent

.PHONY: all install uninstall
