// tpanel: a command panel for tuios sessions on this machine and its hosts.
// Browse sessions per host, attach, start (by name or zoxide project), kill.
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
)

// Kanagawa, to match the terminal.
var (
	cFg     = lipgloss.Color("#DCD7BA")
	cDim    = lipgloss.Color("#727169")
	cLine   = lipgloss.Color("#54546D")
	cSel    = lipgloss.Color("#2A2A37")
	cMark   = lipgloss.Color("#43242B") // visual range: Kanagawa winterRed
	cBlue   = lipgloss.Color("#7E9CD8")
	cGreen  = lipgloss.Color("#98BB6C")
	cYellow = lipgloss.Color("#E6C384")
	cRed    = lipgloss.Color("#FF5D62")
	cViolet = lipgloss.Color("#957FB8")
	cAqua   = lipgloss.Color("#7AA89F")
)

var agentColor = map[string]lipgloss.Color{
	"working": cBlue, "waiting": cYellow, "blocked": cRed, "delegating": cGreen, "done": cDim,
}

type session struct {
	Name       string `json:"name"`
	Windows    int    `json:"window_count"`
	Agent      string `json:"agent_state"`
	Attached   bool   `json:"attached"`
	LastActive int64  `json:"last_active"`
}

type host struct {
	Name     string    `json:"host"` // "local" or a [hosts] name
	Status   string    `json:"status"`
	Sessions []session `json:"sessions"`
	Cores    int
	Load     float64
	Addr     string // ssh destination, from [hosts]
	Command  string // tuios on that host
}

type window struct {
	Title   string `json:"display_name"`
	Cwd     string `json:"cwd"`
	Agent   string `json:"agent_state"`
	Focused bool   `json:"focused"`
}

type mode int

const (
	browse mode = iota
	filtering
	naming
	confirmKill
)

type (
	hostsMsg struct {
		hosts []host
		err   error
	}
	windowsMsg struct {
		target string
		wins   []window
	}
	dirListMsg struct {
		host string
		dirs []string
		err  error
	}
	pickedMsg  struct{ host, dir string }
	createdMsg struct {
		host, name string
		err        error
	}
	doneMsg struct{ err error }
	killMsg struct{ err error }
	tickMsg struct{}
)

type model struct {
	hosts   []host
	hi, si  int
	windows map[string][]window
	w, h    int
	mode    mode
	input   textinput.Model
	filter  string
	note    string
	err     string
	self    string // the tuios session this runs in, if any
	visual  bool   // v/V: the rows from anchor to the cursor are marked
	anchor  int
	// Set when the panel quits to hand the terminal to tuios (outside tuios).
	execArgs []string
	execDir  string
	chose    bool
}

func tuios(args ...string) ([]byte, error) {
	out, err := exec.Command("tuios", args...).Output()
	if ee, ok := err.(*exec.ExitError); ok && len(ee.Stderr) > 0 {
		err = fmt.Errorf("%s", strings.TrimSpace(string(ee.Stderr)))
	}
	return out, err
}

func loadHosts() tea.Msg {
	out, err := tuios("ls", "--all-hosts", "--json")
	if err != nil {
		return hostsMsg{err: err}
	}
	var ls struct{ Hosts []host }
	if err := json.Unmarshal(out, &ls); err != nil {
		return hostsMsg{err: err}
	}
	var info struct {
		Hosts []struct {
			Host    string
			Cores   int
			Load1   float64
			Addr    string
			Command string
		}
	}
	if out, err := tuios("hosts", "--json"); err == nil {
		_ = json.Unmarshal(out, &info)
	}
	for i := range ls.Hosts {
		h := &ls.Hosts[i]
		sort.SliceStable(h.Sessions, func(a, b int) bool { return h.Sessions[a].LastActive > h.Sessions[b].LastActive })
		for _, in := range info.Hosts {
			if in.Host == h.Name {
				h.Cores, h.Load, h.Addr, h.Command = in.Cores, in.Load1, in.Addr, in.Command
			}
		}
	}
	sort.SliceStable(ls.Hosts, func(a, b int) bool {
		return ls.Hosts[a].Name == "local" || (ls.Hosts[b].Name != "local" && ls.Hosts[a].Name < ls.Hosts[b].Name)
	})
	return hostsMsg{hosts: ls.Hosts}
}

func loadWindows(target string) tea.Cmd {
	return func() tea.Msg {
		var r struct{ Windows []window }
		if out, err := tuios("list-windows", "-s", target, "--json"); err == nil {
			_ = json.Unmarshal(out, &r)
		}
		return windowsMsg{target, r.Windows}
	}
}

// remotePath finds tools in a non-interactive ssh shell, which skips the login PATH.
// shortcut: fixed Homebrew/user dirs; a host with zoxide elsewhere needs it here.
const remotePath = "env PATH=/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH "

// loadDirList reads zoxide's folders on a host, most frecent first.
func loadDirList(h host) tea.Cmd {
	return func() tea.Msg {
		cmd := exec.Command("zoxide", "query", "-l")
		if h.Name != "local" {
			cmd = exec.Command("ssh", "-o", "BatchMode=yes", h.Addr, remotePath+"zoxide query -l")
		}
		out, err := cmd.Output()
		return dirListMsg{h.Name, strings.Split(strings.TrimSpace(string(out)), "\n"), err}
	}
}

// pickDir suspends the panel and runs fzf over a host's folders, like ftz.
func pickDir(hostName string, dirs []string) tea.Cmd {
	var out strings.Builder
	shown := hostName
	if shown == "local" {
		shown, _ = os.Hostname()
		shown = strings.SplitN(shown, ".", 2)[0]
	}
	label := " 󰉋 folders on " + shown + " "
	cmd := exec.Command("fzf", "--no-sort", "--reverse", "--height", "100%", "--scheme", "path",
		"--border", "rounded", "--border-label", label, "--prompt", "  ", "--pointer", "▌", "--gutter", " ",
		"--info", "inline-right", "--header", "enter attach or create its session · esc back",
		"--color", "fg:#dcd7ba,fg+:#dcd7ba,bg+:#2a2a37,hl:#e6c384,hl+:#e6c384,gutter:-1,prompt:#7e9cd8,pointer:#98bb6c,info:#727169,header:#727169,border:#54546d,label:#7e9cd8")
	if hostName == "local" {
		cmd.Args = append(cmd.Args, "--preview", "ls -A --color=always {}", "--preview-window", "right,40%,border-left,<100(hidden)")
	}
	cmd.Stdin = strings.NewReader(strings.Join(dirs, "\n"))
	cmd.Stdout = &out
	return tea.ExecProcess(cmd, func(error) tea.Msg {
		return pickedMsg{hostName, strings.TrimSpace(out.String())}
	})
}

// dirSession names a folder's session the way ftz does: its basename, dots as underscores.
func dirSession(dir string) string { return strings.ReplaceAll(filepath.Base(dir), ".", "_") }

// createRemote starts a detached session in a folder on a host, through that
// host's own tuios: `tuios new --host` cannot take a remote --cwd.
func createRemote(h host, name, dir string) tea.Cmd {
	return func() tea.Msg {
		tuiosBin := h.Command
		if tuiosBin == "" {
			tuiosBin = remotePath + "tuios"
		}
		q := func(s string) string { return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'" }
		out, err := exec.Command("ssh", "-o", "BatchMode=yes", h.Addr,
			tuiosBin+" new "+q(name)+" --cwd "+q(dir)+" --detach").CombinedOutput()
		if err != nil {
			err = fmt.Errorf("%s", strings.TrimSpace(string(out)))
		}
		return createdMsg{h.Name, name, err}
	}
}

func tick() tea.Cmd { return tea.Tick(3*time.Second, func(time.Time) tea.Msg { return tickMsg{} }) }

// target names a session for tuios verbs: NAME here, HOST:NAME on a host.
func target(hostName, name string) string {
	if hostName == "local" {
		return name
	}
	return hostName + ":" + name
}

// openArgs is the tuios command that shows a session. Inside tuios the client
// switches in place; outside, the panel's terminal becomes the client.
func openArgs(inTuios bool, hostName, name string, create bool, dir string) []string {
	if inTuios {
		args := []string{"switch-session"}
		if create {
			args = append(args, "--create")
			if dir != "" && hostName == "local" {
				args = append(args, "--cwd", dir)
			}
		}
		return append(args, target(hostName, name))
	}
	switch {
	case hostName == "local":
		return []string{"attach", "-c", name}
	case create:
		return []string{"new", "--host", hostName, name}
	default:
		return []string{"attach", "--host", hostName, name}
	}
}

func ago(now, t int64) string {
	switch s := now - t; {
	case s < 60:
		return "now"
	case s < 3600:
		return fmt.Sprintf("%dm", s/60)
	case s < 86400:
		return fmt.Sprintf("%dh", s/3600)
	default:
		return fmt.Sprintf("%dd", s/86400)
	}
}

func matches(s, query string) bool {
	s = strings.ToLower(s)
	for _, term := range strings.Fields(strings.ToLower(query)) {
		if !strings.Contains(s, term) {
			return false
		}
	}
	return true
}

func (m model) host() *host {
	if m.hi < len(m.hosts) {
		return &m.hosts[m.hi]
	}
	return nil
}

func (m model) visible() []session {
	h := m.host()
	if h == nil {
		return nil
	}
	var out []session
	for _, s := range h.Sessions {
		if matches(s.Name, m.filter) {
			out = append(out, s)
		}
	}
	return out
}

// marked is what x acts on: the visual range, else the cursor's session.
func (m model) marked() []session {
	v := m.visible()
	if !m.visual {
		if s := m.selected(); s != nil {
			return []session{*s}
		}
		return nil
	}
	lo, hi := min(m.anchor, m.si), max(m.anchor, m.si)
	return v[max(0, lo):min(len(v), hi+1)]
}

func (m model) selected() *session {
	v := m.visible()
	if m.si < len(v) {
		return &v[m.si]
	}
	return nil
}

func (m model) hostByName(name string) *host {
	for i := range m.hosts {
		if m.hosts[i].Name == name {
			return &m.hosts[i]
		}
	}
	return nil
}

func (m model) Init() tea.Cmd { return tea.Batch(loadHosts, tick()) }

func (m *model) clamp() {
	m.hi = max(0, min(m.hi, len(m.hosts)-1))
	m.si = max(0, min(m.si, len(m.visible())-1))
}

func (m model) windowsCmd() tea.Cmd {
	if s := m.selected(); s != nil {
		return loadWindows(target(m.host().Name, s.Name))
	}
	return nil
}

// open shows a session: in place inside tuios, or by handing over the terminal.
func (m model) open(hostName, name string, create bool, dir string) (tea.Model, tea.Cmd) {
	args := openArgs(m.self != "", hostName, name, create, dir)
	m.chose = true
	if m.self == "" {
		m.execArgs, m.execDir = args, dir
		return m, tea.Quit
	}
	return m, func() tea.Msg { _, err := tuios(args...); return doneMsg{err} }
}

func (m model) startInput(md mode, placeholder string) (model, tea.Cmd) {
	m.mode, m.err, m.note = md, "", ""
	m.input.Reset()
	m.input.Placeholder = placeholder
	return m, m.input.Focus()
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.w, m.h = msg.Width, msg.Height
		return m, nil
	case tickMsg:
		return m, tea.Batch(loadHosts, tick())
	case hostsMsg:
		if msg.err != nil {
			m.err = msg.err.Error()
			return m, nil
		}
		var hostName, sessName string
		if h := m.host(); h != nil {
			hostName = h.Name
		}
		if s := m.selected(); s != nil {
			sessName = s.Name
		}
		m.hosts = msg.hosts
		for i, h := range m.hosts {
			if h.Name == hostName {
				m.hi = i
			}
		}
		for i, s := range m.visible() {
			if s.Name == sessName {
				m.si = i
			}
		}
		m.clamp()
		return m, m.windowsCmd()
	case windowsMsg:
		m.windows[msg.target] = msg.wins
		return m, nil
	case dirListMsg:
		if msg.err != nil {
			m.err = "zoxide on " + msg.host + ": " + msg.err.Error()
			return m, nil
		}
		m.note = ""
		return m, pickDir(msg.host, msg.dirs)
	case pickedMsg:
		h := m.hostByName(msg.host)
		if msg.dir == "" || h == nil {
			return m, nil
		}
		name := dirSession(msg.dir)
		for _, s := range h.Sessions {
			if s.Name == name {
				return m.open(h.Name, name, false, "")
			}
		}
		if h.Name == "local" {
			return m.open("local", name, true, msg.dir)
		}
		m.note = "starting " + name + " on " + h.Name + "…"
		return m, createRemote(*h, name, msg.dir)
	case createdMsg:
		if msg.err != nil {
			m.err = msg.err.Error()
			return m, nil
		}
		return m.open(msg.host, msg.name, false, "")
	case doneMsg:
		if msg.err != nil {
			m.err, m.chose = msg.err.Error(), false
			return m, nil
		}
		return m, tea.Quit
	case killMsg:
		if msg.err != nil {
			m.err = msg.err.Error()
		}
		return m, loadHosts
	case tea.KeyMsg:
		return m.key(msg)
	}
	return m, nil
}

func (m model) key(k tea.KeyMsg) (tea.Model, tea.Cmd) {
	if k.String() == "ctrl+c" {
		return m, tea.Quit
	}
	switch m.mode {
	case filtering:
		switch k.String() {
		case "esc":
			m.filter, m.mode = "", browse
			m.input.Blur()
		case "enter":
			m.mode = browse
			m.input.Blur()
		default:
			var cmd tea.Cmd
			m.input, cmd = m.input.Update(k)
			m.filter, m.si = m.input.Value(), 0
			return m, tea.Batch(cmd, m.windowsCmd())
		}
		m.clamp()
		return m, m.windowsCmd()
	case naming:
		switch k.String() {
		case "esc":
			m.mode = browse
			return m, nil
		case "enter":
			name := strings.TrimSpace(m.input.Value())
			if name == "" || strings.ContainsAny(name, ": ") {
				m.err = "a session name has no spaces or colons"
				return m, nil
			}
			m.mode = browse
			return m.open(m.host().Name, name, true, "")
		}
		var cmd tea.Cmd
		m.input, cmd = m.input.Update(k)
		return m, cmd
	case confirmKill:
		m.mode = browse
		if marked := m.marked(); len(marked) > 0 && (k.String() == "y" || k.String() == "Y") {
			var targets []string
			for _, s := range marked {
				targets = append(targets, target(m.host().Name, s.Name))
			}
			m.visual = false
			m.note = fmt.Sprintf("killed %d session(s)", len(targets))
			return m, func() tea.Msg {
				var errs []string
				for _, t := range targets {
					if _, err := tuios("kill-session", t); err != nil {
						errs = append(errs, err.Error())
					}
				}
				if errs != nil {
					return killMsg{fmt.Errorf("%s", strings.Join(errs, "; "))}
				}
				return killMsg{}
			}
		}
		m.note = "kept them"
		return m, nil
	}

	m.err, m.note = "", ""
	switch k.String() {
	case "esc":
		if m.visual {
			m.visual = false
			return m, nil
		}
		return m, tea.Quit
	case "q":
		return m, tea.Quit
	case "v", "V":
		m.visual, m.anchor = !m.visual, m.si
	case "j", "down":
		m.si++
	case "k", "up":
		m.si--
	case "g", "home":
		m.si = 0
	case "G", "end":
		m.si = len(m.visible()) - 1
	case "tab", "l", "right":
		m.hi, m.si, m.visual = (m.hi+1)%max(1, len(m.hosts)), 0, false
	case "shift+tab", "h", "left":
		m.hi, m.si, m.visual = (m.hi-1+len(m.hosts))%max(1, len(m.hosts)), 0, false
	case "1", "2", "3", "4", "5", "6", "7", "8", "9":
		if i := int(k.String()[0] - '1'); i < len(m.hosts) {
			m.hi, m.si, m.visual = i, 0, false
		}
	case "r":
		return m, loadHosts
	case "enter":
		if s := m.selected(); s != nil {
			return m.open(m.host().Name, s.Name, false, "")
		}
	case "n":
		if h := m.host(); h != nil && h.Status == "up" {
			return m.startInput(naming, "session name")
		}
	case "/":
		if h := m.host(); h != nil && h.Status == "up" {
			m.note = "reading folders on " + h.Name + "…"
			return m, loadDirList(*h)
		}
	case "x", "d":
		if len(m.marked()) > 0 {
			m.mode = confirmKill
		}
	case "f":
		m.visual = false
		m2, cmd := m.startInput(filtering, "filter sessions")
		m2.input.SetValue(m.filter)
		return m2, cmd
	}
	m.clamp()
	return m, m.windowsCmd()
}

// ---- drawing ----

func fit(s string, w int) string {
	if w <= 0 {
		return ""
	}
	s = ansi.Truncate(s, w, "…")
	return s + strings.Repeat(" ", max(0, w-lipgloss.Width(s)))
}

func box(title string, lines []string, w, h int, border lipgloss.Color) string {
	bs := lipgloss.NewStyle().Foreground(border)
	ts := lipgloss.NewStyle().Foreground(cBlue).Bold(true)
	t := ansi.Truncate(" "+title+" ", max(0, w-4), "…")
	top := bs.Render("╭─") + ts.Render(t) + bs.Render(strings.Repeat("─", max(0, w-3-lipgloss.Width(t)))+"╮")
	out := []string{top}
	for i := 0; i < h-2; i++ {
		l := ""
		if i < len(lines) {
			l = lines[i]
		}
		out = append(out, bs.Render("│")+fit(l, w-2)+bs.Render("│"))
	}
	out = append(out, bs.Render("╰"+strings.Repeat("─", max(0, w-2))+"╯"))
	return strings.Join(out, "\n")
}

// scroll keeps the cursor row inside a window of n rows.
func scroll(lines []string, cursor, n int) []string {
	start := max(0, min(cursor-n+1, len(lines)-n))
	if cursor < start {
		start = cursor
	}
	return lines[max(0, start):min(len(lines), max(0, start)+n)]
}

func (m model) hostLines(w int) []string {
	var out []string
	for i, h := range m.hosts {
		base := lipgloss.NewStyle()
		if i == m.hi {
			base = base.Background(cSel)
		}
		dot, label := "●", h.Name
		dc := cGreen
		if h.Status != "up" {
			dc = cRed
		}
		if h.Name == "local" {
			label, _ = os.Hostname()
			label = strings.SplitN(label, ".", 2)[0]
		}
		ptr := base.Render(" ")
		if i == m.hi {
			ptr = base.Foreground(cGreen).Render("▌")
		}
		count := fmt.Sprintf("%d", len(h.Sessions))
		name := fit(fmt.Sprintf("%d %s", i+1, label), w-7)
		out = append(out, ptr+base.Foreground(dc).Render(dot+" ")+base.Foreground(cFg).Render(name)+base.Foreground(cDim).Render(fmt.Sprintf("%4s", count)))
		sub := "this machine"
		switch {
		case h.Status != "up":
			sub = h.Status
		case h.Name != "local" && h.Cores > 0:
			sub = fmt.Sprintf("load %.1f / %d", h.Load, h.Cores)
		case h.Name != "local":
			sub = "remote"
		}
		out = append(out, base.Foreground(cDim).Render(fit("    "+sub, w)), "")
	}
	return out
}

func (m model) sessionLines(w int) []string {
	now := time.Now().Unix()
	var out []string
	lo, hi := min(m.anchor, m.si), max(m.anchor, m.si)
	for i, s := range m.visible() {
		inRange := m.visual && i >= lo && i <= hi
		base := lipgloss.NewStyle()
		switch {
		case inRange:
			base = base.Background(cMark)
		case i == m.si:
			base = base.Background(cSel)
		}
		ptr := base.Render(" ")
		switch {
		case i == m.si:
			ptr = base.Foreground(cGreen).Render("▌")
		case inRange:
			ptr = base.Foreground(cRed).Render("▌")
		}
		ac, ok := agentColor[s.Agent]
		dot := base.Foreground(cLine).Render("○ ")
		if ok {
			dot = base.Foreground(ac).Render("● ")
		}
		mark := "  "
		if s.Attached {
			mark = "◉ "
		}
		if m.host().Name == "local" && s.Name == m.self {
			mark = "★ "
		}
		nameW := max(8, w-1-2-12-5-5-2)
		out = append(out, ptr+dot+
			base.Foreground(cFg).Render(fit(s.Name, nameW))+
			base.Foreground(ac).Render(fit(" "+s.Agent, 12))+
			base.Foreground(cDim).Render(fmt.Sprintf("%3dw ", s.Windows)+fmt.Sprintf("%4s ", ago(now, s.LastActive)))+
			base.Foreground(cAqua).Render(mark))
	}
	if len(out) == 0 {
		msg := "no sessions here: n starts one"
		if h := m.host(); h != nil && h.Status != "up" {
			msg = "host is " + h.Status
		}
		out = append(out, "", lipgloss.NewStyle().Foreground(cDim).Render("  "+msg))
	}
	return out
}

func (m model) windowLines() []string {
	s := m.selected()
	if s == nil {
		return nil
	}
	home, _ := os.UserHomeDir()
	var out []string
	for _, w := range m.windows[target(m.host().Name, s.Name)] {
		ptr := "  "
		if w.Focused {
			ptr = lipgloss.NewStyle().Foreground(cGreen).Render("▶ ")
		}
		cwd := w.Cwd
		if strings.HasPrefix(cwd, home) {
			cwd = "~" + cwd[len(home):]
		}
		agent := ""
		if c, ok := agentColor[w.Agent]; ok {
			agent = lipgloss.NewStyle().Foreground(c).Render(w.Agent) + "  "
		}
		out = append(out, ptr+lipgloss.NewStyle().Foreground(cFg).Render(w.Title)+"  "+agent+lipgloss.NewStyle().Foreground(cDim).Render(cwd))
	}
	return out
}

func hints(pairs ...string) string {
	var b strings.Builder
	for i := 0; i+1 < len(pairs); i += 2 {
		b.WriteString(lipgloss.NewStyle().Foreground(cYellow).Bold(true).Render(" " + pairs[i]))
		b.WriteString(lipgloss.NewStyle().Foreground(cDim).Render(" " + pairs[i+1] + " "))
	}
	return b.String()
}

func (m model) View() string {
	if m.w == 0 {
		return ""
	}
	total := 0
	for _, h := range m.hosts {
		total += len(h.Sessions)
	}
	where := "outside tuios"
	if m.self != "" {
		where = "in " + m.self
	}
	left := lipgloss.NewStyle().Foreground(cViolet).Bold(true).Render(" ◆ tuios") + lipgloss.NewStyle().Foreground(cDim).Render("  command panel")
	right := lipgloss.NewStyle().Foreground(cDim).Render(fmt.Sprintf("%s · %d sessions · %d hosts ", where, total, len(m.hosts)))
	header := left + strings.Repeat(" ", max(1, m.w-lipgloss.Width(left)-lipgloss.Width(right))) + right

	bottomH := 0
	if m.h >= 18 {
		bottomH = min(8, m.h/4+2)
	}
	if m.mode != browse && bottomH == 0 {
		bottomH = 3
	}
	bodyH := m.h - 2 - bottomH
	hostW := min(28, max(22, m.w/4))
	mainW := m.w - hostW

	hostName := ""
	if h := m.host(); h != nil {
		hostName = h.Name
		if hostName == "local" {
			hostName, _ = os.Hostname()
			hostName = strings.SplitN(hostName, ".", 2)[0]
		}
	}
	hostBox := box("hosts", m.hostLines(hostW-2), hostW, bodyH, cLine)

	title := "sessions · " + hostName
	if m.filter != "" {
		title += " · f " + m.filter
	}
	mainBox := box(title, scroll(m.sessionLines(mainW-2), m.si, bodyH-2), mainW, bodyH, cBlue)
	body := lipgloss.JoinHorizontal(lipgloss.Top, hostBox, mainBox)

	var bottom string
	switch m.mode {
	case naming:
		bottom = box("new session on "+hostName, []string{" " + m.input.View()}, m.w, bottomH, cYellow)
	case filtering:
		bottom = box("filter", []string{" " + m.input.View()}, m.w, bottomH, cYellow)
	case confirmKill:
		marked := m.marked()
		var names []string
		here := false
		for _, s := range marked {
			names = append(names, s.Name)
			here = here || (m.host().Name == "local" && s.Name == m.self)
		}
		red := lipgloss.NewStyle().Foreground(cRed)
		lines := []string{red.Render(fmt.Sprintf(" kill %d session(s) on %s and every program in them?", len(marked), hostName)),
			lipgloss.NewStyle().Foreground(cFg).Render(" " + strings.Join(names, ", "))}
		if here {
			lines = append(lines, red.Bold(true).Render(" includes the session you are in"))
		}
		bottom = box("kill", lines, m.w, max(bottomH, len(lines)+2), cRed)
	default:
		if bottomH > 0 {
			t := "windows"
			if s := m.selected(); s != nil {
				t += " · " + s.Name
			}
			bottom = box(t, m.windowLines(), m.w, bottomH, cLine)
		}
	}

	var footer string
	switch {
	case m.err != "":
		footer = lipgloss.NewStyle().Foreground(cRed).Render(" ✗ " + m.err)
	case m.note != "":
		footer = lipgloss.NewStyle().Foreground(cGreen).Render(" ✓ " + m.note)
	case m.mode == confirmKill:
		footer = hints("y", "kill", "any key", "keep")
	case m.mode != browse:
		footer = hints("enter", "ok", "esc", "cancel")
	case m.visual:
		footer = lipgloss.NewStyle().Foreground(cRed).Bold(true).Render(fmt.Sprintf(" VISUAL %d ", len(m.marked()))) +
			hints("j/k", "extend", "x", "kill all", "v", "done", "esc", "cancel")
	default:
		footer = hints("enter", "attach", "/", "folder", "n", "new", "x", "kill", "f", "filter", "⇥", "host", "q", "quit")
	}

	parts := []string{header, body}
	if bottom != "" {
		parts = append(parts, bottom)
	}
	parts = append(parts, ansi.Truncate(footer, m.w, "…"))
	return strings.Join(parts, "\n")
}

func main() {
	in := textinput.New()
	in.Prompt = "› "
	in.PromptStyle = lipgloss.NewStyle().Foreground(cYellow)
	in.TextStyle = lipgloss.NewStyle().Foreground(cFg)
	in.Cursor.Style = lipgloss.NewStyle().Foreground(cYellow)
	m := model{windows: map[string][]window{}, input: in, self: os.Getenv("TUIOS_SESSION")}

	res, err := tea.NewProgram(m, tea.WithAltScreen()).Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, "tpanel:", err)
		os.Exit(2)
	}
	final := res.(model)
	if final.execArgs != nil {
		if final.execDir != "" {
			_ = os.Chdir(final.execDir)
		}
		bin, err := exec.LookPath("tuios")
		if err == nil {
			err = syscall.Exec(bin, append([]string{"tuios"}, final.execArgs...), os.Environ())
		}
		fmt.Fprintln(os.Stderr, "tpanel:", err)
		os.Exit(2)
	}
	if !final.chose {
		os.Exit(1) // cancelled: callers may fall back to something else
	}
}
