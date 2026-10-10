-- Program-owned native Demo HUD. Visuals are deliberately whitebox references.
local UI={};UI.__index=UI
function UI.new(context,dispatch)
 return setmetatable({context=context,dispatch=dispatch,view=nil,last_refresh=0,rows={}},UI)
end
function UI:start()
 local U=CS.UnityEngine;self.U=U;local V,C=U.Vector2,U.Color
 local fonts=U.Resources.FindObjectsOfTypeAll(typeof(U.Font));for i=0,fonts.Length-1 do if fonts[i].name=='NotoSansSC-Medium'then self.font=fonts[i];break end end
 self.font=self.font or U.Font.CreateDynamicFontFromOSFont('PingFang SC',20)
 self.root=U.GameObject('demo_ui');self.root.transform:SetParent(self.context.adapter.runtime_root.transform,false)
 local canvas=self.root:AddComponent(typeof(U.Canvas));canvas.renderMode=U.RenderMode.ScreenSpaceOverlay;canvas.sortingOrder=160
 local scaler=self.root:AddComponent(typeof(U.UI.CanvasScaler));scaler.uiScaleMode=U.UI.CanvasScaler.ScaleMode.ScaleWithScreenSize;scaler.referenceResolution=V(1280,720);scaler.matchWidthOrHeight=.5
 self.root:AddComponent(typeof(U.UI.GraphicRaycaster))
 local top=self:panel(self.root,'hud',0,-58,900,94,C(.035,.065,.1,.94),V(.5,1))
 self.title=self:text(top,'title','仔仔搜打撤1.0',0,24,860,32,22)
 self.status=self:text(top,'status','初始化中',0,-3,860,25,17)
 self.hint=self:text(top,'objective','探索四房 → 开宝箱 → 收集 / 用药 → 绿色区域撤离',0,-30,860,25,15)
 self.notice=self:text(self.root,'notice','',0,102,950,36,18,V(.5,0))
 self.help=self:text(self.root,'help','WASD 移动  Shift 冲刺  Ctrl 蹲行  E 交互  F 铲击  B 背包  H 用药',0,34,1050,26,15,V(.5,0))
 self:button(self.root,'interact','交互 / E',-100,175,170,44,function()self.dispatch('interact')end,V(1,0))
 self:button(self.root,'attack','铲击 / F',-100,226,170,44,function()self.dispatch('attack')end,V(1,0))
 self:button(self.root,'heal','用药 / H',-100,277,170,44,function()self.dispatch('heal')end,V(1,0))
 self:button(self.root,'bag','背包 / B',-100,-141,170,38,function()self.dispatch('bag')end,V(1,1))
 self:button(self.root,'attributes','角色 / 怪物属性',-100,-186,170,38,function()self.dispatch('attributes')end,V(1,1))
 self:button(self.root,'qa','验证 Demo',-100,-231,170,38,function()self.dispatch('qa')end,V(1,1))
 self.modal=self:panel(self.root,'modal',0,0,660,440,C(.04,.075,.115,.99));self.modal:GetComponent(typeof(U.UI.Image)).raycastTarget=true
 self.modal_title=self:text(self.modal,'modal_title','背包',0,182,600,36,24)
 self.modal_hint=self:text(self.modal,'modal_hint','',0,-112,580,45,16)
 self:button(self.modal,'close','关闭',263,182,98,35,function()self.dispatch('close')end)
 self.take=self:button(self.modal,'take_all','全部拾取',0,-182,170,42,function()self.dispatch('take_all')end)
 self.modal:SetActive(false)
 self.result_panel=self:panel(self.root,'result',0,0,660,340,C(.03,.07,.105,.99));self.result_panel:GetComponent(typeof(U.UI.Image)).raycastTarget=true
 self.result_text=self:text(self.result_panel,'result_text','',0,25,610,210,22)
 self:button(self.result_panel,'restart','重新开始',0,-120,190,44,function()self.dispatch('restart')end)
 self.result_panel:SetActive(false)
 self.started=true;return true
end
function UI:panel(parent,name,x,y,w,h,color,anchor)
 local U=self.U;local go=U.GameObject('demo_ui_'..name);go.transform:SetParent(parent.transform,false)
 local rect=go:AddComponent(typeof(U.RectTransform));rect.anchorMin=anchor or U.Vector2(.5,.5);rect.anchorMax=rect.anchorMin;rect.sizeDelta=U.Vector2(w,h);rect.anchoredPosition=U.Vector2(x,y)
 local image=go:AddComponent(typeof(U.UI.Image));image.color=color;image.raycastTarget=false;return go
end
function UI:text(parent,name,value,x,y,w,h,size,anchor)
 local U=self.U;local go=U.GameObject('demo_ui_'..name);go.transform:SetParent(parent.transform,false)
 local rect=go:AddComponent(typeof(U.RectTransform));rect.anchorMin=anchor or U.Vector2(.5,.5);rect.anchorMax=rect.anchorMin;rect.sizeDelta=U.Vector2(w,h);rect.anchoredPosition=U.Vector2(x,y)
 local label=go:AddComponent(typeof(U.UI.Text));label.font=self.font;label.fontSize=size;label.text=value;label.color=U.Color(.91,.96,1,1);label.alignment=U.TextAnchor.MiddleCenter;label.raycastTarget=false;return label
end
function UI:button(parent,name,value,x,y,w,h,fn,anchor)
 local U=self.U;local go=self:panel(parent,name,x,y,w,h,U.Color(.14,.3,.39,1),anchor)
 local image=go:GetComponent(typeof(U.UI.Image));image.raycastTarget=true
 local button=go:AddComponent(typeof(U.UI.Button));button.targetGraphic=image;button.onClick:AddListener(fn)
 self:text(go,name..'_label',value,0,0,w-6,h-4,16);return go
end
function UI:open(view,request)
 self.view=view;self.view_request=request or{};self.modal:SetActive(true);self:refresh_modal()
end
function UI:close()self.view=nil;self.modal:SetActive(false)end
function UI:refresh_modal()
 local ctx=self.context;local s=ctx.state
 for _,go in ipairs(self.rows)do self.U.Object.Destroy(go)end;self.rows={}
 self.take:SetActive(self.view=='chest')
 if self.view=='attributes'then
  local p=ctx.services.Characters:read_snapshot({run_id=s.run_id,instance_id='player_local'}).data
  local m=ctx.services.Characters:read_snapshot({run_id=s.run_id,instance_id=ctx.monster_instance_id or 'monster_cube_1'}).data
  local d=ctx.definitions[ctx.monster_entity_id or 'monster_cube']
  self.modal_title.text='Demo · 公共属性与对象挂钩'
  local content='角色 HP '..tostring(p.hp)..' / '..tostring(p.max_hp)..'\n步行 '..ctx.config.player.walkSpeedMps..'  冲刺 '..ctx.config.player.sprintSpeedMps..'  蹲行 '..ctx.config.player.crouchSpeedMps..' m/s\n出生保护 '..ctx.config.player.spawnProtectionSec..' s  受击保护 '..ctx.config.player.hitInvulnerabilitySec..' s\n墨潮怪物 HP '..tostring(m.hp)..' / '..tostring(m.max_hp)..'\n视距 '..d.sense.rangeM..' m  视角 '..d.sense.fullAngleDeg..'°\n怪物伤害 '..d.attacks[1].damageHp..'  铲伤害 '..ctx.definitions.weapon_shovel.attack.damageHp
  if ctx.adapter.inkwave then
   local v=ctx.adapter.inkwave:status();local pos=ctx.adapter:position('player_local')
   content=content..'\n导入蒙皮 '..tostring(v.skin_count or'-')..' · 绑定骨骼 '..tostring(v.skin_bone_count or'-')..'\n头脚高度 '..string.format('%.2f',v.head_foot_height_m or 0)..' m · 枪口朝向 '..string.format('%.2f',v.muzzle_forward_dot or 0)..'\n玩家坐标 '..string.format('%.1f / %.1f',pos.x,pos.z)..' · 动作 '..tostring(v.clip)
  end
  local label=self:text(self.modal,'attributes_body',content,0,20,610,255,16);self.rows[1]=label.gameObject
  self.modal_hint.text='逻辑属性调整后重启预览 · 实际速度 '..tostring(ctx.adapter.speed_readback or'未映射')..' · 胶囊 '..(ctx.adapter.collider_apply_ok and'已映射'or'待 SDK 映射')
  return
 end
 local chest=self.view=='chest'
 local snap=ctx.services.Inventory:read_snapshot({run_id=s.run_id,container_id=chest and'chest_demo'or'bag_player_local'})
 local bag=snap.data.bag or{items={},slots=12}
 self.modal_title.text=(chest and'补给宝箱'or'随身背包')..'  '..#bag.items..' / '..bag.slots..' 格'
 for i,item in ipairs(bag.items)do
  local item_id=item.id;local def=ctx.definitions[item.entity_id]or{}
  local value=(def.displayName or item.entity_id)..' ×'..item.count..(chest and' · 拾取'or(item.entity_id=='item_heal_small'and' · 使用'or' · 藏品'))
  self.rows[#self.rows+1]=self:button(self.modal,'item_'..i,value,0,118-(i-1)*54,550,43,function()self.dispatch(chest and'pickup'or'use_item',item_id)end)
 end
 self.modal_hint.text=chest and'拾取走统一库存事务；再次打开不会重抽物品。'or'药品恢复 30 HP，读条 1.2 秒；满血或中断不消耗。'
end
function UI:update_snapshot(r)if self.view then self:refresh_modal()end end
function UI:update(dt)
 if not self.started then return end
 local ctx=self.context;local s=ctx.state;local p=s.entities.player_local;local m=s.entities[ctx.monster_instance_id or 'monster_cube_1']
 local remaining=math.max(0,ctx.config.session.roundDurationSec-s.clock)
 self.status.text='HP '..tostring(p and p.hp or'-')..' / '..ctx.config.player.maxHp..'    时间 '..math.floor(remaining/60)..':'..string.format('%02d',math.floor(remaining%60))..'    怪物 HP '..tostring(m and m.hp or'-')..'    '..tostring(s.phase)
 local bag=s.containers.bag_player_local;local count=bag and#bag.items or 0
 self.hint.text='背包 '..count..' / '..ctx.config.inventory.bagSlots..'    怪物：'..tostring(ctx.demo and ctx.demo.objects.monster.ai_state or'等待')..'    搜集后回绿色区域撤离'
 if ctx.adapter.inkwave then local v=ctx.adapter.inkwave:status();self.hint.text=self.hint.text..' · 骨骼 '..tostring(v.clip)..' / '..v.changed_bone_frames end
 if s.extract then self.hint.text='撤离中 '..string.format('%.1f',math.max(0,ctx.config.session.extractionHoldSec-(s.clock-s.extract.started_at)))..' 秒 · 离区或受击取消'end
 self.notice.text=s.toast or''
 if ctx.demo and ctx.demo.qa_summary then self.notice.text=ctx.demo.qa_summary end
 local heal=ctx.demo and ctx.demo.objects.heal
 if heal and heal.cast then self.notice.text='用药读条 '..string.format('%.1f',heal:get_status().progress_sec)..' / 1.2 秒'end
 self.result_panel:SetActive(s.result~=nil)
 if s.result then
  self.result_text.text=(s.result.success and'撤离成功'or'探索失败')..'\n带出价值：'..s.result.loot_value..'\n结果原因：'..s.result.reason..'\n结算 ID：'..s.result.result_id..'\n本地 Demo：仓库 / 商店 / 多人另行接入'
 end
 if self.view and ((self.view=='attributes'and s.clock-self.last_refresh>=.5)or self.last_inventory_version~=s.inventory_version)then self.last_refresh=s.clock;self.last_inventory_version=s.inventory_version;self:refresh_modal()end
end
function UI:dispose()self.started=false;if self.root then self.U.Object.Destroy(self.root)end end
return UI
