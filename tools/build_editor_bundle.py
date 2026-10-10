#!/usr/bin/env python3
"""Generate the native editor wrapper from canonical static Lua modules."""
from pathlib import Path
import json, re
from bundle_lua import bundle
ROOT=Path(__file__).resolve().parents[1]
ENTRY_ID='b680ca44-9e0d-4880-9820-65899787da8d'
source,count=bundle(ROOT,'gameplay.demo')
source=source.replace('-- Generated project scaffold bundle. SDK mapping and gameplay remain unimplemented.','-- Generated canonical Demo bundle. Native SDK mapping is isolated in zaizai adapter.')
header=f'''---@id {ENTRY_ID}
---@referenceName demo_entry.lua
---@start
---@end
local Demo = (function()
'''
tail='''
end)()
local instance
local failed=false
local unpack_args=table.unpack or unpack
local function invoke(method,...)
 if failed or not instance then return end
 local args={...}
 local ok,err=pcall(function()return instance[method](instance,unpack_args(args))end)
 if not ok then
  failed=true
  CS.UnityEngine.Debug.LogError('[ZZ_DEMO_ERROR] '..tostring(err))
  if instance.ui and instance.ui.notice then instance.ui.notice.text='Demo错误：'..tostring(err)end
 end
end
function Start()
 instance=Demo.new(self.gameObject)
 -- Child property scripts must finish loading before their profiles are read.
 instance.pending=true
end
function Update() invoke('update',CS.UnityEngine.Time.unscaledDeltaTime)end
function OnDestroy()if instance then pcall(function()instance:dispose()end)end end
function GetStatus()return failed and 'FAILED'or(instance and instance.started and 'READY'or'WAIT_ACTOR')end
function GetSnapshot()return instance and instance:GetSnapshot()or{ready=false}end
function GetQAResults()return instance and instance.qa_results or{}end
return {GetStatus=GetStatus,GetSnapshot=GetSnapshot,GetQAResults=GetQAResults}
'''
out=ROOT/'scripts/modules';out.mkdir(parents=True,exist_ok=True)
(out/'demo_entry.lua').write_text(header+source+tail,encoding='utf-8')
for name in ('player_attributes','monster_attributes','match_attributes'):
 (out/(name+'.lua')).write_text((ROOT/'gameplay/adapters/zaizai'/(name+'.lua')).read_text(),encoding='utf-8')
print(json.dumps({'modules':count,'entry':str(out/'demo_entry.lua'),'propertyScripts':3},ensure_ascii=False))
