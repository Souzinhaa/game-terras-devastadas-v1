from PIL import Image,ImageDraw,ImageFilter,ImageEnhance
import numpy as np,math,wave,subprocess,json,shutil
from pathlib import Path
P=Path(__file__).resolve().parents[1]; BASE=P.parents[1]; G=BASE/'generated_images'
W,H,FPS,D=1280,720,24,18
rng=np.random.default_rng(42)
files={'cenario.png':'exec-31fa32f9-5e75-4e53-b8c6-38db5d144442.png','barricada.png':'exec-64790e2d-e8ec-4df5-943d-f773208645df.png','hostil.png':'exec-585a4646-94d7-4686-b7e7-46ab961e70c0.png','hatch.png':'exec-35149b1a-e3d8-41c5-80f7-4fde1dec3c15.png'}
for dst,src in files.items(): shutil.copyfile(G/src,P/'assets'/dst)
bg=Image.open(P/'assets/cenario.png').convert('RGB').resize((W,H),Image.Resampling.LANCZOS)
tile=Image.new('RGB',(W*2,H));tile.paste(bg,(0,0));tile.paste(bg.transpose(Image.Transpose.FLIP_LEFT_RIGHT),(W,0))
def cut(path,width):
 im=Image.open(path).convert('RGBA'); a=im.getchannel('A');box=a.point(lambda v:255 if v>30 else 0).getbbox();im=im.crop(box);return im.resize((width,round(im.height*width/im.width)),Image.Resampling.LANCZOS)
bar=cut(P/'assets/barricada.png',210);host=cut(P/'assets/hostil.png',73)
raw=[Image.open(BASE/f'output/veiculos_loop/hatch/frames/{i:02}.png').convert('RGBA') for i in range(24)]
# Use the same crop for all existing driving frames.
boxes=[im.getchannel('A').point(lambda v:255 if v>40 else 0).getbbox() for im in raw];box=(min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes))
cars=[im.crop(box).resize((410,round((box[3]-box[1])*410/(box[2]-box[0]))),Image.Resampling.LANCZOS) for im in raw]
for i,im in enumerate(cars): im.save(P/'assets'/f'carro_{i:02}.png')
def ease(a,b,t):
 q=np.clip(t,0,1);return a+(b-a)*q*q*(3-2*q)
def velocity(t):
 if t<3:return 1
 if t<4:return 1-(t-3)
 if t<5:return 0
 if t<6:return (t-5)*1.6
 if t<7.5:return 1.6
 return 1
# A full mirrored panorama traversal makes the first/last state periodic.
grid=np.arange(FPS*D+1)/FPS;v=np.array([velocity(t) for t in grid]);pos=np.concatenate(([0],np.cumsum((v[:-1]+v[1:])*.5/FPS)));pos*=W*2/pos[-1]
def bgframe(offset):
 k=round(offset)%(2*W); strip=Image.new('RGB',(W,H)); first=tile.crop((k,0,min(2*W,k+W),H));strip.paste(first,(0,0));
 if k+W>2*W:strip.paste(tile.crop((0,0,k+W-2*W,H)),(2*W-k,0))
 return strip
# Audio: deliberately synthesized, no copyrighted recordings or voices.
SR=44100;n=SR*D;tt=np.arange(n)/SR
speed=np.interp(tt,grid,v); hz=37+speed*24+2*np.sin(2*np.pi*tt*5)
phase=np.cumsum(hz)*2*np.pi/SR
engine=(np.sin(phase)+.37*np.sin(2*phase)+.2*np.sin(3*phase))*.13*(.55+speed*.4)
noise=rng.normal(0,1,n);wind=np.convolve(noise,np.ones(35)/35,mode='same')*.1
mix=engine+wind
# Gentle boundary matching for noise, engine is faded only over 12 ms at edges.
def savewav(name,x):
 x=np.asarray(x);x=x*.84/max(1,np.max(np.abs(x))); x[:min(400,len(x))]*=np.linspace(0,1,min(400,len(x)));x[-min(400,len(x)):]*=np.linspace(1,0,min(400,len(x)))
 with wave.open(str(P/'audio'/name),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes((x*32767).astype('<i2').tobytes())
def impact(sec,kind):
 t=np.arange(int(sec*SR))/SR;no=rng.normal(size=len(t))
 if kind=='bar':
  x=no*.35*np.exp(-t*7)+.22*np.sin(2*np.pi*78*t)*np.exp(-t*11)
  for freq in [229,453,723,1123]:x+=.06*np.sin(2*np.pi*freq*t)*np.exp(-t*4)
  for delay in [.07,.18,.29]:
   j=int(delay*SR);x[j:]+=rng.normal(size=len(t)-j)*.12*np.exp(-np.arange(len(t)-j)/SR*19)
 elif kind=='hit':x=.4*np.sin(2*np.pi*(95*t-40*t*t))*np.exp(-t*18)+no*.13*np.exp(-t*22)
 else:x=np.sin(2*np.pi*(1250*t-150*t*t))*.09*np.sin(np.pi*np.minimum(t/sec,1)) +no*.04
 return x
for name,onset,x in [('freada.wav',3.1,impact(.8,'brake')),('barricada_impacto.wav',6,impact(1.25,'bar')),('hostil_impacto.wav',13,impact(.5,'hit'))]:
 savewav(name,x.copy());j=int(onset*SR);mix[j:j+len(x)]+=x
savewav('motor_loop.wav',engine[:SR*3].copy());savewav('vento_loop.wav',wind[:SR*3].copy());savewav('mix_sincronizado.wav',mix.copy())
subprocess.run(['ffmpeg','-y','-v','error','-i',str(P/'audio/mix_sincronizado.wav'),'-c:a','libvorbis','-q:a','5',str(P/'audio/mix_sincronizado.ogg')],check=True)
# Deterministic particles across frames.
particles=[(float(rng.uniform(-1,1)),float(rng.uniform(.3,1)),float(rng.uniform(0,360)),float(rng.uniform(5,15))) for _ in range(22)]
chunks=[]
for j in range(6):
 x0=j%3*70;y0=j//3*(bar.height//2);chunks.append((bar.crop((x0,y0,x0+70,y0+bar.height//2)),x0,y0))
def put(canvas,im,x,y):canvas.alpha_composite(im,(round(x),round(y)))
proc=subprocess.Popen(['ffmpeg','-y','-v','error','-f','rawvideo','-pixel_format','rgb24','-video_size',f'{W}x{H}','-framerate',str(FPS),'-i','-','-an','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p',str(P/'video/fundo_sem_audio.mp4')],stdin=subprocess.PIPE)
for frame in range(FPS*D):
 t=frame/FPS;canvas=bgframe(pos[frame]).convert('RGBA')
 carx=760
 if 5<=t<6:carx=ease(760,700,t-5)
 elif 6<=t<7.5:carx=ease(700,500,(t-6)/1.5)
 elif 7.5<=t<9.5:carx=ease(500,760,(t-7.5)/2)
 # Barricade approaches, then stays fixed during stop and charge.
 if 1.2<=t<6:
  bx=ease(-220,490,(t-1.2)/2.8) if t<4 else 490
  put(canvas,bar,bx,627-bar.height)
 if 10<=t<13:
  hx=ease(-100,744,(t-10)/3);put(canvas,host,hx,627-host.height+math.sin(t*8)*1.5)
 if 13<=t<14:
  a=t-13;rot=host.rotate(180*a,resample=Image.Resampling.BICUBIC,expand=True);put(canvas,rot,744-a*380,627-host.height-95*math.sin(a*math.pi)+210*a*a)
 car=cars[(int(t*20)%24) if velocity(t)>.05 else 0]
 shadow=Image.new('RGBA',(W,H));sd=ImageDraw.Draw(shadow);sd.ellipse((carx+15,612,carx+365,636),fill=(0,0,0,95));canvas=Image.alpha_composite(canvas,shadow.filter(ImageFilter.GaussianBlur(6)))
 put(canvas,car,carx,635-car.height)
 if 6<=t<7.2:
  a=t-6
  for j,(chunk,x,y) in enumerate(chunks):
   q=chunk.rotate((j-2)*a*110,Image.Resampling.BICUBIC,expand=True);put(canvas,q,490+x-(90+j*19)*a,627-bar.height+y-130*a+(210+j*13)*a*a)
 # Dust covers impacts, smoke trails behind right-facing screen edge of leftward car.
 fx=Image.new('RGBA',(W,H));dd=ImageDraw.Draw(fx)
 for k in range(10):
  age=(t*.8+k/10)%1;r=6+age*17;xx=carx+335+age*130;yy=624-age*27
  if velocity(t)>.03:dd.ellipse((xx-r,yy-r*.6,xx+r,yy+r*.6),fill=(160,137,105,round((1-age)*35)))
 for impact_t,ix in [(6,670),(13,755)]:
  age=t-impact_t
  if 0<=age<1.25:
   for j,(vx,vy,angle,r) in enumerate(particles):
    xx=ix+vx*age*150; yy=600-vy*age*80+age*age*25;rr=r+age*30;alpha=round(92*(1-age/1.25))
    dd.ellipse((xx-rr,yy-rr*.65,xx+rr,yy+rr*.65),fill=(166,130,86,alpha))
   if age<.2:
    for j in range(9):
     an=j/9*math.pi*2;xx=ix+math.cos(an)*age*350;yy=590+math.sin(an)*age*220
     dd.line((ix,590,xx,yy),fill=(255,178,66,round(180*(1-age/.2))),width=2)
 canvas=Image.alpha_composite(canvas,fx.filter(ImageFilter.GaussianBlur(1.5)))
 if frame in [0,96,144,312]:canvas.convert('RGB').save(P/f'frame_{frame:03}.jpg',quality=90)
 proc.stdin.write(canvas.convert('RGB').tobytes())
 if frame%72==0:print(f'render {frame}/{FPS*D}',flush=True)
proc.stdin.close();assert proc.wait()==0
subprocess.run(['ffmpeg','-y','-v','error','-i',str(P/'video/fundo_sem_audio.mp4'),'-i',str(P/'audio/mix_sincronizado.wav'),'-c:v','copy','-c:a','aac','-b:a','160k','-shortest','-movflags','+faststart',str(P/'video/fundo_com_audio.mp4')],check=True)
subprocess.run(['ffmpeg','-y','-v','error','-i',str(P/'video/fundo_com_audio.mp4'),'-c:v','libtheora','-q:v','7','-c:a','libvorbis','-q:a','4',str(P/'video/fundo_godot.ogv')],check=True)
subprocess.run(['ffmpeg','-y','-v','error','-i',str(P/'video/fundo_com_audio.mp4'),'-vf','scale=640:360','-c:v','libx264','-crf','24','-c:a','aac','-b:a','96k','-movflags','+faststart',str(P/'previa.mp4')],check=True)
shutil.copyfile(P/'frame_000.jpg',P/'assets/fallback.jpg')
print('ALL MEDIA READY',flush=True)
