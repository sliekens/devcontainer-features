# Mono (mono)

> [!WARNING]
> Mono is now maintained by [WineHQ](https://www.winehq.org/news/2025030801) (since August 2024), but they do not yet offer pre-built binaries or apt packages. This feature installs from Microsoft's last-published apt repository (`download.mono-project.com`), which is frozen at the final Microsoft build (February 2024) and expected to remain available for a few more years. The install script uses workarounds to make it work on current systems and may break without notice.

Installs `mono-complete` from the [official Mono stable repository](https://www.mono-project.com/download/stable/#download-lin-debian). The installed version is whatever the Mono project last published to that repository — no version override is offered because Mono is no longer actively developed and only one version is effectively available.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/mono:1": {}
}
```

## Options

This feature does not expose configurable options.


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Mono license](https://gitlab.winehq.org/mono/mono/-/blob/main/LICENSE).

## Links

- [Mono documentation](https://www.mono-project.com/docs/)

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
