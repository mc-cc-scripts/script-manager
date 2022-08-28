# script-manager

**Work in Progress!** This project is not yet finished and wont work properly.
---

---

A dependency manager for scripts to use in the mod CC: Tweaked of Minecraft.

# Install
Download SCM with the following command:

    pastebin run 1kKZ8zTS

# Commands
**Note:** "From GitHub" usually refers to repositories within this project. "Script" refers to programs **and** libraries.
## add
- `<name>`: Downloads a library from GitHub. Libraries always have the suffix `-lib` ([Naming Conventions](https://github.com/mc-cc-scripts/.github/blob/master/profile/README.md#naming-conventions)). The suffix should not be added to the name.
- `<name>@<pastebin code>`: Downloads a library from Pastebin.
- `<url>`: Downloads a library from an URL.
## get
- `<name>`: Downloads a program from GitHub. Programs always have the suffix `-prog` ([Naming Conventions](https://github.com/mc-cc-scripts/.github/blob/master/profile/README.md#naming-conventions)). The suffix should not be added to the name.
- `<name>@<pastebin code>`: Downloads a program from Pastebin.
- `<url>`: Downloads a program from an URL.
## update
By default, without parameters, `update` updates the SCM script.
- `<name>`: Removes and downloads an installed script by name.
- `<all>`: Removes and downloads all installed scripts.
- `<name> <sourceName>`: Removes and downloads an installed script from a specific source. Sources can be added via the `source` command.
## source
- `<add> <scriptName> <sourceName> <source>`: Adds a source (URL, Pastebin Code, ...) with a name to a script.
- `<get> <scriptName>`: Shows all sources of a script.
- `<remove> <scriptName> <sourceName>`: Removes a source from a script.
- `<default> <scriptName> <sourceName>`: Sets a specific source to the default of a script. The previous default script gets a generated name.
- `<rename> <scriptName> <sourceName> <newSourceName>`: Updates the name of a source.
## remove
- `<name>`: Deletes a script by name.
- `<all>`: Deletes all scripts.
## list
Shows all installed scripts.
## config
Shows all available configurations.
- `<name> <value>`: Updates the value of a specific configuration.
## help
Shows all available commands and their description.
- `<name>`: Shows the description of a command by name.
