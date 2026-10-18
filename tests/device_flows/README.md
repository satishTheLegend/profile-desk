# Integrated device-flow procedure

Run these on a dedicated development/QA installation. Test account aliases and attachments must be synthetic. Never capture QR values, pairing codes, conversation content or authentication tokens in screenshots/logs. Native storage fixtures are separate from this procedure and prove no real-service compatibility.

1. Install the intended variant; cold-launch after force-stop. Confirm welcome, separate primary-device explanation, empty state and selector reachability.
2. Create a synthetic local profile. Confirm alias stays correct during loading; keep setup for later, restart, reopen the same saved entry. Then remove local setup and wait for cleanup; verify empty state. Do not pair real accounts without authorization.
3. Create two named profiles, edit and reorder labels. Rapidly switch while loading; verify newest alias remains selected and no stale content is revealed. Repeat while backgrounding, rotating/resizing and showing keyboard.
4. Enable supported device authentication. Open account manager/settings, lock or background, verify labels and content remain hidden. Cancel authentication, trigger lock again during auth, then unlock once. Confirm no double prompt and no covered-screen dead end. Test enrollment/credential change on a dedicated device.
5. Use authorized service accounts only: pair each intended account, manually confirm displayed identity, perform text/photo/document sends to consenting recipients, verify files arrive in the originating account. Never use a fake account identity as successful pairing evidence.
6. While a file action is open, try switching/removing/backgrounding; cancel and verify no callback reaches another account. Exercise cloud documents, large/empty files, external destinations and disk pressure.
7. Capture an accessibility checklist for VoiceOver/TalkBack, full long aliases, tablet external keyboard,320px-equivalent small screen at large text and portrait/landscape. Validate QR/composer and native selector separately.
8. Reboot, upgrade same signed installation, restore/reinstall on designated devices, and execute cleanup process interruption at each journal stage. Never edit live browser databases.
9. For retention, start approved accounts and record actual timestamp/device/provider/checkpoint, repeat at7 and14 elapsed days without intentional unlinking. Keep revocation tests separate.

Record platform, OS/provider, device, build hash, exact steps, result and evidence pointer in `docs/acceptance.csv`. Do not replace NOT_RUN with PASS from source review. Execute local helper `launch_android.sh SERIAL PACKAGE` to verify an installed app survives a cold start; it does not perform account/service interactions.

## Automated integrated shell smoke

`python3 tests/device_flows/run_shell_integration.py -d DEVICE_ID` builds an isolated QA copy and launches the real shell/bridge/engine. It creates only a timestamped synthetic profile, opens the fixed official URL without reading DOM/QR or pairing, disposes the view, keeps setup and performs scoped local cleanup. It never removes unrelated profiles. Run on a supported dedicated simulator/provider; it intentionally fails unsupported providers. This proves integration/lifecycle calls, not service authentication or message/media compatibility.

The Flutter integration-test SDK plugin is intentionally absent from the production app pubspec. The runner copies current source into ignored `build/qa-shell-workspace`, adds the SDK test dependency only there, enforces the fixture lockfile, and runs the real native app. Do not add that dependency back to the production manifest: the tested Flutter version includes iOS dev plugins in release linkage.
