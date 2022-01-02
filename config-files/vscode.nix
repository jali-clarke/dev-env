{ pkgs, home }:
pkgs.writeTextDir "${home}/.local/share/code-server/User/settings.json" ''
  {
    "files.autoSave": "afterDelay",
    "workbench.editor.enablePreview": false,
    "explorer.openEditors.visible": 0,
    "files.eol": "\n",
    "terminal.integrated.shell.linux": "${pkgs.bashInteractive}/bin/bash",
    "terminal.integrated.shellArgs.linux": [
      "--login"
    ],
    "workbench.colorTheme": "Default Dark+",
    "workbench.startupEditor": "none",
    "[haskell]": {
      "editor.tabSize": 2
    },
    "[nix]": {
      "editor.tabSize": 2
    }
  }
''