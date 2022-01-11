{ pkgs, ... }: {
  dotfiles.enableAll = true;

  programs.git = {
    userName = "jali-clarke";
    userEmail = "jinnah.ali-clarke@outlook.com";
  };

  programs.vscode.userSettings = {
    "explorer.openEditors.visible" = 0;
    "files.eol" = "\n";
    "terminal.integrated.shell.linux" = "${pkgs.zsh}/bin/zsh";
    "terminal.integrated.shellArgs.linux" = [
      "--interactive"
      "--login"
    ];
    "workbench.colorTheme" = "Default Dark+";
    "workbench.startupEditor" = "none";
  };
}
