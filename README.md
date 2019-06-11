# ![](https://github.com/docker-suite/artwork/raw/master/logo/png/logo_32.png) templater
![License: MIT](https://img.shields.io/github/license/docker-suite/goss.svg?color=green&style=flat-square)

Very simple templating system that replace ```{{VAR}}``` by ```$VAR``` environment value  

Supports default values by writting ```{{VAR=value}}``` in the template

## ![](https://github.com/docker-suite/artwork/raw/master/various/pin/png/pin_16.png) Authors

Based on [lavoiesl/bash-templater](https://github.com/lavoiesl/bash-templater) and other forks

## ![](https://github.com/docker-suite/artwork/raw/master/various/pin/png/pin_16.png) Instalation

To install templater in linux type:

    curl -L https://raw.githubusercontent.com/bash-suite/templater/master/templater.sh -o /usr/local/bin/templater
    chmod +x /usr/local/bin/templater
    
## ![](https://github.com/docker-suite/artwork/raw/master/various/pin/png/pin_16.png) Usage

```sh
# Passing arguments directly
VAR=value templater template

# Evaluate /tmp/foo and pass those variables to the template
# Useful for defining variables in a file
# Parentheses are important for not polluting the current shell
(set -a && . /tmp/foo && templater template)

# A variant that does NOT pass current env variables to the templater
sh -c 'set -a && . /tmp/foo && templater template'
```

```sh
# Read variables from file:
templater template -f variables.txt

# variables.txt
# The author
AUTHOR=Johan
# The version
VERSION=1.2.3
```

```sh
# Don't print any warning messages:
templater template -f variables.txt -s
```

## ![](https://github.com/docker-suite/artwork/raw/master/various/pin/png/pin_16.png) Examples
See examples/
