"""Verify the exported GLB and the native editor's fallback animation bank agree."""
from pathlib import Path
import json,struct,hashlib,math
root=Path(__file__).resolve().parents[2]/'gameplay/packages/monsters/monster_inkwave'
b=(root/'model/main.glb').read_bytes();magic,version,length=struct.unpack_from('<III',b)
assert magic==0x46546C67 and version==2 and length==len(b)
jlen,jtype=struct.unpack_from('<II',b,12);assert jtype==0x4E4F534A
j=json.loads(b[20:20+jlen]);start=20+jlen;blen,btype=struct.unpack_from('<II',b,start);assert btype==0x004E4942
binary=b[start+8:start+8+blen]
byname={n.get('name'):n for n in j['nodes']};assert len(byname)==len(j['nodes'])
bank=json.loads((root/'animations/runtime_bank.json').read_text())
assert len(bank['nodes'])==len(j['nodes'])
for n in bank['nodes']:
 g=byname[n['name']]
 for key,other,default in [('position','translation',[0,0,0]),('rotation','rotation',[0,0,0,1]),('scale','scale',[1,1,1])]:
  assert max(abs(a-v) for a,v in zip(n[key],g.get(other,default)))<1e-6,(n['name'],key)
assert {c['name'] for c in bank['clips']}=={'idle','patrol','chase','attack','hit','death'}
assert [c['name'] for c in bank['clips']]==['idle','patrol','chase','attack','hit','death'], 'Editor auto-play must begin with idle'
assert [a['name'] for a in j['animations']]==['idle','patrol','chase','attack','hit','death'], 'Unsafe GLB default animation order'
def floats(accessor):
 a=j['accessors'][accessor];v=j['bufferViews'][a['bufferView']];assert a['componentType']==5126
 dim={'SCALAR':1,'VEC3':3,'VEC4':4}[a['type']];off=v.get('byteOffset',0)+a.get('byteOffset',0)
 return struct.unpack_from('<'+'f'*(a['count']*dim),binary,off)
for gc,bc in zip(j['animations'],bank['clips']):
 assert gc['name']==bc['name'];assert len(gc['channels'])==len(bc['tracks'])
 for ch,track in zip(gc['channels'],bc['tracks']):
  sampler=gc['samplers'][ch['sampler']];target=ch['target'];assert j['nodes'][target['node']]['name']==bank['nodes'][track['node']-1]['name'];assert target['path']==track['path']
  for gi,key in [(sampler['input'],'times'),(sampler['output'],'values')]:
   got=floats(gi);want=track[key];assert len(got)==len(want);assert max(abs(a-v) for a,v in zip(got,want))<1e-6
  assert all(math.isfinite(x) for x in track['values'])
 assert abs(bc['duration']-max(max(t['times']) for t in bc['tracks']))<1e-5
assert len(j['skins'])>=1 and all(len(s['joints'])==87 for s in j['skins'])
assert 'muzzle' in byname and 'weapon_shooter' in byname
report=json.loads((root/'model/asset_audit.json').read_text());report.update({'glbSHA256':hashlib.sha256(b).hexdigest(),'animationBankSHA256':hashlib.sha256((root/'animations/runtime_bank.json').read_bytes()).hexdigest(),'gltfVersion':version,'gltfSkinCount':len(j['skins']),'gltfNodes':len(j['nodes']),'gltfImages':len(j['images']),'bankMatchesGLB':True,'attackWindupSec':.55,'attackDurationSec':1.5,'sourceCommit':'dee4273a49f8839d757a3593a14bf33508f02c15'})
(root/'model/asset_audit.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({k:report[k] for k in ['glbSHA256','glbBytes','triangles','rigBones','gltfSkinCount','gltfImages','bankMatchesGLB']},indent=2))
