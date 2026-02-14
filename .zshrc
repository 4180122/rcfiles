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

# Enable prompt substitution
setopt PROMPT_SUBST
setopt PROMPT_SP

# Load vcs_info for better git integration
autoload -Uz vcs_info

# Configure vcs_info before each prompt
precmd_vcs_info() {
    vcs_info
}
precmd_functions+=(precmd_vcs_info)

# vcs_info configuration for git (Aurelia theme)
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes false  # Disabled for speed
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '%F{79}⎇ %b%f'
zstyle ':vcs_info:git:*' actionformats '%F{79}⎇ %b%f%F{198}|%a%f'

# Aurelia theme prompt - simplified and ssh-friendly
prompt() {
    local term_width=${COLUMNS:-80}
    
    # Build the ssh-friendly path (user@host:~/directory)
    local user_host="${USER}@${HOST}"
    local current_dir="${${(%):-%~}}"
    local ssh_path="${user_host}:${current_dir}"
    local datetime="${${(%):-%D{%Y-%m-%d %H:%M}}}"
    local git_info_plain=""
    
    # Strip color codes from git info
    if [[ -n "${vcs_info_msg_0_}" ]]; then
        git_info_plain=$(echo "${vcs_info_msg_0_}" | sed -E 's/\x1b\[[0-9;]*m//g' | sed 's/%[Ff]{[^}]*}//g' | sed 's/%[Ff]//g')
    fi
    
    # Build left side: ╭[ user@host:~/dir ]
    local left_side="╭[ ${ssh_path} ]"
    
    # Build right side: [ git ] [ date ]╮
    local right_side="[ ${datetime} ]╮"
    if [[ -n "$git_info_plain" ]]; then
        right_side="[ ${git_info_plain} ] ${right_side}"
    fi
    
    # Calculate fill length
    local left_length=${#left_side}
    local right_length=${#right_side}
    local fill_length=$((term_width - left_length - right_length + 5))
    
    # Add 1 more character when not in git repo
    [[ -z "$git_info_plain" ]] && fill_length=$((fill_length + 1))
    
    # Truncate path if needed
    if [[ $fill_length -lt 5 ]]; then
        local max_path=$((term_width - ${#user_host} - right_length - 20))
        if [[ $max_path -gt 15 && ${#current_dir} -gt $max_path ]]; then
            local keep_chars=$(( (max_path - 3) / 2 ))
            current_dir="${current_dir:0:$keep_chars}...${current_dir: -$keep_chars}"
            ssh_path="${user_host}:${current_dir}"
            left_side="╭[ ${ssh_path} ]"
            left_length=${#left_side}
            fill_length=$((term_width - left_length - right_length + 5))
            [[ -z "$git_info_plain" ]] && fill_length=$((fill_length + 1))
        fi
    fi
    
    if [[ $fill_length -lt 0 ]]; then
        fill_length=0
    fi
    
    # Create fill string
    local fill=$(printf '─%.0s' $(seq 1 $fill_length))
    
    # Build prompt with Aurelia colors
    PS1="%F{205}╭[ %f%F{117}%n%f%F{205}@%f%F{79}%m%f%F{205}:%f%F{180}${current_dir}%f%F{205} ]${fill}%f"
    
    # Add git info if available
    if [[ -n "${vcs_info_msg_0_}" ]]; then
        PS1+="%F{205}[ %f${vcs_info_msg_0_}%F{205} ]──%f"
    fi
    
    # Add date
    PS1+="%F{205}[ %f%F{198}%D{%Y-%m-%d %H:%M}%f%F{205} ]╮%f"$'\n'
    PS1+="%F{205}╰▶%f "
    
    RPS1=""
}
precmd_functions+=(prompt)

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

alias date='echo -ne "\033[38;5;198m"; \date "+%A %B %d, %Y %l:%M %p %Z"'
alias cal='echo -e "\033[38;5;79m"; \cal'
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
    # Display calendar on startup with Aurelia colors (3 months: previous, current, next)
    clear
    echo -e "\033[38;5;79m"  # Teal (Aurelia green)
    if [[ "$OS" == "macos" ]]; then
        cal -A 1 -B 1 2>/dev/null
    else
        cal -3 2>/dev/null
    fi
    echo -e "\033[0m"  # Reset color

    # Optional fortune display with Aurelia colors
    if command -v fortune &>/dev/null; then
        echo -e "\033[38;5;205m"  # Bright magenta/pink (Aurelia accent)
        fortune 2>/dev/null || true
        echo -e "\033[0m"  # Reset color
    fi

    # Set terminal title
    host=$(uname -n)
    if [[ "$TERM" == "xterm" || "$TERM" == "xterm-256color" ]]; then
        print -Pn "\e]2;${host}\a\e]1;${host}\a"
    fi
fi

######################################################################
#                       Completion
######################################################################

autoload -U compinit
compinit

# Enable edit-command-line for vim multiline editing
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line  # Ctrl+X then Ctrl+E opens vim

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
