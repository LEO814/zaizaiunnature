-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.environment.map_tomb.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Navigation",
  "Movement",
  "Assets",
  "Session",
})
end
return Controller
