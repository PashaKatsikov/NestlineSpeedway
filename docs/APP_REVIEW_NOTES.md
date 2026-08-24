# Notes for App Review — paste into App Store Connect

Context: this text is meant for the "Notes" field on the version submission in
App Store Connect, responding to the Guideline 5.6 (Developer Code of Conduct)
rejection received on Aug 19, 2026 for submission `848be217-78a3-4e4a-880d-054ae41f52cb`.

---

Nestline Speedway is a fully offline, single-player racing/breeding game built
with Flutter. This build contains no ad SDK, no analytics or attribution SDK,
no remote configuration, no server-side feature flags, and makes no network
request of any kind at any point during use. All gameplay logic (the turn-based
race engine, the Mendelian genetics/breeding simulation, and season
progression) runs entirely on-device from a local seeded RNG, and all game
state is persisted only to local `shared_preferences` storage — nothing is
ever transmitted anywhere.

In direct response to the "features that appear to have been intentionally
hidden" finding: the only two screens that previously used an embedded
WebView (Privacy Policy and Help & Support) have been removed in this update
and replaced with native Flutter screens, so the binary no longer contains any
component capable of rendering remote or dynamically served content of any
kind. We have also added an `NSPrivacyTracking = false` privacy manifest
(`PrivacyInfo.xcprivacy`) confirming zero data collection and zero tracking,
consistent with the bundled privacy policy.

We reviewed our own source end to end and could not find any hidden, gated,
A/B-tested, or remotely toggled functionality — the app behaves identically
for every user, on every device, at every time, including for App Review.

We would very much appreciate it if the review team could play through the
app thoroughly this time (Title → Stable → Hatchery / Flock / Upgrades /
Codex, and Season → Race / Trader / Training / Rest are all reachable from
the main menu) and confirm there is no cloaking or fraudulent behavior. If the
review team can point to the specific feature or behavior that triggered the
5.6 flag, we will gladly address it directly — we're also happy to provide a
full source walkthrough or a screen recording of a complete playthrough.

Thank you for your time.
