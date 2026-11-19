package main

import (
	"reflect"
	"testing"
)

func TestOpenArgs(t *testing.T) {
	cases := []struct {
		in         bool
		host, name string
		create     bool
		dir        string
		want       []string
	}{
		{true, "local", "api", false, "", []string{"switch-session", "api"}},
		{true, "local", "api", true, "/d", []string{"switch-session", "--create", "--cwd", "/d", "api"}},
		{true, "workmac", "web", true, "/d", []string{"switch-session", "--create", "workmac:web"}},
		{false, "local", "api", false, "", []string{"attach", "-c", "api"}},
		{false, "workmac", "web", false, "", []string{"attach", "--host", "workmac", "web"}},
		{false, "workmac", "web", true, "", []string{"new", "--host", "workmac", "web"}},
	}
	for _, c := range cases {
		if got := openArgs(c.in, c.host, c.name, c.create, c.dir); !reflect.DeepEqual(got, c.want) {
			t.Errorf("openArgs(%v,%q,%q,%v,%q) = %v, want %v", c.in, c.host, c.name, c.create, c.dir, got, c.want)
		}
	}
}

func TestAgoAndMatches(t *testing.T) {
	for d, want := range map[int64]string{5: "now", 120: "2m", 7200: "2h", 172800: "2d"} {
		if got := ago(1_000_000, 1_000_000-d); got != want {
			t.Errorf("ago(-%d) = %q, want %q", d, got, want)
		}
	}
	if !matches("ppu-toys-ppu-1013", "PPU 1013") || matches("cliban", "ppu") {
		t.Error("matches: every term must appear, case-insensitive")
	}
}

func TestScrollKeepsCursorVisible(t *testing.T) {
	lines := []string{"0", "1", "2", "3", "4", "5"}
	if got := scroll(lines, 5, 3); !reflect.DeepEqual(got, []string{"3", "4", "5"}) {
		t.Errorf("scroll to end = %v", got)
	}
	if got := scroll(lines, 0, 3); !reflect.DeepEqual(got, []string{"0", "1", "2"}) {
		t.Errorf("scroll at top = %v", got)
	}
}

func TestDirSession(t *testing.T) {
	if got := dirSession("/home/a/dev/my.app"); got != "my_app" {
		t.Errorf("dirSession = %q, want my_app", got)
	}
}

func TestMarkedRange(t *testing.T) {
	m := model{hosts: []host{{Name: "local", Sessions: []session{{Name: "a"}, {Name: "b"}, {Name: "c"}, {Name: "d"}}}}}
	m.si = 1
	if got := m.marked(); len(got) != 1 || got[0].Name != "b" {
		t.Errorf("no visual: marked = %v, want just b", got)
	}
	m.visual, m.anchor, m.si = true, 3, 1 // range drawn upward
	var names []string
	for _, s := range m.marked() {
		names = append(names, s.Name)
	}
	if !reflect.DeepEqual(names, []string{"b", "c", "d"}) {
		t.Errorf("visual 3→1: marked = %v, want [b c d]", names)
	}
}
