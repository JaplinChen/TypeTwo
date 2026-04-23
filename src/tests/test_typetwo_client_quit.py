import sys
import unittest
import importlib
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


class TypeTwoClientQuitTest(unittest.TestCase):
    def _load_module(self):
        with patch.dict(
            sys.modules,
            {
                "pystray": MagicMock(),
                "PIL": MagicMock(),
                "PIL.Image": MagicMock(),
            },
        ):
            if "typetwo_client" in sys.modules:
                del sys.modules["typetwo_client"]
            return importlib.import_module("typetwo_client")

    def test_quit_argument_signals_existing_instance(self):
        typetwo_client = self._load_module()
        with patch.object(sys, "argv", ["TypeTwo.exe", "--quit"]):
            with patch.object(typetwo_client, "_signal_running_instance_to_quit", return_value=True) as signal_quit:
                with patch.object(typetwo_client, "_acquire_single_instance") as acquire_single_instance:
                    typetwo_client.main()

        signal_quit.assert_called_once_with()
        acquire_single_instance.assert_not_called()

    def test_quit_argument_exits_cleanly_when_no_instance_found(self):
        typetwo_client = self._load_module()
        with patch.object(sys, "argv", ["TypeTwo.exe", "--quit"]):
            with patch.object(typetwo_client, "_signal_running_instance_to_quit", return_value=False) as signal_quit:
                with patch.object(typetwo_client, "_signal_running_instance_to_quit_via_bridge", return_value=False) as bridge_quit:
                    with patch.object(typetwo_client, "_acquire_single_instance") as acquire_single_instance:
                        typetwo_client.main()

        signal_quit.assert_called_once_with()
        bridge_quit.assert_called_once_with()
        acquire_single_instance.assert_not_called()

    def test_quit_argument_falls_back_to_bridge_quit(self):
        typetwo_client = self._load_module()
        with patch.object(sys, "argv", ["TypeTwo.exe", "--quit"]):
            with patch.object(typetwo_client, "_signal_running_instance_to_quit", return_value=False) as signal_quit:
                with patch.object(typetwo_client, "_signal_running_instance_to_quit_via_bridge", return_value=True) as bridge_quit:
                    with patch.object(typetwo_client, "_acquire_single_instance") as acquire_single_instance:
                        typetwo_client.main()

        signal_quit.assert_called_once_with()
        bridge_quit.assert_called_once_with()
        acquire_single_instance.assert_not_called()


if __name__ == "__main__":
    unittest.main()
