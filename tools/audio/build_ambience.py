#!/usr/bin/env python3
"""Periodic procedural environments; numpy only, no recordings or game RNG."""
from pathlib import Path
import json,wave
import numpy as np
OUT=Path(__file__).resolve().parents[2]/'assets/audio/ambience'
SR=44100;SECONDS=24;N=SR*SECONDS

def render(key,index):
 rng=np.random.default_rng(2190+index)
 t=np.arange(N)/SR
 freq=np.fft.rfftfreq(N,1/SR)
 # A periodic, band-limited noise bed: no random reset at the loop boundary.
 spectrum=rng.normal(size=len(freq))+1j*rng.normal(size=len(freq))
 cut=[650,1200,1900,380,850][index]
 spectrum*=np.exp(-(freq/cut)**2)*(1-np.exp(-(freq/65)**2))
 spectrum[0]=0
 noise=np.fft.irfft(spectrum,n=N)
 noise/=np.std(noise)
 bed=noise*.023*(.8+.2*np.sin(2*np.pi*t/SECONDS))
 hum=[49,41,55,65,46][index]
 hum=round(hum*SECONDS)/SECONDS
 bed+=.024*np.sin(2*np.pi*hum*t)*(1+.18*np.sin(2*np.pi*3*t/SECONDS))
 # Dissonant, slowly breathing layers use whole cycles for a continuous loop.
 for ratio,level,cycles in [(1.0,.032,2),(1.015,.025,3),(1.4142,.018,1),(2.01,.012,4)]:
  drone=round(hum*ratio*SECONDS)/SECONDS
  swell=.65+.35*np.sin(2*np.pi*cycles*t/SECONDS+index*.7)
  bed+=level*np.sin(2*np.pi*drone*t)*swell
 mix=np.stack([bed,np.roll(bed,337)],axis=1)
 def event(at,duration,f,amp,pan,kind):
  u=np.arange(round(duration*SR))/SR
  attack=.45 if kind=='ghost' else .025
  release=.8 if kind=='ghost' else .08
  decay=.3 if kind=='ghost' else (5 if kind=='drop' else 2)
  env=np.minimum(1,u/attack)*np.minimum(1,(duration-u)/release)*np.exp(-u*decay)
  x=np.sin(2*np.pi*f*u+(.8 if kind=='drop' else .2)*np.sin(2*np.pi*f*1.5*u))*env*amp
  ids=(round(at*SR)+np.arange(len(x)))%N
  np.add.at(mix[:,0],ids,x*np.sqrt((1-pan)/2))
  np.add.at(mix[:,1],ids,x*np.sqrt((1+pan)/2))
 if index==0:
  for j,at in enumerate([1.8,5.3,9.1,13.6,18.7,23.8]): event(at,.5,690+j*41,.075,(-1)**j*.6,'drop')
 elif index==1:
  for j in range(8): event(j*3+.6,.9,37+(j%3)*8,.15,(-1)**j*.3,'machine')
 elif index==2:
  for j in range(6): event(j*4+.3,1.2,180+(j%3)*90,.095,(-1)**j*.6,'scan')
 elif index==3:
  for at in [3,9,15,21]: event(at,.18,660,.065,.15,'medical')
 else:
  for j in range(12): event(j*2+.45,.12,420+(j%4)*105,.07,(-1)**j*.45,'data')
 # Distant dissonant resonances, without sudden loud stingers.
 for j,at in enumerate([4.5,16.5]):
  event(at,5.5,[111,98,146,130,165][index]+j*7,.06,(-1)**j*.7,'ghost')
 dry=mix.copy()
 mix+=np.roll(dry,round(.317*SR),axis=0)[:,::-1]*.22
 mix+=np.roll(dry,round(.731*SR),axis=0)*.13
 mix=np.tanh(mix)
 mix*=.28/max(np.max(np.abs(mix)),.001)
 pcm=np.round(mix*32767).astype('<i2')
 OUT.mkdir(parents=True,exist_ok=True)
 with wave.open(str(OUT/(key+'.wav')),'wb') as w:
  w.setnchannels(2);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
 join=float(np.max(np.abs(mix[0]-mix[-1])))
 p99=float(np.quantile(np.abs(np.diff(mix,axis=0)),.999))
 assert join<=p99 and np.max(np.abs(pcm.astype(int)))<32767
 return {'key':key,'seconds':SECONDS,'frames':N,'peak_dbfs':round(float(20*np.log10(np.max(np.abs(mix)))),2),'join_step':join,'adjacent_step_p999':p99,'clipped_samples':0,'rms_dbfs':round(float(20*np.log10(np.sqrt(np.mean(mix**2)))),2)}
if __name__=='__main__':
 tracks=[render(key,i) for i,key in enumerate(['paleta','brecha','cromo','clinic','archive'])]
 (OUT/'manifest.json').write_text(json.dumps({'provenance':'Original periodic synthesis, seeded noise; no recordings or external samples.','sample_rate':SR,'tracks':tracks},indent=2)+'\n')
 print(json.dumps(tracks,indent=2))
