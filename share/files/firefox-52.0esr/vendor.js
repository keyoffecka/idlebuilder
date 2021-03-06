// Use LANG environment variable to choose locale
// pref("intl.locale.matchOS", true);
pref("intl.locale.matchOS", false);

// Disable default browser checking.
pref("browser.shell.checkDefaultBrowser", false);

// Don't disable our bundled extensions in the application directory
pref("extensions.autoDisableScopes", 11);
pref("extensions.shownSelectionUI", true);

// Opt all of us into e10s, instead of just 50%
//pref("browser.tabs.remote.autostart", true);
pref("browser.tabs.remote.autostart", false);
