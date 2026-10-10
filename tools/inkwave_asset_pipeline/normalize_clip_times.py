"""Normalize Blender NLA time and put idle first for editor auto-play safety."""
from pathlib import Path
import json,struct
p=Path(__file__).resolve().parents[2]/'gameplay/packages/monsters/monster_inkwave/model/main.glb'
raw=p.read_bytes();jlen,_=struct.unpack_from('<II',raw,12);g=json.loads(raw[20:20+jlen]);binary=bytearray(raw[28+jlen:]);inputs={s['input'] for a in g['animations'] for s in a['samplers']}
alltimes=[];offsets={}
for ai in inputs:
 a=g['accessors'][ai];v=g['bufferViews'][a['bufferView']];assert a['componentType']==5126 and a['type']=='SCALAR';start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',4)
 values=[struct.unpack_from('<f',binary,start+i*stride)[0] for i in range(a['count'])];offsets[ai]=(start,stride,values);alltimes.extend(values)
delta=min(alltimes)
assert 0<=delta<=1/30+.00001,(delta,'unexpected exporter timeline')
if delta>1e-7:
 for ai,(start,stride,values) in offsets.items():
  times=[max(0,v-delta) for v in values]
  for i,t in enumerate(times):struct.pack_into('<f',binary,start+i*stride,t)
  g['accessors'][ai]['min']=[min(times)];g['accessors'][ai]['max']=[max(times)]
clip_order=['idle','patrol','chase','attack','hit','death']
by_name={a['name']:a for a in g['animations']}
assert len(by_name)==len(clip_order) and set(by_name)==set(clip_order), 'Unexpected or duplicate monster clips'
g['animations']=[by_name[name] for name in clip_order]
encoded=json.dumps(g,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4);binary+=b'\0'*((-len(binary))%4)
p.write_bytes(struct.pack('<III',0x46546C67,2,12+8+len(encoded)+8+len(binary))+struct.pack('<II',len(encoded),0x4E4F534A)+encoded+struct.pack('<II',len(binary),0x004E4942)+binary)
print('NLA time offset removed:',delta)
print('Safe default animation order:',clip_order)
