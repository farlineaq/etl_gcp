import inspect
import os
import sys
import zipfile
from pathlib import Path
from typing import Dict, List
from dataclasses import dataclass, field


@dataclass
class SQLScript:
    """
    Represents an SQL script with a name and its content.

    Attributes:
        name (str): The name of the SQL script.
        content (str): The actual SQL query content of the script. This attribute is excluded from
                       the representation and comparison of the class instances.
    """
    name: str
    content: str = field(repr=False, compare=False)


class SQLScriptsLoader:
    """
    Loads SQL scripts from a specified directory or Python package.

    This class is responsible for discovering and loading SQL scripts contained within a given
    directory or a Python package. It supports loading from zipped packages and normal directory
    structures, making it versatile for different deployment scenarios.

    Attributes:
        _path_to_flows (str): The resolved filesystem path to the directory or package containing SQL scripts.
        _scripts (Dict[str, List[SQLScript]]): A dictionary mapping directory names to lists of `SQLScript` instances.
    """

    def __init__(self, path_to_flows: str | object):
        """
        Initializes the SQLScriptsLoader with a path to the directory or package containing SQL scripts.

        Args:
            path_to_flows (str | object): The filesystem path or Python package object where SQL scripts are located.
        """
        self._path_to_flows: str = self._get_working_path(path_to_flows)
        self._scripts: Dict[str, List[SQLScript]] = {}

    @property
    def scripts(self) -> Dict[str, List[SQLScript]]:
        """
        Returns the loaded SQL scripts.

        Returns:
            Dict[str, List[SQLScript]]: A dictionary mapping directory names to lists of `SQLScript` instances.
        """
        return self._scripts

    def _get_working_path(self, path_to_flows: str) -> str:
        """
        Resolves the working directory path for a given path to flows.

        This method supports resolving paths from both filesystem directories and zipped Python packages,
        ensuring compatibility with various deployment scenarios.

        Args:
            path_to_flows (str): The initial path or package object provided for loading scripts.

        Returns:
            str: The resolved working directory path.
        """
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
    def _handle_zip_file(zip_path: str, sub_path: str) -> str:
        """
        Extracts a zipped file to the working directory and returns the path to the extracted sub-path.

        Args:
            zip_path (str): The path to the zip file.
            sub_path (str): The sub-path within the zip file to extract and resolve.

        Returns:
            str: The filesystem path to the extracted sub-path.
        """
        working_directory = os.getcwd()
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(working_directory)
        base_dir = os.path.join(working_directory, sub_path.split('/')[0])
        if base_dir not in sys.path:
            sys.path.insert(0, base_dir)
        return os.path.join(working_directory, sub_path)

    @staticmethod
    def _get_sql_script_from_file(file_path: Path) -> str:
        """
        Reads and returns the content of an SQL script file.

        Args:
            file_path (Path): The filesystem path to the SQL script file.

        Returns:
            str: The content of the SQL script.
        """
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()

    def load_sql_scripts(self) -> Dict[str, List[SQLScript]]:
        """
        Discovers and loads SQL scripts from the specified path.

        This method walks through the directory structure starting at `_path_to_flows`, loading all
        SQL scripts it finds. The scripts are organized in a dictionary by their directory names.

        Returns:
            Dict[str, List[SQLScript]]: A dictionary mapping directory names to lists of `SQLScript` instances.
        """
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
