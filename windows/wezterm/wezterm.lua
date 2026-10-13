-- %USERPROFILE%\.config\wezterm\wezterm.lua — WezTerm on the Windows host.
-- Windows host only (docs/windows.md). Copy by hand, together with
-- home/dot_config/ghostty/backgrounds/ → %USERPROFILE%\.config\wezterm\backgrounds\.
--
-- A port of home/dot_config/ghostty/config: same font, same two palettes, same
-- background images, same Alt keybind model (docs/adr/0008-terminal-workspace-model.md):
--   GlazeWM owns Win+*, WezTerm owns Alt+* and the Alt+Space leader,
--   zellij owns Ctrl-modal.
-- Not ported: the cursor shader, equalize_splits and the tab overview grid have
-- no WezTerm equivalent.
--
-- https://wezterm.org/config/files.html

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- --- Shell -------------------------------------------------------------------
-- Open straight into the Arch WSL guest. WezTerm lists one "WSL:<distro>" domain
-- per installed distro; only pick ours if it exists, so the terminal still
-- starts (in PowerShell) before `wsl --install archlinux` has run.
for _, dom in ipairs(wezterm.default_wsl_domains()) do
	if dom.name == "WSL:archlinux" then
		config.default_domain = dom.name
	end
end

-- --- Appearance --------------------------------------------------------------
-- Palettes copied from home/dot_config/ghostty/themes/{dracula,latte}.
config.color_schemes = {
	["dotfiles-dark"] = {
		foreground = "#f8f8f2",
		background = "#282a36",
		cursor_bg = "#8be9fd",
		cursor_border = "#8be9fd",
		cursor_fg = "#282a36",
		selection_bg = "#44475a",
		selection_fg = "#ffffff",
		ansi = { "#21222c", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2" },
		brights = { "#6272a4", "#ff6e6e", "#69ff94", "#ffffa5", "#d6acff", "#ff92df", "#a4ffff", "#ffffff" },
	},
	["dotfiles-light"] = {
		foreground = "#4c4f69",
		background = "#eff1f5",
		cursor_bg = "#179299",
		cursor_border = "#179299",
		cursor_fg = "#eff1f5",
		selection_bg = "#d8dae1",
		selection_fg = "#4c4f69",
		ansi = { "#5c5f77", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299", "#acb0be" },
		brights = { "#6c6f85", "#e64553", "#51cf66", "#f59f00", "#3b82f6", "#f783ac", "#22b8cf", "#bcc0cc" },
	},
}

-- Follow the Windows light/dark setting (PowerToys Light Switch flips it).
-- WezTerm reloads this file when the setting changes. wezterm.gui is absent in
-- the mux server, hence the guard.
local mode = "dark"
if wezterm.gui and wezterm.gui.get_appearance():find("Light") then
	mode = "light"
end
config.color_scheme = "dotfiles-" .. mode

-- Opaque window; depth comes from a faint image over the palette background,
-- as in Ghostty (background-image-opacity = 0.15, fit = cover).
config.background = {
	{
		source = { Color = config.color_schemes[config.color_scheme].background },
		width = "100%",
		height = "100%",
	},
	{
		source = { File = wezterm.config_dir .. "/backgrounds/" .. mode .. ".jpg" },
		opacity = 0.15,
		width = "Cover",
		height = "Cover",
		horizontal_align = "Center",
		vertical_align = "Center",
		repeat_x = "NoRepeat",
		repeat_y = "NoRepeat",
	},
}

-- --- Font --------------------------------------------------------------------
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" })
config.font_size = 14

-- --- Cursor ------------------------------------------------------------------
config.default_cursor_style = "BlinkingBar"

-- --- Window ------------------------------------------------------------------
-- No title bar (GlazeWM draws the borders), tabs at the bottom.
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000

-- --- Keybinds ----------------------------------------------------------------
-- Convention: Alt = focus/act now, Alt+Shift = resize, Alt+Space = leader (rare).
config.leader = { key = "Space", mods = "ALT", timeout_milliseconds = 2000 }

config.keys = {
	-- Splits (panes)
	{ key = "Enter", mods = "ALT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "Enter", mods = "ALT|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "z", mods = "ALT", action = act.TogglePaneZoomState },

	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },

	{ key = "h", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "j", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },
	{ key = "k", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = "l", mods = "ALT|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },

	-- Tabs (Ctrl+Tab / Ctrl+Shift+Tab are WezTerm defaults)
	{ key = "t", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "ALT", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "w", mods = "ALT|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
	{ key = "o", mods = "ALT", action = act.ShowTabNavigator },
	{
		key = "r",
		mods = "ALT",
		action = act.PromptInputLine({
			description = "Tab title",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Search
	{ key = "f", mods = "ALT|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },

	-- Leader (Alt+Space, then key): infrequent ops
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize", one_shot = false, until_unknown = true }) },
	{ key = "n", mods = "LEADER", action = act.SpawnWindow },
	{ key = ",", mods = "LEADER", action = act.MoveTabRelative(-1) },
	{ key = ".", mods = "LEADER", action = act.MoveTabRelative(1) },
	{ key = "b", mods = "LEADER", action = act.ScrollToBottom },
	{ key = "x", mods = "LEADER", action = act.ReloadConfiguration },
}

-- Jump straight to a tab by number.
for i = 1, 9 do
	table.insert(config.keys, { key = tostring(i), mods = "ALT", action = act.ActivateTab(i - 1) })
end

-- Sticky resize mode: stays until Escape or any other key (until_unknown).
config.key_tables = {
	resize = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
		{ key = "Escape", action = "PopKeyTable" },
	},
}

return config
