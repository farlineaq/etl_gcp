import inspect
import os
import sys
import zipfile
from pathlib import Path
from typing import Dict, List
from dataclasses import dataclass, field


@dataclass
class SQLScript:
    name: str
    content: str = field(repr=False, compare=False)


class SQLScriptsLoader:
    def __init__(self, path_to_flows: str | object):
        self._path_to_flows: str = self._get_working_path(path_to_flows)
        self._scripts: Dict[str, List[SQLScript]] = {}

    @property
    def scripts(self) -> Dict[str, List[SQLScript]]:
        return self._scripts

    def _get_working_path(self, path_to_flows: str) -> str:
        tmp_path = path_to_flows.__path__[0] if inspect.ismodule(path_to_flows) else path_to_flows
        path_parts = tmp_path.split("/")
        for i in range(len(path_parts)):
            partial_path = "/".join(path_parts[:i + 1])
            if zipfile.is_zipfile(partial_path):
                result = self._handle_zip_file(partial_path, "/".join(path_parts[i + 1:]))
                break
        else:
            result = tmp_path
        return result

    @staticmethod
    def _handle_zip_file(zip_path: str, sub_path: str):
        working_directory = os.getcwd()
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(working_directory)
        base_dir = os.path.join(working_directory, sub_path.split('/')[0])
        if base_dir not in sys.path:
            sys.path.insert(0, base_dir)
        return os.path.join(working_directory, sub_path)

    @staticmethod
    def _get_sql_script_from_file(file_path: Path) -> str:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()

    def load_sql_scripts(self) -> Dict[str, List[SQLScript]]:
        for root, dirs, files in os.walk(self._path_to_flows):
            for file_name in files:
                if file_name.endswith('.sql'):
                    directory = Path(root).name
                    script_path = Path(root) / file_name
                    script_name = Path(file_name).stem
                    script_content = self._get_sql_script_from_file(script_path)

                    if directory not in self._scripts:
                        self._scripts[directory] = []
                    self._scripts[directory].append(SQLScript(name=script_name, content=script_content))

        return self._scripts
