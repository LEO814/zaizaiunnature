local Config = require("gameplay.core.config")
local Registry = require("gameplay.registry")
local Factories = require("gameplay.package_factories")
local Services = require("gameplay.core.service_contracts")
local ServiceApi = require("gameplay.core.service_api")
local DefaultAdapter = require("gameplay.adapters.zaizai.adapter")
local Bootstrap = {}
function Bootstrap.create(adapter)
  adapter = adapter or DefaultAdapter.new()
  local context = {config=Config, registry=Registry, services=adapter.services or {},
    is_ready=adapter.is_ready == true, adapter=adapter}
  for _, name in ipairs(Services) do
    local service = context.services[name]
    if type(service) ~= "table" then context.is_ready=false end
    for _, operation in ipairs(ServiceApi.operations[name]) do
      if type(service) ~= "table" or type(service[operation]) ~= "function" then context.is_ready=false end
    end
  end
  function context:new_entity(entity_id, instance)
    if not self.is_ready then return nil, "ADAPTER_NOT_READY" end
    local factory = Factories[entity_id]
    if not factory then return nil, "UNKNOWN_ENTITY" end
    return factory.controller.new(self, instance)
  end
  return context
end
return Bootstrap
