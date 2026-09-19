# Proximonster DLR Engine Channel

This repository is the dedicated distribution channel for the Proximonster-managed DLR engine.

It is **not** the Proximonster application source repository and it does **not** contain recordings, cookies, user credentials, or the upstream DouyinLiveRecorder source tree.

## Purpose

- publish validated Proximonster DLR engine packages;
- expose a stable `channel.json` endpoint for Proximonster;
- keep package archives and channel metadata on the same HTTPS GitHub Pages host;
- allow Proximonster to verify archive SHA-256 before staging and activation.

The current Proximonster updater contract expects the channel manifest and package download to use the same host. Therefore this channel uses **GitHub Pages** as the actual distribution host rather than GitHub raw/release URLs.

## First package baseline

- Proximonster DLR Engine: `1.1.1`
- Upstream DLR release: `v4.0.7`
- Verified upstream commit: `fec734a`
- Target runtime: `win-x64`
- Adapter contract: `2`

The package version `1.1.1` is a distribution-package baseline over the already validated 1.1.0 engine implementation. It is intended to exercise and establish the remote package transaction without changing the recording implementation.

## Repository contents

```text
channel.json                         Stable updater endpoint
packages/                            Published package archives
packages/README.md                   Placeholder until first package is published
tools/Build-DlrEngineChannel.ps1     Builds package + manifest from the VS output DLL
tools/Validate-DlrEngineChannel.ps1  Validates package/manifest consistency
.nojekyll                             Serve static assets as-is through Pages
```

## Security rule

Do not put Bilibili cookies, API keys, private certificates, tokens, credentials, or personal configuration into this repository. GitHub Pages content is publicly available when enabled for a public repository.

## GitHub Pages target

Enable Pages from the `main` branch root. The resulting site is expected at:

`https://<github-owner>.github.io/Proximonster-DLR-Engine-Channel/`

The production Proximonster environment variable will then point to:

`https://<github-owner>.github.io/Proximonster-DLR-Engine-Channel/channel.json`
