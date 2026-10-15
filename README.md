[![Beta build](https://github.com/stylersnico/LetsCheck-Checkmk-2.5-3/actions/workflows/beta.yml/badge.svg)](https://github.com/stylersnico/LetsCheck-Checkmk-2.5-3/actions/workflows/beta.yml)

# LetsCheck for Checkmk 2.5/3+

LetsCheck is a Checkmk client for Android, iOS, Linux, macOS and Windows written with the [Flutter SDK](https://flutter.dev/).

[Checkmk](https://checkmk.com/) is a leading tool for Infrastructure and Application Monitoring. Simple configuration, scalable, flexible. Open Source and Enterprise.

This is a fork of [jochumdev/letscheck](https://github.com/jochumdev/letscheck) that adds Checkmk 3.0 support.

## Features

- View Hosts/Services with comments
- Notifications
- Search Hosts/Services, use the | symbol to separate multiple searches
- Metric graphs per service
- Recent host and service events

## What's new in this fork

### Checkmk 3.0 support

Checkmk 3.0 removed REST API endpoints the original app relied on.

- Host and service lists are fetched with `POST /domain-types/{host,service}/collections/all`, the only method left in Checkmk 3.0. Older servers that answer 404/405 fall back to the former `GET`.
- The connection test calls `/api/1.0/version`. It checks the credentials and reads the server version, instead of loading the GUI login page.
- Events: all relative ages (`s`, `ms`, `m`, `h`, `d`) are parsed and states are mapped correctly.

Tested with Checkmk 2.3, 2.4 and 3.0.

### New functions

- **Metric graphs:** the service screen shows a status card and graphs of the service metrics over the last 4 hours.
- **Recent events:** the connection screen lists the host and service alerts of the last 4 hours, like the Checkmk "Events of recent 4 hours" dashlet.
- Service names in grouped cards link to the service.

### Style change

The dark theme uses the Checkmk "modern dark" palette: Checkmk background and surface colors, the Checkmk green accent, and Checkmk state colors (OK, WARN, CRIT, UNKNOWN, PENDING). Corners are squarer (4 px radius), as in the Checkmk GUI. The add button is hidden on settings screens.

### Fixes

- "Allow insecure connections" was inverted: certificate validation was skipped by default. It is now skipped only when the option is on, and only for that connection.

## Download

Get it from [GitHub Releases](https://github.com/stylersnico/LetsCheck-Checkmk-2.5-3/releases). Current builds are betas.

- **Android:** signed with a debug key. Uninstall the original app first.
- **macOS:** not signed or notarized. Right-click the app and choose "Open", or run `xattr -cr /Applications/letscheck.app`.
- **Windows:** x64 only.

## Demo

![image](docs/videos/letscheck_v0.0.1-rc1.webp)

## FAQ

The “Frequently asked questions” page of the original app is available on the [GitHub wiki](https://github.com/jochumdev/letscheck/wiki/FAQ).

## Development

**Commit**:

```
git add ./file1 ./file2
./scripts/commit_fix.sh "a bug in component x"
```

**Build**:

Run the "Beta build" workflow from the Actions tab. It builds Android, Linux x64, flatpak, macOS and Windows x64.

**Release**:

- Bump `version` in `pubspec.yaml`
- Run the "Beta build" workflow and download its artifacts
- Create a release on GitHub with the artifacts

**API integration test**:

```
cd vendor/checkmk_api
CMK_URL=https://checkmk.example.com CMK_SITE=mysite CMK_USER=automation CMK_SECRET=... flutter test test/integration_test.dart
```

## Authors

- [@jochumdev](https://github.com/jochumdev): original author
- [@stylersnico](https://github.com/stylersnico): Checkmk 3.0 support, new functions and style, with the help of Claude Opus 5.5

## License

Apache 2.0 - Copyright 2025 by [@jochumdev](https://github.com/jochumdev), modifications Copyright 2026 by [@stylersnico](https://github.com/stylersnico)
