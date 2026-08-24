# Notes for App Review — paste into App Store Connect

Context: this text is meant for the "Notes" field on the version submission in
App Store Connect, responding to the Guideline 5.6 (Developer Code of Conduct)
rejection received on Aug 19, 2026 for submission `848be217-78a3-4e4a-880d-054ae41f52cb`.

---

Nestline Speedway is a fully offline, single-player racing/breeding game built
with Flutter. It contains no ad SDK, no analytics or attribution SDK, no
remote configuration, no server-side feature flags, and makes no network
request of any kind at any point during use. All gameplay logic (the
turn-based race engine, the Mendelian genetics/breeding simulation, and
season progression) runs entirely on-device from a local seeded RNG, and all
game state is persisted only to local device storage (`shared_preferences`)
— nothing is ever transmitted anywhere.

The app has exactly two screens that use an embedded WebView: Settings →
Privacy Policy and Settings → Help & Support. Both load a static HTML file
that ships inside the app bundle itself (`assets/web/privacy.html` and
`assets/web/support.html`); nothing is fetched from a server, JavaScript is
disabled in both WebViews, and there is no redirect or dynamically served
content anywhere in the app. Every other screen is native Flutter UI.

In this build we also added a privacy manifest (`PrivacyInfo.xcprivacy`,
`NSPrivacyTracking = false`, no data types collected) that matches the
bundled privacy policy, and bumped the build number so this is reviewed as a
distinct submission from the one that was rejected.

We reviewed our own source end to end and could not find any hidden, gated,
A/B-tested, or remotely toggled functionality — the app behaves identically
for every user, on every device, at every time, including for App Review. We
would very much appreciate a thorough playthrough this time (Title → Stable →
Hatchery / Flock / Upgrades / Codex, and Season → Race / Trader / Training /
Rest are all reachable from the main menu) so we can understand specifically
what triggered the 5.6 flag. We're happy to provide a source walkthrough or a
full playthrough recording if that would help confirm there is no cloaking or
fraudulent behavior in this app.

Thank you for your time.
