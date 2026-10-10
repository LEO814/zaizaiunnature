local Definition=require('gameplay.packages.environment.map_demo.definition')
local Controller={};Controller.__index=Controller
function Controller.new(context,instance)return setmetatable({context=context,instance=instance,definition=Definition},Controller)end
function Controller:start()self.started=true;return true end
function Controller:dispose()self.started=false end
return Controller
