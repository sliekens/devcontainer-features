# Aspire CLI (aspire-cli)

Installs the .NET Aspire CLI.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/aspire-cli:1": {
        "quality": "release"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `quality` | string | `release` | Quality to download. Allowed: `release`, `staging`, `dev`. |

## Persistent State

This feature uses a persistent volume named `aspire-cli-state-${devcontainerId}` mounted at `/var/lib/aspire-cli`.  
On create, it links `/var/lib/aspire-cli` to `$HOME/.aspire` so CLI state persists across container rebuilds.
