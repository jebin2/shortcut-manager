package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

var (
	UserShortcutDir    string
	SystemShortcutDirs = []string{
		"/usr/share/applications",
		"/usr/local/share/applications",
	}
)

func init() {
	home, _ := os.UserHomeDir()
	UserShortcutDir = filepath.Join(home, ".local", "share", "applications")
}

type Shortcut struct {
	Path    string
	Type    string
	Name    string
	AppName string
	Exec    string
}

func ensureUserDir() error {
	return os.MkdirAll(UserShortcutDir, 0755)
}

func ParseDesktopFile(path string) map[string]string {
	data := map[string]string{
		"Name": "", "Comment": "", "Exec": "", "Path": "",
		"Icon": "", "Terminal": "false", "NoDisplay": "false",
		"Categories": "",
	}
	file, err := os.Open(path)
	if err != nil {
		return data
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, "[") {
			continue
		}
		if idx := strings.Index(line, "="); idx != -1 {
			key := strings.TrimSpace(line[:idx])
			val := strings.TrimSpace(line[idx+1:])
			if _, exists := data[key]; exists {
				data[key] = val
			}
		}
	}
	return data
}

func UpdateDesktopFile(path string, updates map[string]string) error {
	if err := ensureUserDir(); err != nil {
		return err
	}
	defer exec.Command("update-desktop-database", UserShortcutDir).Run()

	var lines []string
	if _, err := os.Stat(path); err == nil {
		file, err := os.Open(path)
		if err != nil {
			return err
		}
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			lines = append(lines, scanner.Text())
		}
		file.Close()
	} else {
		lines = []string{"[Desktop Entry]", "Version=1.0", "Type=Application"}
	}

	updatedKeys := make(map[string]bool)
	var newLines []string
	inDesktopEntry := false

	for _, line := range lines {
		stripped := strings.TrimSpace(line)
		if stripped == "[Desktop Entry]" {
			inDesktopEntry = true
			newLines = append(newLines, line)
			continue
		} else if strings.HasPrefix(stripped, "[") {
			inDesktopEntry = false
			newLines = append(newLines, line)
			continue
		}

		if inDesktopEntry && strings.Contains(stripped, "=") && !strings.HasPrefix(stripped, "#") {
			idx := strings.Index(stripped, "=")
			key := strings.TrimSpace(stripped[:idx])
			if val, exists := updates[key]; exists {
				if val != "" {
					newLines = append(newLines, fmt.Sprintf("%s=%s", key, val))
				}
				updatedKeys[key] = true
				continue
			}
		}
		newLines = append(newLines, line)
	}

	insertIdx := len(newLines)
	for i, line := range newLines {
		if strings.HasPrefix(strings.TrimSpace(line), "[") && strings.TrimSpace(line) != "[Desktop Entry]" {
			insertIdx = i
			break
		}
	}

	var additions []string
	for k, v := range updates {
		if !updatedKeys[k] && v != "" {
			additions = append(additions, fmt.Sprintf("%s=%s", k, v))
		}
	}

	finalLines := append(newLines[:insertIdx], append(additions, newLines[insertIdx:]...)...)

	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0755)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := bufio.NewWriter(file)
	for _, line := range finalLines {
		writer.WriteString(line + "\n")
	}
	return writer.Flush()
}

func copyFile(src, dst string) error {
	input, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	return os.WriteFile(dst, input, 0755)
}

func DeleteOrHideShortcut(path string) error {
	defer exec.Command("update-desktop-database", UserShortcutDir).Run()
	if strings.HasPrefix(path, UserShortcutDir) {
		return os.Remove(path)
	}
	ensureUserDir()
	filename := filepath.Base(path)
	target := filepath.Join(UserShortcutDir, filename)
	if err := copyFile(path, target); err != nil {
		return err
	}
	return UpdateDesktopFile(target, map[string]string{"NoDisplay": "true"})
}

func GetAllShortcuts() []Shortcut {
	var shortcuts []Shortcut
	seen := make(map[string]bool)

	// User shortcuts
	entries, err := os.ReadDir(UserShortcutDir)
	if err == nil {
		for _, e := range entries {
			if !e.IsDir() && strings.HasSuffix(e.Name(), ".desktop") {
				path := filepath.Join(UserShortcutDir, e.Name())
				shortcuts = append(shortcuts, Shortcut{
					Path: path, Type: "User", Name: e.Name(),
				})
				seen[e.Name()] = true
			}
		}
	}

	// System shortcuts
	for _, dir := range SystemShortcutDirs {
		entries, err := os.ReadDir(dir)
		if err == nil {
			for _, e := range entries {
				if !e.IsDir() && strings.HasSuffix(e.Name(), ".desktop") && !seen[e.Name()] {
					path := filepath.Join(dir, e.Name())
					shortcuts = append(shortcuts, Shortcut{
						Path: path, Type: "System", Name: e.Name(),
					})
					seen[e.Name()] = true
				}
			}
		}
	}

	for i := range shortcuts {
		data := ParseDesktopFile(shortcuts[i].Path)
		if name, ok := data["Name"]; ok && name != "" {
			shortcuts[i].AppName = name
		} else {
			shortcuts[i].AppName = shortcuts[i].Name
		}
		shortcuts[i].Exec = data["Exec"]
	}

	sort.Slice(shortcuts, func(i, j int) bool {
		return strings.ToLower(shortcuts[i].AppName) < strings.ToLower(shortcuts[j].AppName)
	})

	return shortcuts
}
