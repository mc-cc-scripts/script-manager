package = "SCM"
version = "1.0-0"
source = {
   url = "..." -- We don't have one yet
}
description = {
   summary = "SCM is a script manager for Minecrafts ComputerCraft mod",
   detailed = [[
      We are using CC: Tweaked and in some cases some
      additional peripherals, which we ideally mention in
      the repositories of the scripts that use them.
   ]],
   homepage = "http://...", -- We don't have one yet
   license = "MIT/X11" -- or whatever you like
}
dependencies = {
   "lua = 5.1",
   "http >= 0.4-0"
   -- If you depend on other rocks, add them here
}
build = {
   -- We'll start here.
   type = "builtin"

}