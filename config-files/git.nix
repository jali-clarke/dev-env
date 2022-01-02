{ pkgs, home }:
pkgs.writeTextDir "${home}/.config/git/config" ''
  [user]
    email = jinnah.ali-clarke@outlook.com
    name = jali-clarke
  [pull]
    rebase = false
  [init]
    defaultBranch = master
  [alias]
    autosquash = !GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash
    branchc = branch --show-current
    brancho = !echo origin/$(git branchc)
    diffc = !git diff $1~1
    diffo = !git diff $(git brancho)
    fixup = commit --fixup
    fixupa = commit -a --fixup
    pushf = push --force-with-lease
    pushuo = !git push -u origin $(git branchc)
''
