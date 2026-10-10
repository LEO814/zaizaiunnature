-- Geometry for the authored whitebox. No SDK globals and no object AI.
local Spatial={}
function Spatial.distance(a,b)local x,z=a.x-b.x,a.z-b.z;return math.sqrt(x*x+z*z)end
function Spatial.blocked(a,b,walls,padding)
 padding=padding or 0
 for _,w in ipairs(walls)do
  local lo,hi=0,1
  local valid=true
  for _,axis in ipairs({'x','z'})do
   local av,bv=a[axis],b[axis];local d=bv-av
   local size=axis=='x'and w.sx or w.sz
   local mn,mx=w[axis]-size/2-padding,w[axis]+size/2+padding
   if math.abs(d)<0.00001 then if av<mn or av>mx then valid=false end
   else local t1,t2=(mn-av)/d,(mx-av)/d;if t1>t2 then t1,t2=t2,t1 end;lo=math.max(lo,t1);hi=math.min(hi,t2);if lo>hi then valid=false end end
  end
  if valid and lo<=hi and hi>=0 and lo<=1 then return true end
 end
 return false
end
function Spatial.path(a,b,map,radius)
 radius=radius or 0.35
 if not Spatial.blocked(a,b,map.walls,radius)then return {{x=b.x,y=a.y,z=b.z}}end
 local function key(x,z)return x..':'..z end
 local function walkable(x,z)
  local bounds=map.bounds
  if x<bounds.min_x+radius or x>bounds.max_x-radius or z<bounds.min_z+radius or z>bounds.max_z-radius then return false end
  return not Spatial.blocked({x=x,y=0,z=z},{x=x,y=0,z=z},map.walls,radius)
 end
 local sx,sz=math.floor(a.x+0.5),math.floor(a.z+0.5)
 local tx,tz=math.floor(b.x+0.5),math.floor(b.z+0.5)
 if not walkable(tx,tz)then return nil,'NO_PATH'end
 local q,head,parent,seen={{x=sx,z=sz}},1,{},{};seen[key(sx,sz)]=true
 local endkey
 while head<=#q and head<1700 do
  local p=q[head];head=head+1;local k=key(p.x,p.z)
  if p.x==tx and p.z==tz then endkey=k;break end
  for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do
   local x,z=p.x+d[1],p.z+d[2];local nk=key(x,z)
   if not seen[nk]then
    seen[nk]=true
    if walkable(x,z)and not Spatial.blocked({x=p.x,z=p.z},{x=x,z=z},map.walls,radius)then parent[nk]=k;q[#q+1]={x=x,z=z}end
   end
  end
 end
 if not endkey then return nil,'NO_PATH'end
 local reverse,k={},endkey
 while k~=key(sx,sz)do
  local x,z=k:match('([^:]+):([^:]+)');reverse[#reverse+1]={x=tonumber(x),y=a.y,z=tonumber(z)};k=parent[k];if not k then return nil,'NO_PATH'end
 end
 local out={};for i=#reverse,1,-1 do out[#out+1]=reverse[i]end
 if not Spatial.blocked(out[#out]or a,b,map.walls,radius)then out[#out+1]={x=b.x,y=a.y,z=b.z}end
 return out
end
return Spatial
