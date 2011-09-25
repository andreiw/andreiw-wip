#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#---------------
# Shell options
#---------------
set +o notify # notify job status change
set +o nounset # otherwise some completions will fail

shopt -s cdspell  # corrects spelling
shopt -s cmdhist  # add multi line cmds to history

# This one allows files beginning with a dot ('.') to be returned in the
# results of path-name expansion.
shopt -s dotglob  

# This will give you ksh-88 egrep-style extended pattern matching or,
# in other words, turbo-charged pattern matching within bash. The available 
# operators are:

# ?(pattern-list) Matches zero or one occurrence of the given patterns 
# *(pattern-list) Matches zero or more occurrences of the given patterns 
# +(pattern-list) Matches one or more occurrences of the given patterns 
# @(pattern-list) Matches exactly one of the given patterns 
# !(pattern-list) Matches anything except one of the given patterns 
shopt -s extglob 

bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
if [ "$PS1" ] && [ $bmajor -eq 2 ] && [ $bminor '>' 04 ] \
   && [ -f /etc/bash_completion ]; then # interactive shell
        # Source completion code
        . /etc/bash_completion
fi
unset bash bmajor bminor

#------------------
# Personal aliases 
#------------------
alias h='fc -l'
alias ls='ls --color=always -FC'
alias more="less"

#-----------------
# Misc. functions
#-----------------
function stoppedjobs { jobs -s | wc -l | awk '{print $1}'; }

GREP=`which grep`

colon2fs() {
	echo $1 | sed -e 's/:/ /g'
}
	
set_once() {
	n=:
	for i in $*; do
		echo $n | $GREP -q :$i: || n=$n$i:
	done
	echo $n
}

#-----------------------
# String/file functions
#-----------------------
function gtar { gzip -c -d $1 | tar xvf -; }
function ff() { find . -name '*'$1'*' ; }                 # find a file
function fe() { find . -name '*'$1'*' -exec $2 {} \; ; }  # find a file and run $2 on it 
function fstr() # find a string in a set of files
{
    if [ "$#" -gt 2 ]; then
        echo "Usage: fstr \"pattern\" [files] "
        return;
    fi
    SMSO=$(tput smso)
    RMSO=$(tput rmso)
    find . -type f -name "${2:-*}" -print | xargs grep -sin "$1" | \
sed "s/$1/$SMSO$1$RMSO/gI"
}

function cuttail() # cut last n lines in file, 10 by default
{
    nlines=${2:-10}
    sed -n -e :a -e "1,${nlines}!{P;N;D;};N;ba" $1
}

function lowercase()  # move filenames to lowercase
{
    for file ; do
        filename=${file##*/}
        case "$filename" in
        */*) dirname==${file%/*} ;;
        *) dirname=.;;
        esac
        nf=$(echo $filename | tr A-Z a-z)
        newname="${dirname}/${nf}"
        if [ "$nf" != "$filename" ]; then
            mv "$file" "$newname"
            echo "lowercase: $file --> $newname"
        else
            echo "lowercase: $file not changed."
        fi
    done
}

# swap 2 filenames around
function swap()        
{
    local TMPFILE=tmp.$$
    mv $1 $TMPFILE
    mv $2 $1
    mv $TMPFILE $2
}

#---------
# Exports
#---------

# Bash prompt and colors.
# The forground Colors (background colors begin with 4 verses 3)
# Black       0;30     Dark Gray     1;30
# Red         0;31     Light Red     1;31
# Green       0;32     Light Green   1;32
# Brown       0;33     Yellow        1;33
# Blue        0;34     Light Blue    1;34
# Purple      0;35     Light Purple  1;35
# Cyan        0;36     Light Cyan    1;36
# Light Gray  0;37     White         1;37
# Attribute codes:
# 00=none 01=bold 04=underscore 05=blink 07=reverse 08=concealed

export PAGER=less
export EDITOR=emacs
export ENV=$HOME/.bashrc
export CVS_RSH=ssh
export DISPLAY=":0.0"
export LANG=ru_RU.UTF-8
export JAVA_HOME=~/opt/jdk1.6.0_25/bin/java

# Now set the prompt string. 
export PS1='\h:$(echo $PWD | sed -e "s!^$HOME!~!")/ '

export HISTIGNORE="&:ls:pine:[bf]g:exit:startx:mc" # dont add these to history
export LS_COLORS='no=00:fi=00:di=01;32:ln=01;36:ex=01;31:pi=40;34:so=01;37:*.sh=01;31:*.csh=01;31:*.tar=01;35:*.tgz=01;35:*.arj=01;35:*.taz=01;35:*.lzh=01;35:*.zip=01;35:*.z=01;35:*.Z=01;35:*.gz=01;35:*.bz2=01;35:*.bz=01;35:*.tz=01;35:*.rpm=01;35:*.cpio=01;35:*.jpg=01;33:*.gif=01;33:*.bmp=01;33:*.xbm=01;33:*.xpm=01;33:*.png=01;33:*.tif=01;33'

# PATH setting
# ------------
# I need some directories to be in my PATH in certain order;
# also I want to keep all the directories that are already in the PATH.
# And, of course, I don't want repeated directories in the PATH...

my_path="
        $HOME/bin
        $HOME/opt/arm-2011.03/bin
        $HOME/opt/jdk1.6.0_25/bin
	"
export PATH=$(set_once $my_path $(colon2fs $PATH))

# MANPATH setting
# ---------------

my_manpath="
        /opt/local/man
        /opt/local/share/man	
	"
export MANPATH=$(set_once $my_manpath $(colon2fs $MANPATH))

# LD_LIBRARY_PATH setting
# -----------------------
#
my_ldlib_path="
	$HOME/lib
	"
export LD_LIBRARY_PATH=$(set_once $my_ldlib_path $(colon2fs $LD_LIBRARY_PATH))
