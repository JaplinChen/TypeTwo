from pathlib import Path
import unittest


class BuildAllScriptTest(unittest.TestCase):
    def test_python_build_uses_onedir_runtime_layout(self):
        script = Path(__file__).resolve().parents[2] / "release" / "build_client_exe.bat"
        text = script.read_text(encoding="utf-8")

        self.assertIn("--onedir", text)
        self.assertIn("--contents-directory _internal", text)
        self.assertIn(r"Build complete: src\dist\TypeTwo\TypeTwo.exe (+ _internal\)", text)

    def test_build_all_syncs_default_config_into_package(self):
        script = Path(__file__).resolve().parents[2] / "build_all.bat"
        text = script.read_text(encoding="utf-8")

        self.assertIn(
            r"set DEFAULT_CFG=typetwo_flutter\assets\translator_config.json",
            text,
        )
        self.assertIn(
            r"copy /Y %DEFAULT_CFG% package\translator_config.json",
            text,
        )
        self.assertIn(
            r"del /Q package\*.dll >nul 2>nul",
            text,
        )
        self.assertIn(
            r"del /Q package\typetwo.log >nul 2>nul",
            text,
        )
        self.assertIn(
            r"set INSTALL_SCRIPT=installer\install_ollama_and_model.bat",
            text,
        )
        self.assertIn(
            r"copy /Y %INSTALL_SCRIPT% package\install_ollama_and_model.bat",
            text,
        )

    def test_installer_uses_asset_default_config_and_onedir_runtime(self):
        script = Path(__file__).resolve().parents[2] / "installer" / "typetwo.iss"
        text = script.read_text(encoding="utf-8")

        self.assertIn(
            r'Source: "..\typetwo_flutter\assets\translator_config.json"; DestDir: "{app}"; DestName: "translator_config.json"; Flags: ignoreversion onlyifdoesntexist',
            text,
        )
        self.assertIn(
            r'Source: "..\package\install_ollama_and_model.bat"; DestDir: "{app}"; Flags: ignoreversion',
            text,
        )

    def test_release_workflow_runs_tests_and_smoke_test(self):
        workflow = (
            Path(__file__).resolve().parents[2]
            / ".github"
            / "workflows"
            / "release.yml"
        )
        text = workflow.read_text(encoding="utf-8")

        self.assertIn("flutter analyze", text)
        self.assertIn("flutter test", text)
        self.assertIn(
            'python -m unittest discover -s src/tests -p "test_*.py" -v',
            text,
        )
        self.assertIn(r'.\scripts\package_smoke_test.ps1 -StrictCleanup', text)

    def test_package_smoke_test_checks_single_instance_and_cleanup_diagnostics(self):
        script = (
            Path(__file__).resolve().parents[2]
            / "scripts"
            / "package_smoke_test.ps1"
        )
        text = script.read_text(encoding="utf-8")

        self.assertIn("function Get-NamedProcesses", text)
        self.assertIn("function Format-ProcessSummary", text)
        self.assertIn("function Stop-NamedProcesses", text)
        self.assertIn("function Start-SmokeProcess", text)
        self.assertIn("Failed to start $(Split-Path -Leaf $Path)", text)
        self.assertIn("$Name second launch should not create another process.", text)
        self.assertIn("TypeTwoUI.exe second launch should not create another process.", text)
        self.assertIn("RemainingProcesses", text)
        self.assertIn("passed startup and single-instance checks but cleanup failed", text)


if __name__ == "__main__":
    unittest.main()
