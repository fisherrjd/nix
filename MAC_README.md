Install nix hms:
``` bash
ssh-keygen -o -a 100 -t ed25519 -C "jade@<identifier>"
git clone git@github.com:fisherrjd/nix.git ~/cfg
# SOME COMMAND???
# nix-build --no-link --expr 'with import ~/cfg {}; _hms'

touch .bash_profile
```


``` bash
export PATH="$PATH:$HOME/.nix-profile/bin"
export PATH="$PATH:$HOME/.bin/"
# Commands that should be applied only for interactive shells.
[[ $- == *i* ]] || return

HISTFILESIZE=-1
HISTSIZE=-1

shopt -s histappend
shopt -s checkwinsize
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

HISTCONTROL=ignoreboth
set +h

# additional aliases
[[ -e ~/.aliases ]] && source ~/.aliases

# starship
eval "$(/Users/jade/.nix-profile/bin/starship init bash --print-full-init)"

# direnv
eval "$(/Users/jade/.nix-profile/bin/direnv hook bash)"
```