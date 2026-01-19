######################################################################
#           Cross-platform zshrc (Linux & macOS)
#           Based on bodhi.zazen's zshrc
######################################################################

# Detect OS
case "$(uname -s)" in
    Darwin) OS="macos" ;;
    Linux)  OS="linux" ;;
    *)      OS="unknown" ;;
esac

######################################################################
#                       Shell Options
######################################################################

setopt INC_APPEND_HISTORY SHARE_HISTORY
setopt APPEND_HISTORY
setopt CORRECT
setopt MENUCOMPLETE
setopt ALL_EXPORT

setopt notify globdots correct pushdtohome cdablevars autolist
setopt correctall autocd recexact longlistjobs
setopt autoresume histignoredups pushdsilent 
setopt autopushd pushdminus extendedglob rcquotes mailwarning
unsetopt bgnice autoparamslash

# Autoload zsh modules when they are referenced
zmodload -a zsh/stat stat
zmodload -a zsh/zpty zpty
zmodload -a zsh/zprof zprof
zmodload -ap zsh/mapfile mapfile

######################################################################
#                       Environment Variables
######################################################################

# Base PATH - start fresh and build up
if [[ "$OS" == "macos" ]]; then
    # macOS: use path_helper for system paths
    if [[ -x /usr/libexec/path_helper ]]; then
        eval "$(/usr/libexec/path_helper -s)"
    fi
    # Homebrew
    if [[ -d /opt/homebrew/bin ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d /usr/local/bin ]]; then
        # Intel Mac Homebrew location
        export PATH="/usr/local/bin:$PATH"
    fi
else
    # Linux: standard paths
    PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
fi

# Add user bin directories if they exist
[[ -d "$HOME/bin" ]] && PATH="$PATH:$HOME/bin"
[[ -d "$HOME/.local/bin" ]] && PATH="$PATH:$HOME/.local/bin"

# History
HISTFILE="$HOME/.zhistory"
HISTSIZE=10000
SAVEHIST=10000

# Hostname
HOSTNAME="$(hostname)"

# Editors and pagers
PAGER='less'
command -v most &>/dev/null && PAGER='most'
EDITOR='vim'

# Locale
LC_ALL='en_US.UTF-8'
LANG='en_US.UTF-8'
LC_CTYPE='en_US.UTF-8'

# Java (if available)
if [[ "$OS" == "macos" ]]; then
    [[ -x /usr/libexec/java_home ]] && export JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null)" || true
elif [[ -d /usr/lib/jvm/default-java ]]; then
    export JAVA_HOME="/usr/lib/jvm/default-java"
fi

######################################################################
#                       Colors
######################################################################

autoload colors zsh/terminfo
if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
fi

for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
    eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
done
PR_NO_COLOR="%{$terminfo[sgr0]%}"

# ANSI color codes for echo
BLACK='\e[0;30m'
BLUE='\e[0;34m'
GREEN='\e[0;32m'
CYAN='\e[0;36m'
RED='\e[0;31m'
PURPLE='\e[0;35m'
BROWN='\e[0;33m'
LIGHTGRAY='\e[0;37m'
DARKGRAY='\e[1;30m'
LIGHTBLUE='\e[1;34m'
LIGHTGREEN='\e[1;32m'
LIGHTCYAN='\e[1;36m'
LIGHTRED='\e[1;31m'
LIGHTPURPLE='\e[1;35m'
YELLOW='\e[1;33m'
LIGHTYELLOW='\e[0;33m'
WHITE='\e[1;37m'
NC='\e[0m'

######################################################################
#                       Prompt
######################################################################

# Git branch for prompt
function git_branch_name() {
    git branch 2>/dev/null | sed -n -e 's/^\* \(.*\)/[\1]/p'
}

# Enable prompt substitution
setopt PROMPT_SUBST

prompt() {
    PS1="$PR_LIGHT_GREEN%n$PR_GREY@$PR_BLUE%m$PR_GREY:$PR_LIGHT_RED%2c$PR_CYAN \$(git_branch_name)$PR_NO_COLOR%(!.#.$) "
    RPS1="$PR_LIGHT_YELLOW%D{%m/%d/%y %l:%M %p}$PR_NO_COLOR"
}
precmd_functions+=(prompt)

# Mutt editor
if [[ -n "$SSH_TTY" ]]; then
    MUTT_EDITOR=vim
else
    MUTT_EDITOR=vim
fi

unsetopt ALL_EXPORT

######################################################################
#                       Aliases
######################################################################

# ls aliases - cross-platform
if [[ "$OS" == "macos" ]]; then
    alias ls='ls -cG'
    alias la='ls -acG'
    alias ll='ls -lahG'
    alias lsd='ls -d */'
    alias lsg='ls -G | g'
    alias lag='ls -aG | g'
    alias llg='ls -lahG | g'
else
    alias ls='ls -c --color=auto'
    alias la='ls -ac --color=auto'
    alias ll='ls -lah --color=auto'
    alias lsd='ls -d */'
    alias lsg='ls --color=auto | g'
    alias lag='ls -a --color=auto | g'
    alias llg='ls -lah --color=auto | g'
fi

# Colorize grep
alias g="grep --color=always"
alias gi="grep -i --color=always"

# Confirm before overwrite
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

# Force operations (override -i)
alias rmf='rm -Rfv'
alias cpf='\cp -v'
alias mvf='\mv -v'

# No clobber
set -o noclobber # Override with >|

# Sysadmin - cross-platform
if [[ "$OS" == "macos" ]]; then
    alias psa='ps aux'
    alias psg='ps aux | grep'
else
    alias psa='ps auxf'
    alias psg='ps aux | grep'
fi

alias date='echo -ne "${LIGHTBLUE}"; \date "+%A %B %d, %Y %l:%M %p %Z"'
alias cal='echo -e "${CYAN}"; \cal'
alias hist='history | g $1'
alias du='du -sh'
alias dul='\du -h | less'
alias df='df -h'
alias nano='nano -w'
alias nanob='nano -w -B'

# Package manager aliases
if [[ "$OS" == "linux" ]]; then
    if command -v apt &>/dev/null; then
        alias apti='sudo apt install'
        alias aptu='sudo apt update'
        alias aptg='sudo apt upgrade'
    elif command -v aptitude &>/dev/null; then
        alias apti='sudo aptitude install'
        alias aptu='sudo aptitude update'
        alias aptg='sudo aptitude upgrade'
    fi
elif [[ "$OS" == "macos" ]] && command -v brew &>/dev/null; then
    alias brews='brew search'
    alias brewi='brew install'
    alias brewu='brew update && brew upgrade'
fi

# Git
alias gitl='git log --all --decorate --oneline --graph'

# Fun aliases (optional - only work if commands are installed)
if command -v display-dhammapada &>/dev/null; then
    alias buddha='echo -e "${GREEN}"; clear ; display-dhammapada; echo -e "${CYAN}  Peace be with you $USER" ; echo'
fi

######################################################################
#                       Functions
######################################################################

# Extract files from any archive
function ex() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar)                tar xf "$1"      ;;
            *.tar.bz2 | *.tbz2)   tar xjvf "$1"    ;;
            *.tar.gz | *.tgz)     tar xzvf "$1"    ;;
            *.tar.xz | *.txz)     tar xJvf "$1"    ;;
            *.bz2)                bunzip2 "$1"     ;;
            *.rar)                unrar x "$1"     ;;
            *.gz)                 gunzip "$1"      ;;
            *.zip)                unzip "$1"       ;;
            *.Z)                  uncompress "$1"  ;;
            *.7z)                 7z x "$1"        ;;
            *)   echo "'$1' cannot be extracted via ex()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Background daemon launcher
function daemon() {
    (exec "$@" &>/dev/null &)
}

######################################################################
#                       Terminal Setup
######################################################################

# Only run interactive setup for non-dumb terminals
if [[ "$TERM" != "dumb" ]]; then
    # Display calendar on startup (3 months: previous, current, next)
    clear
    if [[ "$OS" == "macos" ]]; then
        cal -A 1 -B 1 2>/dev/null
    else
        cal -3 2>/dev/null
    fi

    # Optional fortune display
    if command -v fortune &>/dev/null; then
        if [[ "$OS" == "macos" ]]; then
            # macOS: fortune is typically in /usr/local/bin or /opt/homebrew/bin
            echo -e "${GREEN}"
            fortune 2>/dev/null || true
        else
            # Linux: fortune is typically in /usr/games/fortune
            echo -e "${GREEN}"
            /usr/games/fortune 2>/dev/null || fortune 2>/dev/null || true
        fi
    fi

    # Set terminal title
    host=$(uname -n)
    if [[ "$TERM" == "xterm" || "$TERM" == "xterm-256color" ]]; then
        print -Pn "\e]2;${host}\a\e]1;${host}\a"
    fi
fi

# X resources (Linux only)
if [[ "$OS" == "linux" && -e "$HOME/.Xresources" && -n "$DISPLAY" ]]; then
    command -v xrdb &>/dev/null && xrdb -merge "$HOME/.Xresources"
fi

######################################################################
#                       Completion
######################################################################

autoload -U compinit
compinit

# Key bindings
bindkey "^?" backward-delete-char
bindkey '^[OH' beginning-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[F' end-of-line
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey "^r" history-incremental-search-backward
bindkey ' ' magic-space
bindkey '^I' complete-word

# Completion caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$HOME/.zsh/cache/$HOST"

# Completion styling
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/2 )) numeric )'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate
zstyle ':completion:*:expand:*' tag-order all-expansions

# Formatting
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Subscript completion
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Process completion - cross-platform
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
if [[ "$OS" == "macos" ]]; then
    zstyle ':completion:*:*:kill:*:processes' command 'ps -A -o pid,user,command'
    zstyle ':completion:*:processes-names' command 'ps -c -A -o command'
else
    zstyle ':completion:*:*:kill:*:processes' command 'ps --forest -A -o pid,user,cmd'
    zstyle ':completion:*:processes-names' command 'ps axho command'
fi

# Host completion from /etc/hosts
zstyle ':completion:*' hosts $(awk '/^[^#]/ {print $2 $3" "$4" "$5}' /etc/hosts 2>/dev/null | grep -v ip6- && grep "^#%" /etc/hosts 2>/dev/null | awk -F% '{print $2}')

# Ignore patterns
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~' '*?.old' '*?.pro'
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:*:users' ignored-patterns \
    adm apache bin daemon games gdm halt ident junkbust lp mail mailnull \
    named news nfsnobody nobody nscd ntp operator pcap postgres radvd \
    rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs avahi-autoipd \
    avahi backup messagebus beagleindex debian-tor dhcp dnsmasq fetchmail \
    firebird gnats haldaemon hplip irc klog list man cupsys postfix \
    proxy syslog www-data mldonkey sys snort _spotlight

# SSH/SCP completion
zstyle ':completion:*:scp:*' tag-order files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:scp:*' group-order files all-files users hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host users hosts-ipaddr
zstyle '*' single-ignored show

######################################################################
#                       FZF
######################################################################

if command -v fzf &>/dev/null; then
    if [[ "$OS" == "macos" ]]; then
        eval "$(fzf --zsh)"
    else
        [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
    fi
fi

######################################################################
#                       Zplug (Plugin Manager)
######################################################################

# Find zplug installation
if [[ "$OS" == "macos" ]] && command -v brew &>/dev/null; then
    ZPLUG_HOME="$(brew --prefix 2>/dev/null)/opt/zplug"
elif [[ -d "$HOME/.zplug" ]]; then
    ZPLUG_HOME="$HOME/.zplug"
fi

if [[ -n "$ZPLUG_HOME" && -f "$ZPLUG_HOME/init.zsh" ]]; then
    export ZPLUG_HOME
    source "$ZPLUG_HOME/init.zsh"
    
    # Plugins
    zplug 'wfxr/forgit'
    
    # Install missing plugins
    if ! zplug check --verbose; then
        printf "Install zplug plugins? [y/N]: "
        if read -q; then
            echo
            zplug install
        fi
    fi
    
    # Load plugins
    zplug load
fi

######################################################################
#                       SSH Agent
######################################################################

if [[ -z "$SSH_AUTH_SOCK" ]]; then
    RUNNING_AGENT="$(ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]')"
    if [[ "$RUNNING_AGENT" = "0" ]]; then
        ssh-agent -s &> "$HOME/.ssh/ssh-agent"
    fi
    if [[ -f "$HOME/.ssh/ssh-agent" ]]; then
        eval "$(cat "$HOME/.ssh/ssh-agent")"
    fi
fi

######################################################################
#                       Local Overrides
######################################################################

# Source local customizations if they exist
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
