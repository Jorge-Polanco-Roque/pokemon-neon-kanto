#!/usr/bin/env python3
"""Original deterministic score. Python 3 + numpy; no samples or MIDI downloads."""
from pathlib import Path
import json, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/audio/music'
SR=44100
# Original motifs, expressed as semitones above a tonal center. None transcribed.
PHRASES=[
 [0,7,12,10,7,3,5,7, 10,7,5,3,2,5,7,-99],
 [0,3,7,14,12,7,10,5, 3,5,7,3,2,-1,2,7],
 [12,10,7,5,7,10,14,12, 10,7,3,5,2,7,5,-99],
 [7,8,7,3,5,2,3,0, -1,2,5,8,7,5,2,-99],
]
def tone(midi,seconds,kind):
 t=np.arange(max(32,int(seconds*SR)))/SR
 f=440*2**((midi-69)/12)
 phase=2*np.pi*f*t+.012*np.sin(2*np.pi*5.2*t)
 if kind=='pulse':
  x=sum(np.sin(h*phase)*np.sin(np.pi*h*.25)/h for h in range(1,14))*.8
 elif kind=='arp': x=sum(np.sin(h*phase)/h for h in [1,3,5,7])*.7
 elif kind=='bass': x=.65*np.sin(phase+1.25*np.exp(-t*13)*np.sin(2*phase))+.18*np.sin(phase/2)
 else: x=np.sin(phase+2*np.exp(-t*8)*np.sin(phase*2.002))*.7
 env=np.minimum(1,t/.004)*np.minimum(1,(seconds-t)/.016)*np.exp(-t*(2.3 if kind in ['arp','bell'] else .75))
 return x*env

def render(key,bpm,root,bars,energy,variant):
 rng=np.random.default_rng(7200+variant)
 beat=60/bpm
 frames=round(bars*4*beat*SR)
 mix=np.zeros((frames,2),dtype=np.float64)
 def add(x,start,gain,pan=0,echo=False):
  start=round(start*SR)
  def layer(offset,level,p):
   ids=(start+offset+np.arange(len(x)))%frames
   np.add.at(mix[:,0],ids,x*level*np.sqrt((1-p)/2))
   np.add.at(mix[:,1],ids,x*level*np.sqrt((1+p)/2))
  layer(0,gain,pan)
  if echo:
   layer(round(beat*.75*SR),gain*.22,-pan)
   layer(round(beat*1.5*SR),gain*.08,pan)
 def hit(at,kind,gain):
  dur=.22 if kind!='hat' else .045
  t=np.arange(int(dur*SR))/SR
  if kind=='kick': x=np.sin(2*np.pi*(49*t+2.4*(1-np.exp(-t*35))))*np.exp(-t*22)
  elif kind=='snare': x=(rng.uniform(-1,1,len(t))*.75+np.sin(2*np.pi*185*t)*.25)*np.exp(-t*26)
  else: x=(rng.uniform(-1,1,len(t)))*np.exp(-t*95)
  x*=np.minimum(1,t/.001)*np.minimum(1,(dur-t)/.008)
  add(x,at,gain,.25 if kind=='hat' else 0)
 progression=[0,0,-4,-2,0,3,-4,-1]
 for bar in range(bars):
  shift=progression[(bar//2)%8] if key!='victory' else [0,5,7,0][bar%4]
  base=root+shift
  phrase=PHRASES[(bar//2+variant)%4]
  if key=='victory': phrase=[0,4,7,12,7,12,16,19]*2
  if key=='title':
   add(tone(base+12,beat*3.6,'bell'),bar*4*beat,.045,-.4,True)
   add(tone(base+19,beat*3.6,'bell'),(bar*4+.5)*beat,.028,.4,True)
  # Rhythmic lead with short rests, answer phrases, and second-half variation.
  for step in range(8):
   pitch=phrase[(bar%2)*8+step]
   if pitch==-99 or (energy<.5 and step%2): continue
   octave=12 if bar>=bars//2 and bar%4==3 else 0
   add(tone(base+24+pitch+octave,beat*(.82 if energy<.5 else .39),'pulse'),(bar*4+step*.5)*beat,.135 if energy>.5 else .085,-.12,True)
  # Bass and a fast, quiet second pulse channel form the chip backbone.
  for step in range(8):
   add(tone(base+[0,0,12,7][step%4],beat*.43,'bass'),(bar*4+step*.5)*beat,.21)
  chord=[0,3,7,12] if key!='victory' else [0,4,7,12]
  for step in range(16):
   if energy<.5 and step%2: continue
   note=base+12+chord[(step+bar)%4]
   add(tone(note,beat*.21,'arp'),(bar*4+step*.25)*beat,.042,.55 if step%2 else -.55)
  # Distinct arrangement: half-time refuge, driving wild, syncopated trainer, industrial guardian.
  for step in range(16):
   when=(bar*4+step*.25)*beat
   if step in ([0,8] if energy<.5 else ([0,6,8,11] if variant==1 else [0,8,10])): hit(when,'kick',.25*max(.5,energy))
   if step in [4,12]: hit(when,'snare',.115*energy)
   if step%2==0: hit(when,'hat',.055*energy)
   if bar%4==3 and step>=13 and energy>.5: hit(when,'snare',.065*energy)
  if bar%4 in [0,2]: add(tone(base+36,beat*1.7,'bell'),bar*4*beat,.065,.35,True)
 # Parallel soft saturation. Constant gain retains dynamics and leaves headroom.
 mix=np.tanh(mix*1.25)*.8
 peak=float(np.max(np.abs(mix)))
 mix*=.46/max(peak,.001)
 # 2ms anti-click at the exact loop seam, not a long fade/pause.
 ramp=np.linspace(0,1,int(.002*SR));mix[:len(ramp)]*=ramp[:,None];mix[-len(ramp):]*=ramp[::-1,None]
 pcm=np.round(mix*32767).astype('<i2')
 OUT.mkdir(parents=True,exist_ok=True)
 with wave.open(str(OUT/(key+'.wav')),'wb') as w:
  w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
 return {'key':key,'bpm':bpm,'bars':bars,'seconds':frames/SR,'peak_dbfs':round(20*np.log10(np.max(np.abs(mix))),2),'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(mix**2))),2),'loop':key!='victory','clipped_samples':int(np.sum(np.abs(pcm.astype(np.int32))>=32767)),'seam_step':float(np.max(np.abs(mix[0]-mix[-1])))}
if __name__=='__main__':
 tracks=[render(*args) for args in [('title',84,42,16,.28,2),('world',100,45,16,.4,0),('wild',156,45,32,.85,0),('trainer',164,47,32,.95,1),('warden',176,42,32,1.0,2),('victory',136,48,4,.6,3)]]
 (OUT/'manifest.json').write_text(json.dumps({'version':1,'provenance':'Original algorithmic score; synthesized oscillators and seeded noise; no third-party recordings, MIDI or samples.','sample_rate':SR,'tracks':tracks},indent=2)+'\n')
 print(json.dumps(tracks,indent=2))
