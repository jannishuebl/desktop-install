#!/bin/bash

bold=`tput bold`
normal=`tput sgr0`

function echo_headline {
  size=${#1}
  v=$(printf "%-${size}s" "=")
  echo "${v// /=}"
  echo "${bold}$1${normal}"
  echo "${v// /=}"
}

function echo_bold {
  echo "${bold}$1${normal}"
}

function install_essentials() {
  echo_headline "INSTALLING ESSENTIALS"


  echo_bold "update apt cache"
  apt-get update

  echo_bold "install basic stuff"
  apt-get install -q -y build-essential checkinstall curl git xclip tree gparted nfs-common portmap pavucontrol screen

  echo_bold "install network manager vpn plugins"
  apt-get install -q -y network-manager-openvpn network-manager-pptp network-manager-vpnc

  echo_bold "install instant messanger"
  apt-get install -q -y irssi


  echo_bold "install webbrowsers"
  apt-get install -q -y firefox chromium-browser

  echo_bold "install codecs"
  apt-get install -q -y libxvidcore4 gstreamer0.10-plugins-base gstreamer0.10-plugins-good gstreamer0.10-plugins-ugly gstreamer0.10-plugins-bad gstreamer0.10-plugins-bad-multiverse gstreamer0.10-ffmpeg gstreamer0.10-alsa gstreamer0.10-fluendo-mp3


  echo_bold "install musicplayer"
  apt-get install -q -y gmusicbrowser

  echo_bold "install desktop recording tool"
  apt-get install -q -y gtk-recordmydesktop

  echo_bold "install password depot: keepassx"
  apt-get install -q -y keepassx
}

function install_rails() {
  echo_headline "INSTALLING RAILS"

  apt-get -y install gawk libgdbm-dev pkg-config libffi-dev build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev autoconf libc6-dev libncurses5-dev automake libtool bison subversion python postgresql postgresql-contrib libpq-dev redis-server
  curl -L https://get.rvm.io | sudo -u "${SUDO_USER}" -H bash -s stable --rails
  su -l "${SUDO_USER}" -c "source \"${homedir}/.rvm/scripts/rvm\""
}



function install_dotfiles() {
  echo_headline "INSTALLING VIM, ZSH, AND DOTFILES"

  echo_bold "update apt cache"
  apt-get update

  apt-get install -q -y stow zsh libncurses5-dev libgnome2-dev libgnomeui-dev libgtk2.0-dev libatk1.0-dev libbonoboui2-dev libcairo2-dev libx11-dev libxpm-dev libxt-dev mercurial git build-essential curl

  hg clone https://vim.googlecode.com/hg/ /tmp/vim
  (cd /tmp/vim/src; ./configure --with-features=huge --enable-gui=gnome2 --enable-rubyinterp --enable-pythoninterp)
  make -C /tmp/vim/src
  make -C /tmp/vim/src install
  rm -rf /tmp/vim

  curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sudo -u "${SUDO_USER}" -H sh
  curl -L https://raw.github.com/maksimr/dotfiles/master/gnome-terminal-themes/molokai.sh | sudo -u "${SUDO_USER}" -H sh

  rm "${homedir}/.zshrc"
  sudo -u "${SUDO_USER}" -H git clone https://github.com/jannishuebl/dotfiles.git "${homedir}/dotfiles"
  ln -s "${homedir}/dotfiles/zsh/flopska.zsh-theme" "${homedir}/.oh-my-zsh/themes/flopska.zsh-theme"
  ln -s "${homedir}/dotfiles/zsh/zshrc" "${homedir}/.zshrc"

  (
  cd ${homedir}/dotfiles
  git submodule init
  git submodule update

  stow --target=$homedir vim
  )

  git clone https://github.com/jannishuebl/dotvim.git
  
  ln -sfn dotvim .vim
  ln -sfn dotvim/vimrc .vimrc
  cd .vim; make install

  chsh $SUDO_USER -s /bin/zsh
}

function install_fixubuntu() {
  echo_headline "FIXING UBUNTU"

  wget -qO- https://raw2.github.com/micahflee/fixubuntu/master/fixubuntu.sh | sudo -u "${SUDO_USER}" -H sh
}

function install_heroku_toolbelt() {
  echo_headline "INSTALLING HEROKU-TOOLBELT"

  wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh
}

function install_nodejs() {
  echo_headline "INSTALLING NODE.JS"

  apt-get install python-software-properties
  apt-add-repository -y ppa:chris-lea/node.js
  apt-get update -q -y
  apt-get install nodejs -q -y
  apt-get install npm -q -y
  npm install -g karma
  ln -s /usr/bin/nodejs /usr/bin/node &>/dev/null
}

function install_chef() {
  echo_headline "INSTALLING CHEF CLIENT"

  curl -L https://www.opscode.com/chef/install.sh | sudo bash
}

function install_selected() {

  selected_items=$1

  if [[ ${selected_items[@]} =~ "essentials" ]]; then
    install_essentials
  fi
  
  if [[ ${selected_items[@]} =~ "rails" ]]; then
    install_rails
  fi
  
  if [[ ${selected_items[@]} =~ "ansible" ]]; then
    install_ansible
  fi
  
  if [[ ${selected_items[@]} =~ "vagrant" ]]; then
    install_vagrant
  fi

  if [[ ${selected_items[@]} =~ "dotfiles" ]]; then
    install_dotfiles
  fi

  if [[ ${selected_items[@]} =~ "fixubuntu" ]]; then
    install_fixubuntu
  fi

  if [[ ${selected_items[@]} =~ "heroku-toolbelt" ]]; then
    install_heroku_toolbelt
  fi

  if [[ ${selected_items[@]} =~ "nodejs" ]]; then
    install_nodejs
  fi

  if [[ ${selected_items[@]} =~ "chef" ]]; then
    install_chef
  fi
}

function usage {
  echo "usage: install.sh [[-s | --silent] [--dotfiles] | [-h | --help]]"
}

# Start of program

if [[ $USER != "root" ]]; then
  echo "You need to run this as root."
  exit 1
fi

homedir=`eval echo ~$SUDO_USER`

silent=
while [ "$1" != "" ]; do
  case $1 in
    ( -s | --silent )       silent=1
                            ;;
    ( --dotfiles )          dotfiles=1
                            ;;
    ( -h | --help )         usage
                            exit
  esac
  shift
done

if [ "$silent" = "1" ]; then
  echo_headline "Silent Mode"
  if [ "$dotfiles" = "1" ]; then
    install_dotfiles
  else
    install_selected "essentials rails ansible vagrant dotfiles fixubuntu heroku-toolbelt nodejs chef"
  fi
else
  selected_items=$(whiptail --separate-output --checklist "What do you want to install?" 15 60 9 \
  essentials "Essentials" on \
  rails "Rails" on \
  ansible "Ansible" on \
  vagrant "Vagrant" on \
  dotfiles "Vim, Zsh, Dotfiles" on \
  fixubuntu "Fix ubuntu" on \
  heroku-toolbelt "Heroku Toolbelt" on \
  nodejs "node.js, npm, karma" on \
  chef "Chef Client" on 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    install_selected "$selected_items"
  else
    echo "Cancelled."
  fi
fi
