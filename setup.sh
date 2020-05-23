#! /bin/bash
sudo apt install zsh
cp .screenrc ~
cp -r .vim ~
cp .vimrc ~
cp .zshrc ~
git clone https://github.com/zplug/zplug ~/.zplug
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config --global user.name "4180122"
git config --global user.email "al.amirkh@gmail.com"
