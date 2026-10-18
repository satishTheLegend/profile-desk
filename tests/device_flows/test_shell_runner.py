"""Device-inventory guards must fail closed before Flutter can install/uninstall."""

import importlib.util
import io
import json
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location("shell_runner", Path(__file__).with_name("run_shell_integration.py"))
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class IOSInventoryParserTests(unittest.TestCase):
    OPENSTEP = b'{ "dev.profiledesk.shellFixture.qa" = { CFBundleIdentifier = "dev.profiledesk.shellFixture.qa"; CFBundleName = "Shell Fixture"; }; }'

    def test_xml_and_binary_plists_do_not_require_conversion(self):
        for format in (plistlib.FMT_XML, plistlib.FMT_BINARY):
            with self.subTest(format=format), patch.object(RUNNER.subprocess, "run") as converter:
                self.assertEqual(RUNNER.parse_ios_inventory(plistlib.dumps({"dev.profiledesk.shellFixture.qa": {}}, fmt=format)),
                                 {"dev.profiledesk.shellFixture.qa"})
                converter.assert_not_called()

    @unittest.skipUnless(Path("/usr/bin/plutil").is_file(), "OpenStep conversion requires macOS plutil")
    def test_real_openstep_inventory_uses_system_plutil(self):
        self.assertEqual(RUNNER.parse_ios_inventory(self.OPENSTEP), {"dev.profiledesk.shellFixture.qa"})

    def test_converter_failure_rejects_inventory(self):
        with patch.object(RUNNER.subprocess, "run", side_effect=subprocess.CalledProcessError(1, ["plutil"])), \
                self.assertRaisesRegex(SystemExit, "inventory after plist conversion"):
            RUNNER.parse_ios_inventory(self.OPENSTEP)

    def test_converter_timeout_rejects_inventory(self):
        with patch.object(RUNNER.subprocess, "run", side_effect=subprocess.TimeoutExpired(["plutil"], 5)), \
                self.assertRaisesRegex(SystemExit, "inventory after plist conversion"):
            RUNNER.parse_ios_inventory(self.OPENSTEP)

    def test_invalid_converted_output_rejects_inventory(self):
        result = subprocess.CompletedProcess(["plutil"], 0, stdout=b"not a plist")
        with patch.object(RUNNER.subprocess, "run", return_value=result), \
                self.assertRaisesRegex(SystemExit, "inventory after plist conversion"):
            RUNNER.parse_ios_inventory(self.OPENSTEP)

    def test_oversized_input_rejected_without_conversion(self):
        with patch.object(RUNNER.subprocess, "run") as converter, self.assertRaisesRegex(SystemExit, "bounded"):
            RUNNER.parse_ios_inventory(b"x" * (RUNNER.MAX_IOS_INVENTORY_BYTES + 1))
        converter.assert_not_called()

    def test_oversized_converted_output_rejected(self):
        result = subprocess.CompletedProcess(["plutil"], 0, stdout=b"x" * (RUNNER.MAX_IOS_INVENTORY_BYTES + 1))
        with patch.object(RUNNER.subprocess, "run", return_value=result), \
                self.assertRaisesRegex(SystemExit, "inventory after plist conversion"):
            RUNNER.parse_ios_inventory(self.OPENSTEP)

    def test_dictionary_with_non_metadata_value_is_rejected(self):
        with self.assertRaisesRegex(SystemExit, "inventory"):
            RUNNER.parse_ios_inventory(plistlib.dumps({"Error": "service unavailable"}))


class SourceSymlinkTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name).resolve()
        self.source = self.base / "source"
        self.stage = self.base / "isolated/stage"
        self.source.mkdir()
        self.stage.mkdir(parents=True)
        (self.source / "content").write_text("synthetic source")

    def validate(self, target):
        link = self.source / "link"
        link.symlink_to(target)
        return RUNNER.isolated_symlink_target(link, self.stage / "link", self.source, self.stage)

    def test_relative_in_tree_source_link_is_preserved(self):
        self.assertEqual(self.validate("content"), "content")

    def test_absolute_link_into_shared_source_is_rejected(self):
        with self.assertRaisesRegex(SystemExit, "Absolute source link"):
            self.validate(str(self.source / "content"))

    def test_relative_link_leaving_original_source_is_rejected(self):
        with self.assertRaisesRegex(SystemExit, "leaves the project"):
            self.validate("../outside")

    def test_source_in_tree_link_that_escapes_staged_layout_is_rejected(self):
        # This resolves within the original source, but preserving it in QA
        # would point to a sibling outside the isolated workspace.
        with self.assertRaisesRegex(SystemExit, "leave the QA workspace"):
            self.validate("../source/content")


class DisposableDeviceTests(unittest.TestCase):
    def guard(self, platform, inventory, *, emulator=True, device_id="dedicated"):
        devices = [{"id": "dedicated", "isSupported": True, "emulator": emulator, "targetPlatform": platform}]
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(RUNNER.subprocess, "check_output", side_effect=[json.dumps(devices), inventory]) as calls, \
                patch.object(RUNNER.shutil, "which", return_value="/synthetic/adb"), \
                patch("sys.stdout", new=io.StringIO()):
            RUNNER.guard_disposable_device(Path(directory), device_id)
            return calls.call_args_list

    def test_android_absent_fixture_is_allowed_on_exact_device(self):
        calls = self.guard("android-arm64", "package:dev.profiledesk.profile_desk\n")
        self.assertEqual(calls[1].args[0], ["/synthetic/adb", "-s", "dedicated", "shell", "pm", "list", "packages"])

    def test_android_failed_build_base_identity_is_protected(self):
        with self.assertRaisesRegex(SystemExit, "already installed"):
            self.guard("android-arm64", "package:dev.profiledesk.shell_fixture\n")

    def test_android_successful_build_qa_identity_is_protected(self):
        with self.assertRaisesRegex(SystemExit, "already installed"):
            self.guard("android-arm64", "package:dev.profiledesk.shell_fixture.qa\n")

    def test_android_inventory_matching_is_exact(self):
        self.guard("android-arm64", "package:dev.profiledesk.shell_fixture.qa_other\n")

    def test_android_inventory_errors_fail_closed(self):
        for output in ("", "Error: package service unavailable\n", "package:android\nError: denied\n"):
            with self.subTest(output=output), self.assertRaisesRegex(SystemExit, "inventory"):
                self.guard("android-arm64", output)

    def test_physical_devices_are_rejected(self):
        with self.assertRaisesRegex(SystemExit, "physical devices"):
            self.guard("ios", b"", emulator=False)

    def test_device_id_must_match_exactly(self):
        with self.assertRaisesRegex(SystemExit, "exact supported"):
            self.guard("android-arm64", "", device_id="ded")

    def test_ios_absent_fixture_is_allowed(self):
        calls = self.guard("ios", plistlib.dumps({"dev.profiledesk.profileDesk.qa": {}}))
        self.assertEqual(calls[1].args[0], ["xcrun", "simctl", "listapps", "dedicated"])

    def test_ios_base_and_qa_identities_are_protected(self):
        for identifier in ("dev.profiledesk.shellFixture", "dev.profiledesk.shellFixture.qa"):
            with self.subTest(identifier=identifier), self.assertRaisesRegex(SystemExit, "already installed"):
                self.guard("ios", plistlib.dumps({identifier: {}}))

    def test_ios_inventory_must_be_dictionary(self):
        with self.assertRaisesRegex(SystemExit, "inventory"):
            self.guard("ios", plistlib.dumps([]))


class OwnedCleanupTests(unittest.TestCase):
    def ownership(self, platform="android"):
        return RUNNER.FixtureOwnership(platform, "dedicated", "/synthetic/adb" if platform == "android" else "xcrun",
                                       RUNNER.fixture_identifiers(platform))

    def clean(self, installed, after, *, platform="android", failure=None):
        with patch.object(RUNNER, "device_inventory", side_effect=[installed, after]) as inventory, \
                patch.object(RUNNER.subprocess, "run", side_effect=failure) as removal, \
                patch("sys.stdout", new=io.StringIO()):
            RUNNER.cleanup_owned_fixture(self.ownership(platform))
            return removal.call_args_list, inventory.call_count

    def test_android_removes_only_owned_flavored_fixture(self):
        production = "dev.profiledesk.profile_desk"
        calls, inventories = self.clean({production, "dev.profiledesk.shell_fixture.qa"}, {production})
        self.assertEqual(calls[0].args[0], ["/synthetic/adb", "-s", "dedicated", "uninstall", "dev.profiledesk.shell_fixture.qa"])
        self.assertEqual(calls[0].kwargs["timeout"], 30)
        self.assertEqual(len(calls), 1)
        self.assertEqual(inventories, 2)

    def test_android_removes_owned_base_and_flavored_fixture(self):
        calls, _ = self.clean(set(RUNNER.fixture_identifiers("android")), set())
        self.assertEqual([call.args[0][-1] for call in calls], ["dev.profiledesk.shell_fixture", "dev.profiledesk.shell_fixture.qa"])

    def test_already_absent_fixture_is_verified_without_removal(self):
        calls, inventories = self.clean({"android"}, {"android"})
        self.assertEqual(calls, [])
        self.assertEqual(inventories, 2)

    def test_ios_removes_only_owned_fixture_on_exact_simulator(self):
        production = "dev.profiledesk.profileDesk"
        calls, _ = self.clean({production, "dev.profiledesk.shellFixture.qa"}, {production}, platform="ios")
        self.assertEqual(calls[0].args[0], ["xcrun", "simctl", "uninstall", "dedicated", "dev.profiledesk.shellFixture.qa"])
        self.assertEqual(len(calls), 1)

    def test_production_identity_can_never_be_claimed_for_cleanup(self):
        ownership = RUNNER.FixtureOwnership("android", "dedicated", "/synthetic/adb", frozenset({"dev.profiledesk.profile_desk"}))
        with patch.object(RUNNER, "device_inventory") as inventory, self.assertRaisesRegex(SystemExit, "exact disposable"):
            RUNNER.cleanup_owned_fixture(ownership)
        inventory.assert_not_called()

    def test_failed_removal_reports_failure_after_final_inventory(self):
        with self.assertRaisesRegex(RuntimeError, "CalledProcessError"):
            self.clean({"dev.profiledesk.shell_fixture.qa"}, set(), failure=subprocess.CalledProcessError(1, ["synthetic"]))

    def test_remaining_owned_identity_fails_cleanup(self):
        with self.assertRaisesRegex(RuntimeError, "dev.profiledesk.shell_fixture.qa"):
            self.clean({"dev.profiledesk.shell_fixture.qa"}, {"dev.profiledesk.shell_fixture.qa"})

    def test_test_failure_still_runs_cleanup(self):
        original = subprocess.CalledProcessError(1, ["flutter", "test"])
        with patch.object(RUNNER.subprocess, "run", side_effect=original), \
                patch.object(RUNNER, "cleanup_owned_fixture") as cleanup, \
                self.assertRaises(subprocess.CalledProcessError) as raised:
            RUNNER.run_owned_test(Path("/synthetic/app"), self.ownership())
        self.assertIs(raised.exception, original)
        cleanup.assert_called_once_with(self.ownership())

    def test_original_test_failure_survives_additional_cleanup_failure(self):
        original = subprocess.CalledProcessError(1, ["flutter", "test"])
        with patch.object(RUNNER.subprocess, "run", side_effect=original), \
                patch.object(RUNNER, "cleanup_owned_fixture", side_effect=RuntimeError("synthetic cleanup error")), \
                patch("sys.stderr", new=io.StringIO()), \
                self.assertRaises(subprocess.CalledProcessError) as raised:
            RUNNER.run_owned_test(Path("/synthetic/app"), self.ownership())
        self.assertIs(raised.exception, original)
        self.assertIn("synthetic cleanup error", original.__notes__[0])

    def test_cleanup_failure_fails_an_otherwise_passing_run(self):
        with patch.object(RUNNER.subprocess, "run"), \
                patch.object(RUNNER, "cleanup_owned_fixture", side_effect=RuntimeError("synthetic cleanup error")), \
                self.assertRaisesRegex(RuntimeError, "synthetic cleanup error"):
            RUNNER.run_owned_test(Path("/synthetic/app"), self.ownership())


if __name__ == "__main__":
    unittest.main()
