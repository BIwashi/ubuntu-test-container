# ubuntuベース
FROM ubuntu

# Docker環境下でのPATH設定
ENV PATH /usr/local/bin:$PATH

# ロケールを日本語UTF-8に設定
# これによりDocker環境下で日本語入力が可能となる 
RUN apt-get update \
    && apt-get install -y locales \
    && locale-gen ja_JP.UTF-8
# ロケール環境変数の設定
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

# aptコンテナのupdate&upgrade
RUN apt-get update && apt-get upgrade -y

# ubuntu 18.0.4で発生する問題回避 timezone 選択
RUN apt-get install -y tzdata
ENV TZ=Asia/Tokyo

# 色々なものをインストール
RUN apt-get install -y git
RUN apt-get install -y vim
RUN apt-get install -y wget
RUN apt-get install -y curl
RUN apt-get install -y build-essential 
RUN apt-get install -y file
RUN apt-get install -y sudo


# GUIをホストで実行するための環境変数
ENV DISPLAY host.docker.internal:0.0


# 接続確認
RUN apt-get install -y x11-apps 
# 接続できていれば、$xeyes で目が表示されるはず

# ubuntuのdesktop環境を入れる
RUN apt-get install -y ubuntu-desktop
# RUN nautilus


#　linuxbrewの「Alternative Installation」を実行
RUN git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew && \
    mkdir /home/linuxbrew/.linuxbrew/bin && \
    ln -s /home/linuxbrew/.linuxbrew/Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin && \
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)


#----------------追加----------------#

####################################
#
# ユーザー設定
# 
####################################

# ユーザーとホームディレクトリの環境変数設定
ENV USER new
ENV PW password
ENV HOME /home/${USER}
ENV SHELL /bin/bash

# 一般ユーザーアカウント追加
RUN    useradd -m ${USER} && \
    # 一般ユーザーにsudo権限を付与
    gpasswd -a ${USER} sudo && \
    # 一般ユーザーのパスワードを設定
    echo "${USER}:${PW}" | chpasswd 

# 以降のRUN/CMDを実行するユーザー
USER ${USER}

# 以降の作業ディレクトリを指定
WORKDIR ${HOME}

####################################
#
# linux-brewのinstall
# 
####################################

# Linuxbrew関連のフォルダ作成
RUN echo ${PW} | sudo -S mkdir -p /home/linuxbrew/.linuxbrew/etc \
    /home/linuxbrew/.linuxbrew/include \
    /home/linuxbrew/.linuxbrew/lib \
    /home/linuxbrew/.linuxbrew/opt \
    /home/linuxbrew/.linuxbrew/sbin \
    /home/linuxbrew/.linuxbrew/share \
    /home/linuxbrew/.linuxbrew/var/homebrew/linked \
    /home/linuxbrew/.linuxbrew/var/homebrew/locks \
    /home/linuxbrew/.linuxbrew/Cellar && \
    # 権限変更
    echo ${PW} | sudo -S chown -R ${USER} /home/linuxbrew/.linuxbrew/etc \
    /home/linuxbrew/.linuxbrew/include \
    /home/linuxbrew/.linuxbrew/lib \
    /home/linuxbrew/.linuxbrew/opt \
    /home/linuxbrew/.linuxbrew/sbin \
    /home/linuxbrew/.linuxbrew/share \
    /home/linuxbrew/.linuxbrew/var/homebrew/linked \
    /home/linuxbrew/.linuxbrew/Cellar \
    /home/linuxbrew/.linuxbrew/Homebrew \
    /home/linuxbrew/.linuxbrew/bin \
    /home/linuxbrew/.linuxbrew/var/homebrew/locks && \
    # パスの設定
    echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> .bash_profile && \
    # パスの反映
    . ~/.bash_profile && \
    # brew doctorの実行
    brew doctor

# echoのだとダメだったのでENVに変更
ENV PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

RUN . ~/.bash_profile

####################################
#
# zshの設定
# 
####################################

RUN brew install zsh
USER root
RUN which zsh | sudo tee -a /etc/shells
RUN chsh -s /home/linuxbrew/.linuxbrew/bin/zsh

# zshにもPATHを通す
ENV PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# シェル変更
ENV SHELL /home/linuxbrew/.linuxbrew/bin


####################################
#
# dotfiles
# 
####################################

RUN git clone --recursive https://github.com/BIwashi/dotfiles.git

# 以降の作業ディレクトリを指定
WORKDIR $HOME/dotfiles

# dotfile setup
RUN ./setup.sh
RUN ./install_zprezto.sh

# dotfiles用の諸々ツール
RUN brew install exa
RUN brew install fzf
RUN brew install bat

####################################

# キーバインド設定
RUN $(brew --prefix)/opt/fzf/install

RUN apt-get autoremove -y
WORKDIR $HOME

# ユーザーを戻す
USER ${USER}