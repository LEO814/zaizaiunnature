-- Package behavior entry point. Replace the NOT_IMPLEMENTED shell with actual behavior.
local Base = require("gameplay.core.base_controller")
local Definition = require("gameplay.packages.items.item_treasure.definition")
local Controller = {}
function Controller.new(context, instance)
  return Base.new(context, instance, Definition, {
  "Characters",
  "Combat",
  "Inventory",
  "Interaction",
  "Assets",
  "Session",
})
end
return Controller
