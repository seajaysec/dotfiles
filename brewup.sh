#!/bin/bash
PATH="/usr/local/bin:/usr/local/sbin:/Users/${USER}/.local/bin:/usr/bin:/usr/sbin:/bin:/sbin"

## M1 Brew PATH Fix
if [ $(arch) = "arm64" ]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

## checks if mas, terminal-notifier are installed, if not will promt to install
if [ -z $(which mas) ]; then
  brew install mas 2>/dev/null
fi

DATE=$(date '+%Y%m%d.%H%M')
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
reset=$(tput sgr0)
brewFileName="Brewfile.${HOSTNAME}"

## Sets Working Dir as Real A Script Location
if [ -z $(which realpath) ]; then
  brew install coreutils
fi
cd $(dirname "$(realpath "$0")")

git pull 2>&1

## Brew packages update and cleanup
echo "${yellow}==>${reset} Running Updates..."
brew update 2>&1
brew outdated 2>&1
brew upgrade 2>&1
brew cleanup --prune=1 -s 2>&1
echo "${green}==>${reset} Finished Updates"

## Creating Dump File with hostname
brew bundle dump --force --file="./${brewFileName}"

## Pushing to Repo
git add . 2>&1
git commit -m "${DATE}_update" 2>&1
git push 2>&1

echo "${green}==>${reset} All Updates & Cleanups Finished"
