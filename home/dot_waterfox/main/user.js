// Waterfox profile prefs -- managed by chezmoi (profile: ~/.waterfox/main).
// Deliberately short: Waterfox already ships telemetry/studies/Safe Browsing off,
// so nothing from Betterfox/arkenfox is copied. See docs/waterfox.md.

// --- Vertical + tree tabs (native; no Sidebery needed)
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.revamp", true);
user_pref("browser.tabs.verticalTabs.tree.enabled", true);

// --- Portal file picker (default 2 = auto = off outside Flatpak)
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);

// --- Memory: unload tabs idle for an hour when memory is low (default false on Linux)
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("browser.tabs.min_inactive_duration_before_unload", 3600000);

// --- DNS: off. Waterfox defaults to DoH (trr.mode 2) + an OHTTP relay, which can
// bypass the work VPN's split-horizon DNS. 5 = TRR explicitly disabled.
user_pref("network.trr.mode", 5);
