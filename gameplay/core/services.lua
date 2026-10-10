-- Authority for HP, inventory transactions and round results. Lua 5.1.
-- spatial.position(id) -> position; distance(position,position) -> metres;
-- spatial.los(position,position) -> boolean. No native engine APIs are assumed.
local Services = {}
local function copy(value)
  if type(value)~="table" then return value end
  local result={}
  for key,item in pairs(value) do result[key]=copy(item) end
  return result
end
local function finite(value)
  return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
local function positive_integer(value)
  return finite(value) and value>0 and value==math.floor(value)
end
local function text(value) return type(value)=="string" and value~="" end

function Services.new(state, config, definitions, spatial)
  definitions=definitions or {}
  spatial=spatial or {}
  local Characters, Combat, Inventory, Session={},{},{},{}
  local player_config=config.player or {}
  local inventory_config=config.inventory or {}
  local interaction_config=config.interaction or {}
  local combat_config=config.combat or {}
  local session_config=config.session or {}

  local function result(request,ok,reason,data)
    return {ok=ok,reason=reason or (ok and "OK" or "FAILED"),
      request_id=type(request)=="table" and request.request_id or nil,data=copy(data or {})}
  end
  local function fail(request,reason) return result(request,false,reason) end
  local function active() return state.phase=="EXPLORE" or state.phase=="EXTRACTING" end
  local function validate(request,playing)
    if type(request)~="table" then return "INVALID_REQUEST" end
    if request.run_id~=state.run_id then return "STALE_RUN" end
    if playing and not active() then return "ROUND_NOT_ACTIVE" end
  end
  local function mutate(name,request,operation)
    if type(request)~="table" or not text(request.request_id) then return fail(request,"REQUEST_ID_REQUIRED") end
    local key=name..":"..request.request_id
    local cached=state.requests[key]
    if cached then
      if request.run_id~=nil and request.run_id~=state.run_id then return fail(request,"STALE_RUN") end
      return copy(cached)
    end
    local value=operation()
    state.requests[key]=copy(value)
    return value
  end
  local function position(id)
    if type(spatial.position)=="function" then
      local ok,value=pcall(spatial.position,id)
      if ok and type(value)=="table" then return value end
    end
    local entity=state.entities[id]
    return entity and entity.position_m or nil
  end
  local function distance(a,b)
    if not a or not b then return nil end
    if type(spatial.distance)=="function" then
      local ok,value=pcall(spatial.distance,a,b)
      if ok and finite(value) and value>=0 then return value end
    end
    if not (finite(a.x) and finite(a.y) and finite(a.z) and finite(b.x) and finite(b.y) and finite(b.z)) then return nil end
    local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z
    return math.sqrt(x*x+y*y+z*z)
  end
  local function los(a,b)
    if type(spatial.los)~="function" then return nil end
    local ok,value=pcall(spatial.los,a,b)
    if not ok or type(value)~="boolean" then return nil end
    return value
  end
  local function is_player(entity)
    local definition=definitions[entity.entity_id] or {}
    return definition.type=="player" or string.sub(entity.entity_id,1,7)=="player_"
  end
  local function bag_for(owner_id)
    local entity=state.entities[owner_id]
    return entity and state.containers[entity.bag_id] or state.containers["bag_"..tostring(owner_id)]
  end
  local function find_item(item_id)
    for _,container in pairs(state.containers) do
      for index,item in ipairs(container.items) do
        if item.id==item_id then return item,container,index,nil end
      end
    end
    for _,entity in pairs(state.entities) do
      for slot,item in pairs(entity.equipment or {}) do
        if item and item.id==item_id then return item,nil,nil,{entity=entity,slot=slot} end
      end
    end
  end
  local function changed(container)
    if container then container.version=container.version+1 end
    state.inventory_version=state.inventory_version+1
  end
  local function consume_item(item,container,index,count)
    item.count=item.count-count
    if item.count==0 then table.remove(container.items,index) end
    changed(container)
  end
  local function snapshot(container,owner_id)
    local entity=state.entities[owner_id or container.owner_id]
    return {bag=copy(container),items=copy(container.items),container_id=container.id,
      owner_id=container.owner_id,slots=container.slots,version=container.version,
      equipment=copy(entity and entity.equipment or {}),inventory_version=state.inventory_version}
  end

  function Characters:spawn(request)
    return mutate("Characters.spawn",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      if not text(request.instance_id) or not text(request.entity_id) then return fail(request,"INVALID_ENTITY_ID") end
      if state.entities[request.instance_id] then return fail(request,"INSTANCE_EXISTS") end
      local definition=definitions[request.entity_id]
      if not definition then return fail(request,"UNKNOWN_ENTITY") end
      local maximum=(definition.basic or {}).maxHp or definition.maxHp or player_config.maxHp or 100
      if not positive_integer(maximum) then return fail(request,"INVALID_MAX_HP") end
      local entity={id=request.instance_id,entity_id=request.entity_id,hp=maximum,max_hp=maximum,
        alive=true,position_m=copy(request.position_m or {x=0,y=0,z=0}),
        forward_m=copy(request.forward_m or {x=0,y=0,z=1}),last_hit_at=-math.huge,
        spawn_protect_until=state.clock,armor_flat_hp=definition.armorFlatHp or 0,
        damage_reduction_ratio=definition.damageReductionRatio or 0,equipment={},modifiers={}}
      if is_player(entity) then
        entity.hp=math.min(maximum,player_config.startHp or maximum)
        entity.armor_flat_hp=player_config.armorFlatHp or 0
        entity.damage_reduction_ratio=player_config.damageReductionRatio or 0
        entity.spawn_protect_until=state.clock+(player_config.spawnProtectionSec or 0)
        entity.bag_id="bag_"..entity.id
        state.containers[entity.bag_id]={id=entity.bag_id,owner_id=entity.id,
          slots=inventory_config.bagSlots or 12,items={},version=0}
        state.player_id=entity.id
      end
      state.entities[entity.id]=entity
      return result(request,true,nil,{instance=entity,instance_id=entity.id,bag_id=entity.bag_id})
    end)
  end
  function Characters:read_snapshot(request)
    local error=validate(request,false)
    if error then return fail(request,error) end
    local entity=state.entities[request.instance_id]
    if not entity then return fail(request,"UNKNOWN_INSTANCE") end
    local value=copy(entity)
    value.position_m=copy(position(entity.id) or entity.position_m)
    return result(request,true,nil,value)
  end
  function Characters:apply_modifier(request) return fail(request,"UNSUPPORTED_DEMO_MODIFIER") end
  function Characters:remove_modifier(request) return fail(request,"UNSUPPORTED_DEMO_MODIFIER") end

  local function get_attack(source,attack_id)
    local definition=definitions[source.entity_id] or {}
    if definition.attack and (definition.attack.id==attack_id or attack_id=="primary") then return definition.attack end
    for _,attack in ipairs(definition.attacks or {}) do
      if attack.id==attack_id then return attack end
    end
    if is_player(source) then
      local weapon=source.equipment.weapon
      local weapon_definition=weapon and definitions[weapon.entity_id] or definitions.weapon_shovel
      if weapon_definition and weapon_definition.attack and weapon_definition.attack.id==attack_id then
        return weapon_definition.attack
      end
    end
  end
  function Combat:try_begin_attack(request)
    return mutate("Combat.begin",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local source=state.entities[request.source_instance_id]
      if not source or not source.alive then return fail(request,"SOURCE_NOT_ALIVE") end
      local attack=get_attack(source,request.attack_id)
      if not attack then return fail(request,"UNKNOWN_ATTACK") end
      local key=source.id..":"..request.attack_id
      if state.clock<(state.cooldowns[key] or -math.huge) then return fail(request,"ATTACK_COOLDOWN") end
      local weapon=is_player(source) and source.equipment.weapon or nil
      if weapon and weapon.durability~=nil and weapon.durability<=0 then return fail(request,"WEAPON_BROKEN") end
      state.attack_sequence=state.attack_sequence+1
      local id=state.run_id..":attack_"..state.attack_sequence
      state.attacks[id]={id=id,source_instance_id=source.id,attack_id=request.attack_id,
        definition=attack,started_at=state.clock,cancelled=false,hit_count=0}
      state.cooldowns[key]=state.clock+(attack.cooldownSec or 0)
      if weapon and weapon.durability~=nil then
        local weapon_definition=definitions[weapon.entity_id] or {}
        weapon.durability=math.max(0,weapon.durability-(weapon_definition.durabilityCostPerAttack or 0))
        changed(bag_for(source.id))
      end
      return result(request,true,nil,{attack_instance_id=id,attack_id=request.attack_id,source_instance_id=source.id})
    end)
  end
  function Combat:cancel_attack(request)
    return mutate("Combat.cancel",request,function()
      local error=validate(request,false)
      if error then return fail(request,error) end
      local attack=state.attacks[request.attack_instance_id]
      if not attack then return fail(request,"UNKNOWN_ATTACK_INSTANCE") end
      attack.cancelled=true
      return result(request,true,nil,{attack_instance_id=attack.id})
    end)
  end
  function Combat:try_apply_damage(request)
    return mutate("Combat.damage",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local attack=state.attacks[request.attack_instance_id]
      if not attack or attack.cancelled then return fail(request,"INVALID_ATTACK_INSTANCE") end
      local source,target=state.entities[attack.source_instance_id],state.entities[request.target_instance_id]
      if not source or not source.alive or not target or not target.alive then return fail(request,"TARGET_OR_SOURCE_NOT_ALIVE") end
      if source.id==target.id or (not combat_config.friendlyFire and is_player(source) and is_player(target)) then return fail(request,"INVALID_FACTION") end
      local definition=attack.definition
      local elapsed=state.clock-attack.started_at
      local window_start=definition.windupSec or 0
      local window_end=window_start+(definition.activeSec or 0.2)
      if elapsed<window_start or elapsed>=window_end then return fail(request,"OUTSIDE_HIT_WINDOW") end
      local tick=request.tick_index or 0
      if not finite(tick) or tick<0 or tick~=math.floor(tick) then return fail(request,"INVALID_TICK_INDEX") end
      if definition.damageMode~="periodic" and tick~=0 then return fail(request,"INVALID_SINGLE_TICK") end
      if definition.damageMode=="periodic" then
        local interval=definition.tickIntervalSec or 0
        if interval<(combat_config.minPeriodicTickSec or 0.2) then return fail(request,"INVALID_TICK_INTERVAL") end
        local due=(definition.firstTickDelaySec or interval)+tick*interval
        if elapsed<due then return fail(request,"TICK_NOT_DUE") end
      end
      local dedupe=attack.id..":"..target.id..":"..tick
      if state.damage_keys[dedupe] then return fail(request,"DUPLICATE_HIT") end
      if attack.hit_count>=(definition.maxTargets or 1) and definition.damageMode~="periodic" then return fail(request,"TARGET_LIMIT") end
      local evidence=request.hit_evidence
      if type(evidence)~="table" or not finite(evidence.distance_m) or evidence.distance_m<0 or evidence.angular_valid~=true then return fail(request,"INVALID_HIT_EVIDENCE") end
      local actual_distance=distance(position(source.id),position(target.id))
      if actual_distance==nil then return fail(request,"POSITION_UNAVAILABLE") end
      local range=definition.rangeM or 0
      if actual_distance>range or evidence.distance_m>range then return fail(request,"OUT_OF_RANGE") end
      if definition.requireLineOfSight~=false then
        if evidence.line_of_sight~=true then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
        local visible=los(position(source.id),position(target.id))
        if visible==nil then return fail(request,"LOS_UNSUPPORTED") end
        if not visible then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
      end
      if state.clock<target.spawn_protect_until then return fail(request,"SPAWN_PROTECTED") end
      if state.clock-target.last_hit_at<(player_config.hitInvulnerabilitySec or 0.2) then return fail(request,"HIT_INVULNERABLE") end
      local target_definition=definitions[target.entity_id] or {}
      if target_definition.physicalDamageImmune and definition.damageType=="physical" then return fail(request,"IMMUNE") end
      local base=definition.damageHp or 0
      if not finite(base) or base<0 then return fail(request,"INVALID_DAMAGE_DEFINITION") end
      local damage=math.floor(math.max(0,base-target.armor_flat_hp)*(1-target.damage_reduction_ratio)+0.5)
      state.damage_keys[dedupe]=true
      attack.hit_count=attack.hit_count+1
      target.hp=math.max(0,target.hp-damage)
      if damage>0 then target.last_hit_at=state.clock end
      target.alive=target.hp>0
      if not target.alive and is_player(target) then state.pending_terminal="death" end
      if state.extract and state.extract.user_instance_id==target.id and damage>0 and session_config.extractionCancelOnDamage~=false then
        state.extract=nil
        state.phase="EXPLORE"
        state.toast="撤离因受击取消"
      end
      return result(request,true,nil,{damage_hp=damage,hp=target.hp,max_hp=target.max_hp,alive=target.alive,target_instance_id=target.id})
    end)
  end
  function Combat:try_heal(request)
    return mutate("Combat.heal",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local user=state.entities[request.user_instance_id]
      if not user or not user.alive then return fail(request,"USER_NOT_ALIVE") end
      if user.hp>=user.max_hp then return fail(request,"FULL_HEALTH") end
      local item,container,index=find_item(request.item_instance_id)
      if not item or not container or container.owner_id~=user.id then return fail(request,"ITEM_NOT_OWNED") end
      local definition=definitions[item.entity_id] or {}
      local effect=definition.effect or {}
      if effect.kind~="heal" or not finite(effect.amountHp) or effect.amountHp<=0 then return fail(request,"NOT_HEAL_ITEM") end
      local cooldown_key="heal:"..user.id..":"..item.entity_id
      if state.clock<(state.cooldowns[cooldown_key] or -math.huge) then return fail(request,"ITEM_COOLDOWN") end
      local healed=math.min(effect.amountHp,user.max_hp-user.hp)
      user.hp=user.hp+healed
      consume_item(item,container,index,1)
      state.cooldowns[cooldown_key]=state.clock+(definition.cooldownSec or 0)
      return result(request,true,nil,{healed_hp=healed,hp=user.hp,max_hp=user.max_hp,
        item_instance_id=item.id,item_remaining=item.count})
    end)
  end

  function Inventory:_create_container(request)
    if type(request)~="table" or not text(request.id) then return fail(request,"INVALID_CONTAINER") end
    if state.containers[request.id] then return fail(request,"CONTAINER_EXISTS") end
    local slots=request.slots or inventory_config.bagSlots or 12
    if not positive_integer(slots) then return fail(request,"INVALID_CAPACITY") end
    state.containers[request.id]={id=request.id,owner_id=request.owner_id,slots=slots,items={},version=0,position_m=copy(request.position_m)}
    return result(request,true,nil,copy(state.containers[request.id]))
  end
  function Inventory:_add_item(request)
    if type(request)~="table" then return fail(request,"INVALID_REQUEST") end
    local container=state.containers[request.container_id]
    local definition=definitions[request.entity_id]
    if not container or not definition or not text(request.id) or not positive_integer(request.count or 1) then return fail(request,"INVALID_ITEM") end
    if find_item(request.id) then return fail(request,"ITEM_EXISTS") end
    local count=request.count or 1
    if count>(definition.maxStack or 1) then return fail(request,"STACK_OVERFLOW") end
    local item={id=request.id,entity_id=request.entity_id,count=count}
    if definition.durabilityMax and definition.durabilityMax>0 then item.durability=definition.durabilityMax end
    if request.equip_slot then
      local owner=state.entities[container.owner_id]
      if not owner or (request.equip_slot~="weapon" and request.equip_slot~="tool") or owner.equipment[request.equip_slot] then return fail(request,"INVALID_SLOT") end
      owner.equipment[request.equip_slot]=item
    else
      if #container.items>=container.slots then return fail(request,"BAG_FULL") end
      table.insert(container.items,item)
    end
    changed(container)
    return result(request,true,nil,{item=item,version=container.version})
  end
  function Inventory:read_snapshot(request)
    local error=validate(request,false)
    if error then return fail(request,error) end
    local container=request.container_id and state.containers[request.container_id] or bag_for(request.owner_instance_id)
    if not container then return fail(request,"UNKNOWN_CONTAINER") end
    return result(request,true,nil,snapshot(container,request.owner_instance_id))
  end
  function Inventory:try_transfer(request)
    return mutate("Inventory.transfer",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local from,to=state.containers[request.from_id],state.containers[request.to_id]
      if not from or not to or from==to then return fail(request,"INVALID_CONTAINERS") end
      local versions=request.expected_versions
      if type(versions)~="table" then return fail(request,"VERSION_REQUIRED") end
      if (versions.from or versions[from.id])~=from.version or (versions.to or versions[to.id])~=to.version then return fail(request,"VERSION_CONFLICT") end
      local actor_id=request.user_instance_id or request.owner_instance_id
      if not actor_id then
        if state.entities[to.owner_id] and is_player(state.entities[to.owner_id]) then actor_id=to.owner_id
        elseif state.entities[from.owner_id] and is_player(state.entities[from.owner_id]) then actor_id=from.owner_id end
      end
      local actor=state.entities[actor_id]
      if not actor or not actor.alive or (from.owner_id~=actor.id and to.owner_id~=actor.id) then return fail(request,"NOT_OWNER") end
      local external=from.owner_id~=actor.id and from or (to.owner_id~=actor.id and to or nil)
      if external then
        local external_position=external.position_m or position(external.owner_id)
        local d=distance(position(actor.id),external_position)
        if d==nil or d>(interaction_config.maxDistanceM or 2.2) then return fail(request,"INTERACTION_OUT_OF_RANGE") end
        if interaction_config.requireLineOfSight~=false then
          local visible=los(position(actor.id),external_position)
          if visible==nil then return fail(request,"LOS_UNSUPPORTED") end
          if not visible then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
        end
      end
      local item,container,index=find_item(request.item_instance_id)
      local count=request.count
      if not item or container~=from or not positive_integer(count) or count>item.count then return fail(request,"INVALID_ITEM_COUNT") end
      local definition=definitions[item.entity_id] or {}
      local max_stack=definition.maxStack or 1
      local available=0
      for _,existing in ipairs(to.items) do
        if existing.entity_id==item.entity_id and max_stack>1 then available=available+math.max(0,max_stack-existing.count) end
      end
      local new_slots=math.ceil(math.max(0,count-available)/max_stack)
      if #to.items+new_slots>to.slots then return fail(request,"BAG_FULL") end
      local remaining=count
      for _,existing in ipairs(to.items) do
        if existing.entity_id==item.entity_id and max_stack>1 then
          local moved=math.min(remaining,max_stack-existing.count)
          existing.count=existing.count+moved
          remaining=remaining-moved
        end
      end
      while remaining>0 do
        local moved=math.min(remaining,max_stack)
        local new_item=copy(item)
        if count==item.count and moved==count then new_item.id=item.id
        else state.item_sequence=state.item_sequence+1;new_item.id=state.run_id..":item_"..state.item_sequence end
        new_item.count=moved
        table.insert(to.items,new_item)
        remaining=remaining-moved
      end
      item.count=item.count-count
      if item.count==0 then table.remove(from.items,index) end
      changed(from)
      changed(to)
      return result(request,true,nil,{count=count,from=snapshot(from),to=snapshot(to),inventory_version=state.inventory_version})
    end)
  end
  function Inventory:try_equip(request)
    return mutate("Inventory.equip",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local owner=state.entities[request.owner_instance_id]
      local slot=request.slot_id
      if not owner or not owner.alive or (slot~="weapon" and slot~="tool") then return fail(request,"INVALID_SLOT") end
      local bag=bag_for(owner.id)
      local item,container,index=find_item(request.item_instance_id)
      if not item or container~=bag then return fail(request,"ITEM_NOT_OWNED") end
      local definition=definitions[item.entity_id] or {}
      if definition.equipmentSlot~=slot then return fail(request,"SLOT_MISMATCH") end
      if item.count~=1 then return fail(request,"INVALID_EQUIP_STACK") end
      local previous=owner.equipment[slot]
      table.remove(bag.items,index)
      if previous then table.insert(bag.items,previous) end
      owner.equipment[slot]=item
      changed(bag)
      return result(request,true,nil,snapshot(bag,owner.id))
    end)
  end
  function Inventory:try_consume(request)
    -- Healing already consumed atomically. An authorised receipt acknowledges
    -- that commit; it never spends a second item. UI cannot pre-spend.
    return mutate("Inventory.consume",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local receipt=state.requests["Combat.heal:"..tostring(request.effect_request_id)]
      if not receipt or not receipt.ok or receipt.data.item_instance_id~=request.item_instance_id then
        return fail(request,"EFFECT_COMMIT_REQUIRED")
      end
      return result(request,true,"ALREADY_COMMITTED",{item_instance_id=request.item_instance_id,
        item_remaining=receipt.data.item_remaining,effect_request_id=request.effect_request_id})
    end)
  end

  local function terminal_reason(requested)
    local player=state.player_id and state.entities[state.player_id]
    if state.pending_terminal=="death" or (player and not player.alive) then return "death" end
    if state.clock>=(session_config.roundDurationSec or 600) then return "timeout" end
    local extract=state.extract
    if requested=="extraction" and extract and state.clock-extract.started_at>=(session_config.extractionHoldSec or 3) then
      local d=distance(position(extract.user_instance_id),position(extract.exit_instance_id))
      local user=state.entities[extract.user_instance_id]
      if user and user.alive and d and d<=(interaction_config.maxDistanceM or 2.2)
        and not (session_config.extractionCancelOnDamage~=false and user.last_hit_at>extract.last_hit_at) then
        return "extraction"
      end
    end
    if requested=="quit" then return "quit" end
  end
  local function finish(reason,request)
    if state.result then return result(request,true,"ALREADY_FINISHED",state.result) end
    local items,value={},0
    local bag=state.player_id and bag_for(state.player_id)
    if reason=="extraction" and bag then
      for _,item in ipairs(bag.items) do
        table.insert(items,copy(item))
        value=value+((definitions[item.entity_id] or {}).sellValue or 0)*item.count
      end
    end
    state.result={result_id=state.run_id..":result",run_id=state.run_id,reason=reason,
      success=reason=="extraction",loot_value=value,items=items,clock=state.clock}
    state.phase="FINISHED"
    state.extract=nil
    state.pending_terminal=nil
    return result(request,true,nil,state.result)
  end
  function Session:read_snapshot(request)
    local error=validate(request,false)
    if error then return fail(request,error) end
    return result(request,true,nil,{run_id=state.run_id,phase=state.phase,clock=state.clock,
      remaining_sec=math.max(0,(session_config.roundDurationSec or 600)-state.clock),
      extract=state.extract,result=state.result,toast=state.toast})
  end
  function Session:try_start(request)
    return mutate("Session.start",request,function()
      if state.phase~="LOBBY" and state.phase~="FINISHED" then return fail(request,"ROUND_ALREADY_ACTIVE") end
      if request.run_id~=nil and request.run_id~=state.run_id then return fail(request,"STALE_RUN") end
      state.run_sequence=state.run_sequence+1
      local id="run_"..state.run_sequence
      state:reset_run(id)
      return result(request,true,nil,{run_id=id,phase=state.phase,clock=0,map_entity_id=request.map_entity_id})
    end)
  end
  function Session:try_extract(request)
    return mutate("Session.extract",request,function()
      local error=validate(request,true)
      if error then return fail(request,error) end
      local user=state.entities[request.user_instance_id]
      if not user or not user.alive then return fail(request,"USER_NOT_ALIVE") end
      local d=distance(position(user.id),position(request.exit_instance_id))
      if d==nil or d>(interaction_config.maxDistanceM or 2.2) then return fail(request,"EXIT_OUT_OF_RANGE") end
      if interaction_config.requireLineOfSight~=false then
        local visible=los(position(user.id),position(request.exit_instance_id))
        if visible==nil then return fail(request,"LOS_UNSUPPORTED") end
        if not visible then return fail(request,"BLOCKED_LINE_OF_SIGHT") end
      end
      if state.extract then return fail(request,"ALREADY_EXTRACTING") end
      if session_config.quotaEnforced then
        local total=0
        local bag=bag_for(user.id)
        for _,item in ipairs(bag and bag.items or {}) do
          local definition=definitions[item.entity_id] or {}
          if definition.countsForQuota then total=total+(definition.sellValue or 0)*item.count end
        end
        if total<(session_config.sampleQuotaValue or 1000) then return fail(request,"QUOTA_NOT_MET") end
      end
      state.extract={user_instance_id=user.id,exit_instance_id=request.exit_instance_id,
        started_at=state.clock,last_hit_at=user.last_hit_at}
      state.phase="EXTRACTING"
      return result(request,true,nil,{phase=state.phase,extract=state.extract,hold_sec=session_config.extractionHoldSec or 3})
    end)
  end
  function Session:try_finish(request)
    return mutate("Session.finish",request,function()
      local error=validate(request,false)
      if error then return fail(request,error) end
      if state.result then return result(request,true,"ALREADY_FINISHED",state.result) end
      if not active() then return fail(request,"ROUND_NOT_ACTIVE") end
      local reason=terminal_reason(request.terminal_reason)
      if not reason then return fail(request,"TERMINAL_CONDITION_NOT_MET") end
      return finish(reason,request)
    end)
  end
  function Session:tick(dt)
    if not finite(dt) or dt<0 then return fail(nil,"INVALID_DT") end
    if not active() then return result(nil,true,nil,{phase=state.phase,result=state.result}) end
    state.clock=state.clock+dt
    local forced=terminal_reason(nil)
    if forced then return finish(forced,nil) end
    local extract=state.extract
    if extract then
      local user=state.entities[extract.user_instance_id]
      local d=distance(position(extract.user_instance_id),position(extract.exit_instance_id))
      local left=d==nil or d>(interaction_config.maxDistanceM or 2.2)
      local hit=user and user.last_hit_at>extract.last_hit_at
      if (left and session_config.extractionCancelOnLeave~=false) or (hit and session_config.extractionCancelOnDamage~=false) then
        state.extract=nil
        state.phase="EXPLORE"
        state.toast=left and "离开出口，撤离取消" or "撤离因受击取消"
      elseif state.clock-extract.started_at>=(session_config.extractionHoldSec or 3) then
        return finish("extraction",nil)
      end
    end
    return result(nil,true,nil,{phase=state.phase,clock=state.clock,extract=state.extract})
  end

  return {Characters=Characters,Combat=Combat,Inventory=Inventory,Session=Session}
end

return Services
