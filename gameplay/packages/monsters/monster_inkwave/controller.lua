-- INKWAVE-inspired shooter monster. Only injected project services; no editor globals.
-- Original BotBrain ideas: reaction delay / short retreat / weapon-range gating (MIT).
-- Public HP, clock, phase and world transforms are owned by the core/Adapter.
local Definition = require("gameplay.packages.monsters.monster_inkwave.definition")
local Controller = {}
Controller.__index = Controller

local required = {"Characters", "Combat", "Movement", "Navigation", "Interaction", "Assets", "Session"}
local methods = {
  Characters = {"read_snapshot"},
  Combat = {"try_begin_attack", "try_apply_damage", "cancel_attack"},
  Movement = {"read_position", "move_to", "stop"},
  Navigation = {"find_path", "cancel_query"},
  Interaction = {"query_target"},
  Assets = {"play_clip"},
  Session = {"read_snapshot"},
}

local function point(value)
  if type(value) ~= "table" then return nil end
  local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
  if not x or not y or not z then return nil end
  return {x = x, y = y, z = z}
end

local function ground_distance(a, b)
  local x, z = a.x - b.x, a.z - b.z
  return math.sqrt(x*x + z*z)
end

local function result_data(result)
  if type(result) == "table" and result.ok == true and type(result.data) == "table" then
    return result.data
  end
  return nil
end

function Controller.new(context, instance)
  assert(type(context) == "table", "context required")
  assert(type(instance) == "table" and type(instance.id) == "string", "instance.id required")
  return setmetatable({
    context = context, instance = instance,
    definition = (context.definitions and context.definitions.monster_inkwave) or Definition,
    required_services = required, disposed = false, started = false,
    ai_state = "idle", state = "idle", target_id = instance.target_id or "player_local",
    reaction_started_at = nil, next_retreat_at = 0, retreat_goal = nil, retreat_until = nil,
    request_sequence = 0, route_index = 1, patrol_wait_until = 0,
    next_attack_at = 0, next_path_at = 0, path_index = 1,
    last_seen_position = nil, last_seen_at = nil, attack_instance_id = nil,
    attack_hit_committed = false, attack_hit_attempted = false,
  }, Controller)
end

function Controller:_now()
  return tonumber(self.context.state.clock) or 0
end

function Controller:_request(operation, fields)
  fields = fields or {}
  self.request_sequence = self.request_sequence + 1
  local prefix = "monster_inkwave:" .. self.instance.id .. ":" .. operation
  if type(self.context.next_request_id) == "function" then
    fields.request_id = self.context:next_request_id(prefix)
  else
    fields.request_id = tostring(self.bound_run_id or self.context.state.run_id) .. ":" .. prefix .. ":" .. self.request_sequence
  end
  fields.run_id = self.bound_run_id or self.context.state.run_id
  return fields
end

function Controller:_play(event, force)
  if self.current_feedback == event and not force then return end
  local feedback = self.definition.feedback[event] or self.definition.feedback.idle
  local role = feedback.clipRole
  local clip = self.definition.clips[role]
  local restart = force == true or self.current_clip ~= clip
  self.current_feedback, self.current_clip = event, clip
  -- Extra presentation hints are consumed by the Adapter for THIS instance only.
  -- They do not grant damage, create inventory, mutate the match or need a new service.
  self.context.services.Assets:play_clip(self:_request("feedback", {
    instance_id = self.instance.id, clip_id = clip, clip_name = role,
    restart = restart, loop = role == "idle" or role == "patrol" or role == "chase",
    monster_feedback = {
      event = "monster_inkwave_" .. event,
      sound_id = feedback.soundId, fx_id = feedback.fxId,
      attack_instance_id = self.attack_instance_id,
      target_position_m = point(self.last_seen_position),
    },
  }))
end

function Controller:_set_state(name)
  self.ai_state, self.state = name, name
end

function Controller:_position(instance_id)
  local data = result_data(self.context.services.Movement:read_position(self:_request("position", {
    instance_id = instance_id,
  })))
  return data and point(data.position_m) or nil, data
end

function Controller:_snapshot(instance_id)
  return result_data(self.context.services.Characters:read_snapshot(self:_request("snapshot", {
    instance_id = instance_id,
  })))
end

function Controller:_stop_moving()
  self.context.services.Movement:stop(self:_request("stop", {instance_id = self.instance.id}))
end

function Controller:_clear_path()
  if self.path_task_id then
    self.context.services.Navigation:cancel_query(self:_request("cancel_path", {
      instance_id = self.instance.id, task_id = self.path_task_id,
    }))
  end
  self.path, self.path_goal, self.path_task_id = nil, nil, nil
  self.path_index, self.next_path_at = 1, 0
end

function Controller:_cancel_attack(reason)
  if self.attack_instance_id then
    self.context.services.Combat:cancel_attack(self:_request("cancel_attack", {
      source_instance_id = self.instance.id,
      attack_instance_id = self.attack_instance_id, reason = reason,
    }))
  end
  self.attack_instance_id, self.attack_started_at = nil, nil
  self.attack_hit_committed, self.attack_hit_attempted = false, false
end

function Controller:_perception()
  local data = result_data(self.context.services.Interaction:query_target(self:_request("perception", {
    user_instance_id = self.instance.id, target_instance_id = self.target_id,
    mode = "perception", range_m = self.definition.sense.rangeM,
    full_angle_deg = self.definition.sense.fullAngleDeg,
    require_line_of_sight = self.definition.sense.requireLineOfSight,
  })))
  if not data then return {visible = false} end
  local sensed_distance = tonumber(data.distance_m)
  local visible = data.visible == true and data.line_of_sight == true
    and data.angular_valid == true and sensed_distance ~= nil
    and sensed_distance <= self.definition.sense.rangeM
  return {visible = visible, distance_m = sensed_distance,
    line_of_sight = data.line_of_sight == true, angular_valid = data.angular_valid == true}
end

function Controller:_remember_target(now, perception)
  if not perception.visible then return end
  local position = self:_position(self.target_id)
  if position then
    self.last_seen_position, self.last_seen_at = position, now
  end
end

function Controller:_follow(goal, speed, dt, now)
  local own_position = self:_position(self.instance.id)
  if not own_position or not goal then
    self:_stop_moving()
    return false, "POSITION_UNAVAILABLE"
  end
  if ground_distance(own_position, goal) <= self.definition.arriveDistanceM then
    self:_stop_moving()
    return true, "ARRIVED"
  end
  local changed_goal = not self.path_goal or ground_distance(self.path_goal, goal) > 0.5
  if changed_goal or now >= self.next_path_at then
    local data = result_data(self.context.services.Navigation:find_path(self:_request("path", {
      instance_id = self.instance.id, from_m = own_position, to_m = goal,
    })))
    self.path_goal, self.path, self.path_index = point(goal), nil, 1
    self.path_task_id = data and data.task_id or nil
    if data and type(data.waypoints) == "table" then
      local path = {}
      for _, candidate in ipairs(data.waypoints) do
        local waypoint = point(candidate)
        if waypoint then path[#path + 1] = waypoint end
      end
      if #path > 0 then self.path = path end
    end
    self.next_path_at = now + (self.path and self.definition.pathRefreshSec or self.definition.pathFailureRetrySec)
  end
  if not self.path then
    self:_stop_moving()
    return false, "NO_PATH"
  end
  while self.path[self.path_index]
    and ground_distance(own_position, self.path[self.path_index]) <= self.definition.arriveDistanceM do
    self.path_index = self.path_index + 1
  end
  local waypoint = self.path[self.path_index]
  if not waypoint then
    self:_stop_moving()
    self.next_path_at = 0
    return false, "PATH_EXHAUSTED"
  end
  local result = self.context.services.Movement:move_to(self:_request("move", {
    instance_id = self.instance.id, goal_m = waypoint, speed_mps = speed, dt_sec = dt,
  }))
  if type(result) ~= "table" or result.ok ~= true then
    self:_stop_moving()
    self:_clear_path()
    return false, "MOVE_BLOCKED"
  end
  return false, "MOVING"
end

function Controller:start()
  if self.disposed then return false, "DISPOSED" end
  if self.started then return true, "ALREADY_STARTED" end
  if not self.context.is_ready then return false, "ADAPTER_NOT_READY" end
  if type(self.context.state) ~= "table" or self.context.state.run_id == nil then
    return false, "MISSING_SESSION_STATE"
  end
  for _, name in ipairs(required) do
    local service = self.context.services and self.context.services[name]
    if type(service) ~= "table" then return false, "MISSING_SERVICE:" .. name end
    for _, method in ipairs(methods[name]) do
      if type(service[method]) ~= "function" then return false, "MISSING_METHOD:" .. name .. "." .. method end
    end
  end
  self.bound_run_id = self.context.state.run_id
  local own_position = self:_position(self.instance.id)
  local snapshot = self:_snapshot(self.instance.id)
  if not own_position then return false, "POSITION_UNAVAILABLE" end
  if not snapshot or snapshot.hp == nil then return false, "CHARACTER_UNAVAILABLE" end
  self.home_position, self.last_hp = own_position, tonumber(snapshot.hp)
  self.route = {}
  local route = self.instance.route or self.definition.patrolRoute
  if type(route) == "table" then
    for _, candidate in ipairs(route) do
      local waypoint = point(candidate)
      if waypoint then self.route[#self.route + 1] = waypoint end
    end
  end
  if #self.route == 0 then
    self.route = {
      {x = own_position.x - 2, y = own_position.y, z = own_position.z},
      {x = own_position.x + 2, y = own_position.y, z = own_position.z},
    }
  end
  self.started = true
  self:_set_state("patrol")
  self:_play("patrol")
  return true, "STARTED"
end

function Controller:_begin_attack(now)
  if now < self.next_attack_at then return false end
  -- Caller reaches this branch only after current distance/FOV/LOS passes.
  -- The verified Adapter accepts a zero-speed move as an in-place facing
  -- command; use only the current visible point, never hidden live transforms.
  if self.last_seen_position then
    self.context.services.Movement:move_to(self:_request("aim", {
      instance_id = self.instance.id, goal_m = point(self.last_seen_position),
      speed_mps = 0, dt_sec = 0,
    }))
  end
  local data = result_data(self.context.services.Combat:try_begin_attack(self:_request("attack", {
    source_instance_id = self.instance.id, target_instance_id = self.target_id,
    attack_id = self.definition.attacks[1].id,
  })))
  if not data or not data.attack_instance_id then
    self.next_attack_at = now + 0.2
    return false
  end
  self.attack_instance_id, self.attack_started_at = data.attack_instance_id, now
  self.attack_hit_committed, self.attack_hit_attempted = false, false
  self.next_attack_at = now + self.definition.attacks[1].cooldownSec
  self:_clear_path()
  self:_stop_moving()
  self:_set_state("windup")
  self:_play("windup", true)
  return true
end

function Controller:_update_attack(now, perception)
  local attack = self.definition.attacks[1]
  local age = now - self.attack_started_at
  local active_end = attack.windupSec + attack.activeSec
  local finish = active_end + attack.recoverySec
  self:_stop_moving()
  if age < attack.windupSec then
    self:_set_state("windup")
    return
  end
  if age < active_end then
    self:_set_state("attack")
    self:_play("attack")
    if not self.attack_hit_attempted and perception.visible
      and perception.distance_m <= attack.rangeM then
      -- Only the current authoritative active window can submit damage.
      -- The core validates distance, LOS, arc, window and deduplication again.
      self.attack_hit_attempted = true
      local result = self.context.services.Combat:try_apply_damage(self:_request("hit", {
        source_instance_id = self.instance.id, attack_id = attack.id,
        attack_instance_id = self.attack_instance_id, target_instance_id = self.target_id,
        tick_index = 0,
        hit_evidence = {distance_m = perception.distance_m,
          angular_valid = perception.angular_valid, line_of_sight = perception.line_of_sight},
      }))
      self.attack_hit_committed = type(result) == "table" and result.ok == true
    end
    return
  end
  if age < finish then
    self:_set_state("recovery")
    self:_play("recovery")
    return
  end
  self:_cancel_attack("ATTACK_FINISHED")
  self:_set_state(perception.visible and "chase" or "search")
  if not perception.visible then self.search_started_at = now end
end

function Controller:_patrol(now, dt)
  if now < self.patrol_wait_until then self:_play("idle"); self:_stop_moving(); return end
  self:_play("patrol")
  local arrived, reason = self:_follow(self.route[self.route_index], self.definition.patrolSpeedMps, dt, now)
  if arrived then
    self.route_index = self.route_index % #self.route + 1
    self.patrol_wait_until, self.patrol_failure_at = now + self.definition.patrolWaitSec, nil
    self:_clear_path()
  elseif reason == "NO_PATH" or reason == "MOVE_BLOCKED" then
    self.patrol_failure_at = self.patrol_failure_at or now
    if now - self.patrol_failure_at >= self.definition.patrolUnreachableSkipSec then
      self.route_index = self.route_index % #self.route + 1
      self.patrol_failure_at = nil
      self:_clear_path()
    end
  else self.patrol_failure_at = nil end
end

function Controller:_begin_retreat(now, own_position)
  local settings = self.definition.retreat
  if not settings or settings.enabled ~= true or now < self.next_retreat_at
    or not own_position or not self.last_seen_position then return false end
  local x = own_position.x - self.last_seen_position.x
  local z = own_position.z - self.last_seen_position.z
  local length = math.sqrt(x*x + z*z)
  if length < 0.01 then return false end
  local amount = math.max(0, settings.distanceM or 2)
  local goal = {x = own_position.x + x / length * amount,
    y = own_position.y, z = own_position.z + z / length * amount}
  if ground_distance(goal, self.home_position) > self.definition.leashRadiusM then
    goal = point(self.home_position)
  end
  self.retreat_goal = goal
  self.retreat_until = now + (settings.durationSec or 1.5)
  self.next_retreat_at = now + (settings.cooldownSec or 6)
  self:_cancel_attack("RETREAT")
  self:_clear_path()
  self:_set_state("retreat")
  self:_play("retreat")
  return true
end

function Controller:update(dt)
  if self.disposed then return false, "DISPOSED" end
  if not self.started then return false, "NOT_STARTED" end
  if type(dt) ~= "number" or dt < 0 then return false, "INVALID_DT" end
  local public = self.context.state
  if public.run_id ~= self.bound_run_id then self:stop("RUN_CHANGED"); return false, "RUN_CHANGED" end
  if public.phase ~= "EXPLORE" and public.phase ~= "EXTRACTING" then
    self:_cancel_attack("SESSION_INACTIVE")
    self:_clear_path()
    self:_stop_moving()
    self.last_seen_position, self.last_seen_at = nil, nil
    self.reaction_started_at, self.search_started_at = nil, nil
    self.retreat_goal, self.retreat_until = nil, nil
    if self.ai_state ~= "dead" then
      self:_set_state("patrol")
      self:_play("idle")
    end
    return true, "SESSION_INACTIVE"
  end
  local now = self:_now()
  local snapshot = self:_snapshot(self.instance.id)
  if not snapshot or snapshot.hp == nil then self:_stop_moving(); return false, "CHARACTER_UNAVAILABLE" end
  local hp = tonumber(snapshot.hp) or 0
  if snapshot.alive == false or hp <= 0 then
    if self.ai_state ~= "dead" then
      self:_cancel_attack("DEAD")
      self:_clear_path()
      self:_stop_moving()
      self:_set_state("dead")
      self:_play("death", true)
    end
    self.last_hp = hp
    return true, "DEAD"
  end
  if self.ai_state == "dead" then return true, "DEAD" end
  if self.last_hp and hp < self.last_hp then
    self:_cancel_attack("HURT")
    self:_clear_path()
    self:_stop_moving()
    self:_set_state("hurt")
    self.hurt_until = now + self.definition.hurtPauseSec
    self:_play("hit", true)
  end
  self.last_hp = hp
  if self.ai_state == "hurt" and now < self.hurt_until then return true, "HURT" end
  local target_snapshot = self:_snapshot(self.target_id)
  local perception = (target_snapshot and target_snapshot.alive ~= false and (tonumber(target_snapshot.hp) or 0) > 0)
    and self:_perception() or {visible = false}
  self:_remember_target(now, perception)
  if self.ai_state == "hurt" then
    self.reaction_started_at = nil
    self.retreat_goal, self.retreat_until = nil, nil
    self:_set_state(perception.visible and "chase" or (self.last_seen_position and "search" or "patrol"))
    if self.ai_state == "search" then self.search_started_at = now end
  end
  if self.attack_instance_id then self:_update_attack(now, perception); return true, self.ai_state end
  local own_position = self:_position(self.instance.id)
  if own_position and ground_distance(own_position, self.home_position) > self.definition.leashRadiusM then
    self:_set_state("return")
    self.last_seen_position, self.last_seen_at = nil, nil
    self.reaction_started_at, self.retreat_goal, self.retreat_until = nil, nil, nil
  elseif self.ai_state == "retreat" then
    if now >= self.retreat_until then
      self.retreat_goal, self.retreat_until = nil, nil
      self:_clear_path()
      self:_set_state(perception.visible and "chase" or "search")
      if not perception.visible then self.search_started_at = now end
    end
  elseif perception.visible then
    if self.ai_state ~= "chase" then
      self.reaction_started_at = self.reaction_started_at or now
      self:_set_state("alert")
      if now - self.reaction_started_at + 1e-9 >= self.definition.reactionDelaySec then
        self.reaction_started_at = nil
        self:_set_state("chase")
      end
    end
  elseif self.ai_state == "alert" then
    -- A glimpse before reaction completes is not a tracking lock.
    self.reaction_started_at = nil
    self.last_seen_position, self.last_seen_at = nil, nil
    self:_set_state("patrol")
  elseif self.ai_state == "chase" and self.last_seen_at
    and now - self.last_seen_at >= self.definition.sense.loseSightGraceSec then
    self:_set_state("search")
    self.search_started_at = now
    self:_clear_path()
  end
  local retreat = self.definition.retreat
  if self.ai_state == "chase" and perception.visible and retreat and retreat.enabled
    and hp / math.max(1, tonumber(snapshot.max_hp) or self.definition.maxHp) <= retreat.atHpRatio then
    self:_begin_retreat(now, own_position)
  end
  if self.ai_state == "chase" then
    if perception.visible and perception.distance_m <= self.definition.attacks[1].rangeM and self:_begin_attack(now) then
      return true, "WINDUP"
    end
    self:_play("chase")
    if self.last_seen_position then self:_follow(self.last_seen_position, self.definition.chaseSpeedMps, dt, now)
    else self:_set_state("patrol") end
  elseif self.ai_state == "alert" then
    self:_stop_moving()
    self:_play("idle")
  elseif self.ai_state == "retreat" then
    self:_play("retreat")
    self:_follow(self.retreat_goal, self.definition.chaseSpeedMps, dt, now)
  elseif self.ai_state == "search" then
    self.search_started_at = self.search_started_at or now
    if now - self.search_started_at >= self.definition.sense.searchSec or not self.last_seen_position then
      self:_set_state("return")
      self:_clear_path()
    else
      self:_play("patrol")
      self:_follow(self.last_seen_position, self.definition.patrolSpeedMps, dt, now)
    end
  elseif self.ai_state == "return" then
    self:_play("patrol")
    local arrived = self:_follow(self.home_position, self.definition.patrolSpeedMps, dt, now)
    if arrived then
      self:_set_state("patrol")
      self.search_started_at, self.last_seen_position, self.last_seen_at = nil, nil, nil
      self:_clear_path()
    end
  elseif self.ai_state == "patrol" then self:_patrol(now, dt) end
  return true, self.ai_state
end

function Controller:stop(reason)
  if self.disposed then return false, "DISPOSED" end
  if self.started then
    self:_cancel_attack(reason or "STOPPED")
    self:_clear_path()
    self:_stop_moving()
  end
  self.started = false
  self.reaction_started_at, self.search_started_at = nil, nil
  self.last_seen_position, self.last_seen_at = nil, nil
  self.retreat_goal, self.retreat_until = nil, nil
  self.current_feedback, self.current_clip = nil, nil
  self:_set_state("stopped")
  return true, "STOPPED"
end

function Controller:dispose()
  if self.disposed then return true, "ALREADY_DISPOSED" end
  self:stop("DISPOSED")
  self.disposed, self.context = true, nil
  return true, "DISPOSED"
end

return Controller
