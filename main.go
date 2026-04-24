package main

import (
	"fmt"
	"os"
	"strings"

	"github.com/charmbracelet/bubbles/table"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/huh"
	"github.com/charmbracelet/lipgloss"
)

type state int

const (
	stateList state = iota
	stateForm
)

var (
	baseStyle = lipgloss.NewStyle().
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("240"))
)

type model struct {
	state       state
	table       table.Model
	searchInput textinput.Model
	form        *huh.Form

	shortcuts []Shortcut

	// Form values
	fName       string
	fComment    string
	fExec       string
	fPath       string
	fIcon       string
	fCategories string
	fTerminal   bool
	fNoDisplay  bool

	editPath string
	isEdit   bool

	width  int
	height int
}

func initialModel() model {
	ti := textinput.New()
	ti.Placeholder = "Search shortcuts..."
	ti.Focus()

	t := table.New(
		table.WithColumns([]table.Column{
			{Title: "Name", Width: 25},
			{Title: "Type", Width: 10},
			{Title: "Exec", Width: 40},
			{Title: "File Path", Width: 40},
		}),
		table.WithFocused(true),
		table.WithHeight(15),
	)

	s := table.DefaultStyles()
	s.Header = s.Header.
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(lipgloss.Color("240")).
		BorderBottom(true).
		Bold(false)
	s.Selected = s.Selected.
		Foreground(lipgloss.Color("229")).
		Background(lipgloss.Color("57")).
		Bold(false)
	t.SetStyles(s)

	m := model{
		state:       stateList,
		table:       t,
		searchInput: ti,
	}

	m.loadShortcuts("")
	return m
}

func (m *model) loadShortcuts(filter string) {
	m.shortcuts = GetAllShortcuts()
	filter = strings.ToLower(filter)

	var rows []table.Row
	for _, s := range m.shortcuts {
		if filter == "" || strings.Contains(strings.ToLower(s.AppName), filter) || strings.Contains(strings.ToLower(s.Exec), filter) {
			rows = append(rows, table.Row{s.AppName, s.Type, s.Exec, s.Path})
		}
	}
	m.table.SetRows(rows)
}

func (m *model) initForm() {
	m.form = huh.NewForm(
		huh.NewGroup(
			huh.NewInput().Title("Application Name").Value(&m.fName),
			huh.NewInput().Title("Comment").Value(&m.fComment),
			huh.NewInput().Title("Exec Command").Value(&m.fExec),
			huh.NewInput().Title("Working Directory (Path)").Value(&m.fPath),
			huh.NewInput().Title("Icon Path").Value(&m.fIcon),
			huh.NewInput().Title("Categories").Value(&m.fCategories),
			huh.NewConfirm().Title("Terminal Application?").Value(&m.fTerminal),
			huh.NewConfirm().Title("Hide from Menus (NoDisplay)?").Value(&m.fNoDisplay),
		),
	)
	m.form.Init()
}

func (m *model) saveShortcut() {
	if m.fName == "" || m.fExec == "" {
		return // Require Name and Exec
	}

	updates := map[string]string{
		"Name":       m.fName,
		"Comment":    m.fComment,
		"Exec":       m.fExec,
		"Path":       m.fPath,
		"Icon":       m.fIcon,
		"Categories": m.fCategories,
		"Terminal":   "false",
		"NoDisplay":  "false",
	}
	if m.fTerminal {
		updates["Terminal"] = "true"
	}
	if m.fNoDisplay {
		updates["NoDisplay"] = "true"
	}

	filepath := m.editPath
	if m.isEdit {
		if !strings.HasPrefix(filepath, UserShortcutDir) {
			filename := filepath[strings.LastIndex(filepath, "/")+1:]
			filepath = UserShortcutDir + "/" + filename
			copyFile(m.editPath, filepath)
		}
		UpdateDesktopFile(filepath, updates)
	} else {
		filename := strings.ReplaceAll(strings.ToLower(m.fName), " ", "-") + ".desktop"
		filepath = UserShortcutDir + "/" + filename
		UpdateDesktopFile(filepath, updates)
	}
	m.loadShortcuts(m.searchInput.Value())
}

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.table.SetHeight(m.height - 10) // leave room for input and help
	}

	if m.state == stateList {
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "esc":
				if m.searchInput.Focused() {
					m.searchInput.Blur()
				} else {
					m.searchInput.Focus()
				}
			case "q":
				if !m.searchInput.Focused() {
					return m, tea.Quit
				}
			case "down", "j":
				if m.searchInput.Focused() {
					m.searchInput.Blur()
				}
				m.table, cmd = m.table.Update(msg)
				return m, cmd
			case "up", "k":
				m.table, cmd = m.table.Update(msg)
				return m, cmd
			case "n":
				if !m.searchInput.Focused() {
					m.state = stateForm
					m.isEdit = false
					m.fName, m.fComment, m.fExec, m.fPath, m.fIcon, m.fCategories = "", "", "", "", "", ""
					m.fTerminal, m.fNoDisplay = false, false
					m.initForm()
					return m, m.form.Init()
				}
			case "e", "enter":
				if !m.searchInput.Focused() {
					if len(m.table.Rows()) > 0 {
						row := m.table.SelectedRow()
						path := row[3] // File Path is index 3
						data := ParseDesktopFile(path)
						m.state = stateForm
						m.isEdit = true
						m.editPath = path
						m.fName = data["Name"]
						m.fComment = data["Comment"]
						m.fExec = data["Exec"]
						m.fPath = data["Path"]
						m.fIcon = data["Icon"]
						m.fCategories = data["Categories"]
						m.fTerminal = strings.ToLower(data["Terminal"]) == "true"
						m.fNoDisplay = strings.ToLower(data["NoDisplay"]) == "true"
						m.initForm()
						return m, m.form.Init()
					}
				}
			case "d":
				if !m.searchInput.Focused() {
					if len(m.table.Rows()) > 0 {
						row := m.table.SelectedRow()
						DeleteOrHideShortcut(row[3])
						m.loadShortcuts(m.searchInput.Value())
					}
				}
			}
		}

		if m.searchInput.Focused() {
			var cmd1 tea.Cmd
			m.searchInput, cmd1 = m.searchInput.Update(msg)
			m.loadShortcuts(m.searchInput.Value())
			return m, cmd1
		} else {
			var cmd2 tea.Cmd
			m.table, cmd2 = m.table.Update(msg)
			return m, cmd2
		}

	} else if m.state == stateForm {
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "esc" {
				m.state = stateList
				return m, nil
			}
		}

		var cmd1 tea.Cmd
		form, cmd1 := m.form.Update(msg)
		if f, ok := form.(*huh.Form); ok {
			m.form = f
		}

		if m.form.State == huh.StateCompleted {
			m.saveShortcut()
			m.state = stateList
		}

		return m, cmd1
	}

	return m, cmd
}

func (m model) View() string {
	if m.state == stateList {
		helpText := "esc/tab: focus search • j/k/arrows: navigate table • n: new • e/enter: edit • d: delete/hide • q: quit (when not searching)"
		ui := lipgloss.JoinVertical(lipgloss.Left,
			"\n  "+m.searchInput.View(),
			"\n"+baseStyle.Render(m.table.View()),
			"\n  "+lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render(helpText),
		)
		return ui
	} else if m.state == stateForm {
		return fmt.Sprintf("\n  Editing Shortcut (Esc to cancel)\n\n%s", m.form.View())
	}
	return ""
}

func main() {
	if err := ensureUserDir(); err != nil {
		fmt.Printf("Error ensuring user directory: %v\n", err)
		os.Exit(1)
	}

	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Alas, there's been an error: %v", err)
		os.Exit(1)
	}
}
