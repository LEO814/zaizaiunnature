-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.interactables.gate_exit.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Interaction",
  "Inventory",
  "Combat",
  "Session",
  "Assets",
})
end
return Controller
