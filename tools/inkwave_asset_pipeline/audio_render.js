// Local build page. No match/music state and no realtime sound are started.
import {SFX} from './audio_source/src/audio/audio.js';
import {V, mulberry32} from './audio_source/src/audio/music.js';
const SR=22050;
const requests=[
  ['shoot_a','shoot_shooter',5101],['shoot_b','shoot_shooter',5102],['shoot_c','shoot_shooter',5103],
  ['hit','ink_hit_body',5201],['hurt','hurt',5202],['death','splat_enemy',5301],
  ['step','step_dry',5401],['step_ink','step_ink',5402]
];
window.renderMonsterAudio=async()=>{
  const rendered=[];
  for(const [id,source_name,seed] of requests){
    const ctx=new OfflineAudioContext(1,Math.ceil(SR*1.6),SR);
    const output=ctx.createGain();output.gain.value=SFX[source_name].gain;
    const hp=ctx.createBiquadFilter();hp.type='highpass';hp.frequency.value=25;hp.Q.value=.707;
    output.connect(hp);hp.connect(ctx.destination);
    const voice=new V(ctx,output,0,mulberry32(seed));
    SFX[source_name].build(voice,1);
    const buffer=await ctx.startRendering();const raw=buffer.getChannelData(0);
    const frames=Math.min(raw.length,Math.max(1,Math.ceil((voice.end+.015)*SR)));
    let peak=0;for(let i=0;i<frames;i++)peak=Math.max(peak,Math.abs(raw[i]));
    const ceiling_gain=Math.min(1,.82/(peak||1));
    const samples=new Float32Array(frames);
    for(let i=0;i<frames;i++){
      // Builder envelopes end at zero; a short fade removes any remaining filter tail at asset end.
      const fade=Math.min(1,(frames-1-i)/Math.max(1,Math.round(SR*.005)));
      samples[i]=raw[i]*ceiling_gain*Math.max(0,fade);
    }
    rendered.push({id,source_name,seed,sample_rate:SR,channels:1,frames,
      source_end_sec:voice.end,ceiling_gain,source_gain:SFX[source_name].gain,samples:Array.from(samples)});
  }
  return rendered;
};
