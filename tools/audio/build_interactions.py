#!/usr/bin/env python3
"""Original deterministic one-shot synthesis; no external samples."""
from pathlib import Path
import wave,json
import numpy as np
OUT=Path(__file__).resolve().parents[2]/'assets/audio/interactions'
SR=44100
OUT.mkdir(parents=True,exist_ok=True)
manifest={}
for index,(key,duration) in enumerate([('step',.14),('ui',.085),('terminal',.48),('heal',1.35)]):
 t=np.arange(round(SR*duration))/SR
 rng=np.random.default_rng(2800+index)
 if key=='step':
  noise=rng.normal(0,1,len(t)); noise=np.convolve(noise,np.ones(7)/7,mode='same')
  signal=.55*noise*np.exp(-t*42)+.35*np.sin(2*np.pi*(100*t-80*t*t))*np.exp(-t*35)
 elif key=='ui': signal=(np.sin(2*np.pi*880*t)+.2*np.sin(2*np.pi*1760*t))*np.exp(-t*65)
 elif key=='terminal':
  signal=np.sin(2*np.pi*(290*t+430*t*t))*np.exp(-t*8)
  signal+=.25*np.sin(2*np.pi*1160*t)*np.exp(-((t-.22)/.055)**2)
 else:
  signal=np.zeros(len(t))
  for start,hz in [(0,440),(.16,554.365),(.32,659.255),(.48,880)]:
   u=np.maximum(0,t-start)
   signal+=(t>=start)*(np.sin(2*np.pi*hz*u)+.14*np.sin(2*np.pi*hz*2*u))*np.minimum(1,u/.012)*np.exp(-u*5)
 signal*=np.minimum(1,t/.004)*np.minimum(1,(duration-t)/.018)
 signal/=max(1e-9,np.max(np.abs(signal)))
 signal*=10**((-15 if key=='step' else -10)/20)
 pcm=np.round(signal*32767).astype('<i2')
 with wave.open(str(OUT/(key+'.wav')),'wb') as f:
  f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes(pcm.tobytes())
 manifest[key]={'seconds':len(t)/SR,'peak_dbfs':float(20*np.log10(np.max(np.abs(signal)))),'loop':False,'origin':'original NumPy synthesis, seed '+str(2800+index)}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
