# script-manager

A dependency manager for scripts to use in the mod CC: Tweaked of Minecraft.

# Install
Download SCM with the following command:

    pastebin run 1kKZ8zTS

# Commands
**Note:** "From GitHub" usually refers to repositories within this project. "Script" refers to programs **and** libraries.
## add
- `<name>`: Downloads a program from GitHub. Programs always have the suffix `-prog` ([Naming Conventions](https://github.com/mc-cc-scripts/.github/blob/master/profile/README.md#naming-conventions)). The suffix should not be added to the name.
- `<name>@<pastebin code>`: Downloads a program from Pastebin.
## require
- `<name>`: Downloads a library from GitHub. Libraries always have the suffix `-lib` ([Naming Conventions](https://github.com/mc-cc-scripts/.github/blob/master/profile/README.md#naming-conventions)). The suffix should not be added to the name.
- `<name>@<pastebin code>`: Downloads a library from Pastebin.
## update
By default, without parameters, `update` updates the SCM script.
- `<name>`: Removes and downloads an installed script by name.
- `all`: Removes and downloads all installed scripts.
- `<name> <sourceName>`: Removes and downloads an installed script from a specific source. Sources can be added via the `source` command.
## source
- `add <scriptName> <sourceName> <source>`: Adds a source (URL, Pastebin Code, ...) with a name to a script.
- `get <scriptName>`: Shows all sources of a script.
- `remove <scriptName> <sourceName>`: Removes a source from a script.
- `default <scriptName> <sourceName>`: Sets a specific source to the default of a script. The previous default script gets a generated name.
- `rename <scriptName> <sourceName> <newSourceName>`: Updates the name of a source.
## remove
- `<name>`: Deletes a script by name.
- `all`: Deletes all scripts.
## list
Shows all installed scripts.
## config
Shows all available configurations.
- `<name>`: Shows the value of a specific configuration.
- `<name> <value>`: Updates the value of a specific configuration.
## help
Shows all available commands and their description.
- `<name>`: Shows the description of a command by name.

## Requires
If you want to load a library within a program and keep it updated through SCM, then you can do that with the following notation:

```lua
local scm = require("./scm")
scm:load("testLibrary")
```

If the Library is already called by a Programm using this SCM loader, SCM will check all Libraries loaded for these comments:


```lua
--@requires subLibrary
require("subLibrary")
```

The comment tells SCM to look for the sub-library and, if it's not already installed, it will try to download it.
This prevent the programm from Crashing, should SCM not be installed.
