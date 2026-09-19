# Release flow

1. Build the Proximonster solution in Visual Studio.
2. Run `tools/Build-DlrEngineChannel.ps1` with the GitHub owner name.
3. Verify `channel.json` and the package ZIP with `tools/Validate-DlrEngineChannel.ps1`.
4. Commit/push the package and `channel.json` together to `main`.
5. Wait for GitHub Pages to publish the updated files.
6. Configure Proximonster with the `channel.json` HTTPS URL.
7. Use DLR `Check Update` and verify download → SHA-256 → package validation → staging → activation → post-activation smoke test.

For future releases, generate a new package version. Do not overwrite an already published package archive.
