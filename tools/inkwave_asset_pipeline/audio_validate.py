#!/usr/bin/env python3
"""Independent WAV/manifest checks plus real Lua 5.1/5.4 decoder execution.

Install the project's optional lupa==2.6 QA dependency, or set PYTHONPATH to a
temporary directory containing it. This script never runs the editor.
"""
import base64
import hashlib
import json
import math
import re
import struct
import wave
from pathlib import Path
from lupa import lua51, lua54

HERE=Path(__file__).resolve().parent
OUT=HERE.parents[1]/'gameplay/packages/monsters/monster_inkwave/audio'

def sha(data): return hashlib.sha256(data).hexdigest()

def reference_sample(byte):
    bits=(~byte)&255
    sample=(((bits&15)<<3)+132)<<(bits>>4&7)
    sample-=132
    return (-sample if bits&128 else sample)/32768.0

def main():
    manifest=json.loads((OUT/'manifest.json').read_text())
    bank_source=(OUT/'pcm_bank.lua').read_text()
    assert len(manifest['clips'])==8
    assert sha(bank_source.encode())==manifest['bank_lua_sha256']
    assert len(bank_source.encode())<70000
    for source in manifest['source_files']:
        assert sha((HERE/source['path']).read_bytes())==source['sha256']
    wav_results=[]
    expected={}
    for clip in manifest['clips']:
        raw=(OUT/clip['wav']).read_bytes()
        assert sha(raw)==clip['wav_sha256']
        with wave.open(str(OUT/clip['wav']),'rb') as wav:
            assert (wav.getnchannels(),wav.getframerate(),wav.getsampwidth(),wav.getnframes())==(1,22050,2,clip['frames'])
            ints=struct.unpack('<'+'h'*clip['frames'],wav.readframes(clip['frames']))
        reference=[x/32767.0 for x in ints]
        assert .001<max(map(abs,reference))<.821
        assert any(reference) and abs(reference[-1])<1e-5
        match=re.search(r'\b'+re.escape(clip['id'])+r'=\{frames=\d+,source_name="[^"]+",data="([^"]+)"',bank_source)
        assert match,clip['id']
        encoded=base64.b64decode(match.group(1),validate=True)
        assert len(encoded)==clip['frames'] and sha(encoded)==clip['bank_sha256']
        expected[clip['id']]=[reference_sample(x) for x in encoded]
        power=sum(x*x for x in reference)
        noise=sum((x-y)**2 for x,y in zip(reference,expected[clip['id']]))
        snr=10*math.log10(power/noise)
        assert snr>35, (clip['id'],snr)
        wav_results.append({'id':clip['id'],'frames':clip['frames'],'duration_sec':len(reference)/22050,'peak':max(map(abs,reference)),'rms':math.sqrt(power/len(reference)),'mu_law_snr_db_vs_pcm16':snr})
    lua_results=[]
    for module in (lua51,lua54):
        runtime=module.LuaRuntime(unpack_returned_tuples=True)
        bank=runtime.execute(bank_source)
        samples_checked=0
        assert bank['new_decoder']('absent')==(None,'UNKNOWN_CLIP')
        for clip in manifest['clips']:
            decoder=bank['new_decoder'](clip['id'])
            assert decoder['total_frames']==clip['frames'] and decoder['sample_rate']==22050
            writes={}
            def sink(index,value):
                assert index not in writes
                writes[index]=value
            lua_sink=runtime.eval('function(py) return function(i,v) py(i,v) end end')(sink)
            total=0
            while True:
                done,written=decoder['step'](decoder,997,lua_sink)
                assert 0<written<=997
                total+=written
                if done: break
            assert total==clip['frames'] and len(writes)==total
            assert decoder['step'](decoder,997,lua_sink)==(True,0)
            for index,value in writes.items(): assert value==expected[clip['id']][index]
            decoded,sr=bank['decode'](clip['id'])
            assert sr==22050 and len(decoded)==clip['frames']
            for index,value in enumerate(expected[clip['id']]): assert decoded[index+1]==value
            samples_checked+=total
        lua_results.append({'runtime':runtime.lua_implementation,'samples_checked':samples_checked,'chunked_decoder':True,'one_shot_decoder':True,'missing_clip_rejected':True})
    result={'status':'PASS','clips':wav_results,'lua_runtimes':lua_results,'bank_lua_bytes':len(bank_source.encode()),'editor_audio_playback_verified':False,
            'scope':'Offline waveform validation and real Lua PCM decoding; native AudioClip/AudioSource playback must be verified by integration.'}
    (OUT/'validation.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps(result,ensure_ascii=False))

if __name__=='__main__':main()
