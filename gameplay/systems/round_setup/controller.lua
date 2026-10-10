-- Program-owned spawn orchestration. No object-specific AI.
local Controller={};Controller.__index=Controller
function Controller.new(context)return setmetatable({context=context,objects={}},Controller)end
function Controller:request(prefix,fields)fields=fields or{};fields.run_id=self.context.state.run_id;fields.request_id=self.context:next_request_id(prefix);return fields end
function Controller:spawn(entity_id,instance_id,position,node_name,extra)
 local ctx=self.context
 local spawned=ctx.services.Characters:spawn(self:request('spawn_'..instance_id,{entity_id=entity_id,instance_id=instance_id,position_m=position}))
 if not spawned.ok then error('Spawn '..instance_id..': '..tostring(spawned.reason))end
 local asset=ctx.services.Assets:instantiate(self:request('asset_'..instance_id,{entity_id=entity_id,instance_id=instance_id,node_name=node_name,position_m=position}))
 if not asset.ok then error('Asset '..instance_id..': '..tostring(asset.reason))end
 local instance=extra or{};instance.id=instance_id;instance.position_m=position
 local obj,reason=ctx:new_entity(entity_id,instance);if not obj then error(reason)end
 local started,why=obj:start();if not started then error('Start '..instance_id..': '..tostring(why))end
 self.objects[instance_id]=obj
 return obj
end
function Controller:start(map)
 local ctx=self.context;local inv=ctx.services.Inventory
 self.objects={}
 local player=self:spawn('player_default','player_local',map.spawn,'player_default')
 local monster=self:spawn(ctx.monster_entity_id or 'monster_cube',ctx.monster_instance_id or 'monster_cube_1',map.monsterSpawn,ctx.monster_entity_id=='monster_inkwave' and 'monster_inkwave_actor' or (ctx.monster_entity_id or 'monster_cube'),{route=map.patrolRoute})
 local chest=self:spawn('chest_basic','chest_demo',map.chest,'chest_basic',{container_id='chest_demo'})
 -- Exit is a scene marker. Global extraction rules live in Session.
 ctx.services.Characters:spawn(self:request('spawn_exit',{entity_id='gate_exit',instance_id='exit_demo',position_m=map.exit}))
 ctx.services.Assets:instantiate(self:request('asset_exit',{entity_id='gate_exit',instance_id='exit_demo',node_name='gate_exit',position_m=map.exit}))
 inv:_create_container({id='chest_demo',owner_id='chest_demo',slots=8,position_m=map.chest})
 inv:_add_item({container_id='chest_demo',id='treasure_demo',entity_id='item_treasure',count=1})
 inv:_add_item({container_id='chest_demo',id='heal_demo',entity_id='item_heal_small',count=2})
 inv:_add_item({container_id='bag_player_local',id='shovel_local',entity_id='weapon_shovel',count=1})
 local equip=inv:try_equip(self:request('equip_shovel',{owner_instance_id='player_local',item_instance_id='shovel_local',slot_id='weapon'}));if not equip.ok then error(equip.reason)end
 local shovel=ctx:new_entity('weapon_shovel',{id='shovel_local',owner_instance_id='player_local'});assert(shovel:start())
 local heal=ctx:new_entity('item_heal_small',{id='heal_handler',owner_instance_id='player_local'});assert(heal:start())
 self.objects.shovel=shovel;self.objects.heal=heal
 return {player=player,monster=monster,chest=chest,shovel=shovel,heal=heal}
end
function Controller:dispose()
 for _,obj in pairs(self.objects)do if obj.dispose then obj:dispose()end end
 self.objects={}
end
return Controller
