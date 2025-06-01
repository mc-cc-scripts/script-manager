# Script Manager

**SCM** is a script manager for Minecrafts ComputerCraft mod.

We are using [CC: Tweaked](https://tweaked.cc/) and in some cases some additional peripherals, which we ideally mention in the repositories of the scripts that use them.

**SCM** is used so you don't have to worry too much about your libraries. You can focus on writing your program and if it uses external libraries, they will be installed automatically. Furthermore, if you want to keep your scripts up-to-date, **SCM** saves the source of the programs you've installed and lets you update them by just typing `scm update <name>`.

[Documentation](https://github.com/mc-cc-scripts/script-manager/wiki) | [MIT License](https://github.com/mc-cc-scripts/script-manager/blob/master/LICENSE)

# Quickstart
## Installation
Download **SCM** with the following command:

    pastebin run 1kKZ8zTS

## Configuration
There are various configurations you can change. If you want to use your own repository, you can easily change it in the [configuration](https://github.com/mc-cc-scripts/script-manager/wiki/Configuration).

## Commands
You can find a complete list of all commands [here](https://github.com/mc-cc-scripts/script-manager/wiki/Commands).

## Download a program
You can either download a program from GitHub with
```
scm add testProgram
```
or from Pastebin with
```
scm add testProgram@7ByR3NYn
```

## Build scripts
## SCM Program
To add libraries to your programs, you will have to require **SCM** first.
```lua
local scm = require("./scm")
```
Then you can load your libraries as follows:
```lua
scm:load("testLibrary")
```
If a library is missing, **SCM** will try to install it.

Alternatively you can add a comment before requiring the library. This has the advantage of the libraries still being usable without **SCM**, as a comment does not interfere with the logic of the script.
```lua
--@requires subLibrary
require("./libs/subLibrary")
```

### Pastebin
You can also use libraries hosted on Pastebin. Just attach the Pastebin code at the end of the name, separated by an `@`.
```lua
--@requires subLibrary@z4VRj21Y
require("./libs/subLibrary")
```

