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
            r"set TRAY_ICON=src\tray_icon.ico",
            text,
        )
        self.assertIn(
            r"set UI_LOCALE=%RELEASE%\ui_locale.txt",
            text,
        )
        self.assertIn(
            r"set INSTALL_SCRIPT=installer\install_ollama_and_model.bat",
            text,
        )
        self.assertIn(
            r"copy /Y %TRAY_ICON% package\tray_icon.ico",
            text,
        )
        self.assertIn(
            r"copy /Y %UI_LOCALE% package\ui_locale.txt",
            text,
        )
        self.assertIn(
            r"copy /Y %INSTALL_SCRIPT% package\install_ollama_and_model.bat",
            text,
        )
        self.assertIn(
            r"xcopy /Y /E /I src\dist\TypeTwo\* package\ >nul",
            text,
        )

    def test_installer_uses_asset_default_config_and_onedir_runtime(self):
        script = Path(__file__).resolve().parents[2] / "installer" / "typetwo.iss"
        text = script.read_text(encoding="utf-8")

        self.assertIn(
            r'Source: "..\package\_internal\*"; DestDir: "{app}\_internal"; Flags: ignoreversion recursesubdirs createallsubdirs',
            text,
        )
        self.assertIn(
            r'Source: "..\typetwo_flutter\assets\translator_config.json"; DestDir: "{app}"; DestName: "translator_config.json"; Flags: ignoreversion onlyifdoesntexist',
            text,
        )
        self.assertIn(
            r'Source: "..\package\tray_icon.ico"; DestDir: "{app}"; Flags: ignoreversion',
            text,
        )
        self.assertIn(
            r'Source: "..\package\ui_locale.txt"; DestDir: "{app}"; Flags: ignoreversion',
            text,
        )
        self.assertIn(
            r'Source: "..\package\install_ollama_and_model.bat"; DestDir: "{app}"; Flags: ignoreversion',
            text,
        )

if __name__ == "__main__":
    unittest.main()
