// Rebuild only monster_inkwave/audio. Runs public SFX builders in a local offline Web Audio context.
import {createServer} from 'node:http';
import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {dirname,resolve,extname,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const HERE=dirname(fileURLToPath(import.meta.url));
const PROJECT=resolve(HERE,'../..');
const OUTPUT=resolve(PROJECT,'gameplay/packages/monsters/monster_inkwave/audio');
const {chromium}=await import(process.env.PLAYWRIGHT_MODULE||'/Users/bytedance/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs');
const sha256=data=>createHash('sha256').update(data).digest('hex');
function encodeMulaw(sample){
 let v=Math.round(Math.max(-1,Math.min(1,sample))*32767);const sign=v<0?128:0;
 v=Math.min(Math.abs(v),32635)+132;let exponent=7;
 for(let mask=0x4000;exponent>0&&(v&mask)===0;mask>>=1)exponent--;
 const mantissa=(v>>(exponent+3))&15;return (~(sign|(exponent<<4)|mantissa))&255;
}
function decodeMulaw(byte){const u=255-byte;const value=(((u&15)*8+132)*2**((u>>4)&7))-132;return (u&128?-value:value)/32768;}
function wav(samples,sr){
 const out=Buffer.alloc(44+samples.length*2);out.write('RIFF');out.writeUInt32LE(out.length-8,4);out.write('WAVE',8);
 out.write('fmt ',12);out.writeUInt32LE(16,16);out.writeUInt16LE(1,20);out.writeUInt16LE(1,22);
 out.writeUInt32LE(sr,24);out.writeUInt32LE(sr*2,28);out.writeUInt16LE(2,32);out.writeUInt16LE(16,34);
 out.write('data',36);out.writeUInt32LE(samples.length*2,40);
 for(let i=0;i<samples.length;i++)out.writeInt16LE(Math.round(Math.max(-1,Math.min(1,samples[i]))*32767),44+i*2);
 return out;
}
const mime={'.html':'text/html','.js':'text/javascript','.json':'application/json'};
const server=createServer(async(req,res)=>{try{
 const pathname=decodeURIComponent(req.url.split('?')[0]);const file=resolve(HERE,'.'+pathname);
 if(!file.startsWith(HERE+'/'))throw Error('outside build root');
 const data=await readFile(file);res.setHeader('Content-Type',mime[extname(file)]||'application/octet-stream');res.end(data);
 }catch(e){res.statusCode=404;res.end(String(e));}});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
let browser;
try{
 browser=await chromium.launch({executablePath:process.env.CHROME_BINARY||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,timeout:180000});
 const page=await browser.newPage();page.on('pageerror',e=>console.error(e));
 await page.goto(`http://127.0.0.1:${server.address().port}/audio_render.html`);
 await page.waitForFunction(()=>typeof window.renderMonsterAudio==='function');
 const rendered=await page.evaluate(()=>window.renderMonsterAudio());
 await mkdir(OUTPUT,{recursive:true});await copyFile(resolve(HERE,'audio_source/LICENSE'),resolve(OUTPUT,'LICENSE'));
 const clips={},manifest={schema_version:1,sample_rate:22050,channels:1,wav_encoding:'PCM16LE',bank_encoding:'G.711 mu-law 8bit base64',
  source_repository:'https://github.com/ENTROVIA/inkwave-main',source_commit:'dee4273a49f8839d757a3593a14bf33508f02c15',
  source_license:'MIT; Copyright (c) 2026 Jayden Davis',source_files:[],
  method:'Direct upstream SFX.build and V through Chrome OfflineAudioContext. Dry mono one-shots; source gains and deterministic seeds retained. Fixed pitch=1, 25Hz highpass, peak ceiling0.82, 5ms end fade. Original random pitch jitter, runtime HRTF, music, shared plaza reverb, master buses/compressors/limiter are not baked; editor applies 3D attenuation/pitch. Lua bank is a lossy mu-law quantization of these PCM16 WAVs.',clips:[]};
 const audition=[];
 for(const c of rendered){
  if(c.samples.some(v=>!Number.isFinite(v)))throw Error(`${c.id}: nonfinite sample`);
  const encoded=Buffer.from(c.samples.map(encodeMulaw));const decoded=Array.from(encoded,decodeMulaw);
  const wave=wav(c.samples,c.sample_rate);await writeFile(resolve(OUTPUT,`${c.id}.wav`),wave);
  let peak=0,power=0,error=0,nonzero=0,mean=0,decodedPeak=0;
  for(let i=0;i<c.samples.length;i++){const s=c.samples[i];peak=Math.max(peak,Math.abs(s));decodedPeak=Math.max(decodedPeak,Math.abs(decoded[i]));power+=s*s;error+=(s-decoded[i])**2;mean+=s;if(s!==0)nonzero++;}
  const snr_db=10*Math.log10(power/Math.max(error,1e-20));
  if(peak<=.001||peak>.821||nonzero<30||snr_db<25)throw Error(`${c.id}: waveform quality failed`);
  const entry={id:c.id,source_name:c.source_name,seed:c.seed,frames:c.frames,duration_sec:c.frames/c.sample_rate,sample_rate:c.sample_rate,channels:1,
   peak,rms:Math.sqrt(power/c.frames),dc_mean:mean/c.frames,nonzero_samples:nonzero,mu_law_snr_db:snr_db,mu_law_peak:decodedPeak,
   source_gain:c.source_gain,ceiling_gain:c.ceiling_gain,wav:`${c.id}.wav`,wav_bytes:wave.length,wav_sha256:sha256(wave),bank_bytes:encoded.length,bank_sha256:sha256(encoded)};
  manifest.clips.push(entry);clips[c.id]={frames:c.frames,source_name:c.source_name,data:encoded.toString('base64')};
  audition.push(...decoded,...Array(Math.round(c.sample_rate*.14)).fill(0));
 }
 for(const file of ['audio_source/src/audio/audio.js','audio_source/src/audio/music.js','audio_source/src/config.js','audio_source/LICENSE']){const data=await readFile(resolve(HERE,file));manifest.source_files.push({path:file,bytes:data.length,sha256:sha256(data)});}
 const template=await readFile(resolve(HERE,'audio_bank_runtime.lua.in'),'utf8');
 const literal=Object.entries(clips).map(([id,c])=>` ${id}={frames=${c.frames},source_name=${JSON.stringify(c.source_name)},data=${JSON.stringify(c.data)}},`).join('\n');
 const bank=template.replace('__CLIPS__',literal);await writeFile(resolve(OUTPUT,'pcm_bank.lua'),bank);
 manifest.bank_lua_bytes=Buffer.byteLength(bank);manifest.bank_lua_sha256=sha256(bank);manifest.total_frames=manifest.clips.reduce((a,c)=>a+c.frames,0);
 const auditionWav=wav(audition,22050);await writeFile(resolve(OUTPUT,'audition_bank.wav'),auditionWav);
 manifest.audition_order=manifest.clips.map(c=>c.id);manifest.audition_gap_sec=.14;manifest.audition_wav_sha256=sha256(auditionWav);
 await writeFile(resolve(OUTPUT,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
 console.log(JSON.stringify({output:relative(PROJECT,OUTPUT),clips:manifest.clips.map(({id,duration_sec,peak,mu_law_snr_db})=>({id,duration_sec,peak,mu_law_snr_db})),bank_lua_bytes:manifest.bank_lua_bytes,total_frames:manifest.total_frames}));
}finally{if(browser)await browser.close();server.close();}
