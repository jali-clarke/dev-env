baseModule:
{ pkgs, ... }: {
  imports = [ baseModule ];

  programs.git = {
    userName = "jali-clarke";
    userEmail = "jinnah.ali-clarke@outlook.com";
  };

  programs.vscode.userSettings = {
    "explorer.openEditors.visible" = 0;
    "files.eol" = "\n";
    "terminal.integrated.shell.linux" = "${pkgs.bashInteractive}/bin/bash";
    "terminal.integrated.shellArgs.linux" = [
      "--login"
    ];
    "workbench.colorTheme" = "Default Dark+";
    "workbench.startupEditor" = "none";
  };
}
