# NEON RONIN: textured articulated glTF humanoid generator (CC0 original geometry).
# Run: python tools/build_avatar.py
from pathlib import Path
import math
import numpy as np
import trimesh
from PIL import Image
from trimesh.visual.material import PBRMaterial
from trimesh.visual.texture import TextureVisuals
from trimesh.transformations import translation_matrix

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/"assets"
DEST.mkdir(exist_ok=True)
scene=trimesh.Scene()
palette={
  "armor":"#273445","steel":"#586b7d","metal":"#879aaa","under":"#172432",
  "carbon":"#101923","skin":"#b17f69","hair":"#241c1b","beard":"#29201c",
  "cloth":"#241c31","cy":"#0de8e3","mag":"#e92bb0","gold":"#ccab68"}
def material(k):
    h=palette[k]
    rgb=[int(h[i:i+2],16)/255 for i in (1,3,5)]
    return PBRMaterial(name=k,baseColorFactor=(*rgb,1.0),
       metallicFactor=.7 if k in ("armor","steel","metal","carbon","gold") else .07,
       roughnessFactor=.28 if k in ("metal","steel","gold") else .68,
       emissiveFactor=tuple(rgb) if k in ("cy","mag") else (0,0,0))
materials={k:material(k) for k in palette}

def group(parent,name,at):
    scene.graph.update(frame_to=name,frame_from=parent,matrix=translation_matrix(at))
def add(m,name,parent="world",mat="armor",at=None):
    if mat: m.visual=TextureVisuals(material=materials[mat])
    scene.add_geometry(m,node_name=name,geom_name=name,parent_node_name=parent,
       transform=translation_matrix(at) if at is not None else np.eye(4))
def loft(rings,n=32):
    verts=[];faces=[]
    for row in rings:
        y,rx,rz,*rest=row
        z=rest[0] if rest else 0
        for i in range(n):
            a=2*math.pi*i/n
            verts.append((rx*math.cos(a),y,z+rz*math.sin(a)))
    for j in range(len(rings)-1):
        for i in range(n):
            a=j*n+i;b=j*n+(i+1)%n;c=(j+1)*n+i;d=(j+1)*n+(i+1)%n
            faces.extend(((a,c,b),(b,c,d)))
    return trimesh.Trimesh(vertices=verts,faces=faces,process=False)
def ball(dims):
    m=trimesh.creation.icosphere(subdivisions=3,radius=1)
    m.vertices*=np.array(dims)
    return m
def tube(a,b,r=.02):
    a=np.asarray(a,float);b=np.asarray(b,float)
    from trimesh.geometry import align_vectors
    m=trimesh.creation.cylinder(radius=r,height=np.linalg.norm(b-a),sections=12)
    m.apply_transform(align_vectors([0,0,1],b-a))
    m.apply_translation((a+b)/2)
    return m
def plate(y0,y1,a0,a1,rings,n=14,levels=7):
    v=[];fs=[]
    yy=[r[0] for r in rings]
    for k in range(levels+1):
        y=y0+(y1-y0)*k/levels
        rx=np.interp(y,yy,[r[1] for r in rings])
        rz=np.interp(y,yy,[r[2] for r in rings])
        cz=np.interp(y,yy,[r[3] if len(r)>3 else 0 for r in rings])
        for j in range(n+1):
            ang=a0+(a1-a0)*j/n
            v.append((rx*math.sin(ang)*1.08,y,cz-rz*math.cos(ang)*1.1))
    for k in range(levels):
        for j in range(n):
            a=k*(n+1)+j;b=a+1;c=a+n+1;d=c+1
            fs.extend(((a,c,b),(b,c,d)))
    return trimesh.Trimesh(vertices=v,faces=fs,process=False)

# Anatomical torso with layered curved torso plates
torso=[(1.13,.28,.17,.02),(1.30,.34,.20,.02),(1.42,.29,.18,.01),
       (1.61,.31,.22,0),(1.78,.40,.27,0),(1.97,.46,.28,0),
       (2.12,.46,.25,0),(2.25,.32,.20,.02),(2.32,.20,.14,.02)]
add(loft(torso,48),"Body","world","under")
for yi,(low,hi) in enumerate([(1.3,1.42),(1.45,1.61),(1.65,1.81),(1.83,2.02),(2.05,2.2)]):
    for j,(a,b) in enumerate([(-1.12,-.06),(.06,1.12)]):
        add(plate(low,hi,a,b,torso),f"ChestPlate{yi}_{j}")
add(loft([(2.25,.13,.12,.02),(2.39,.14,.12,.02),(2.46,.14,.12,.02)],28),"Neck","world","skin")
add(loft([(2.25,.24,.21,0),(2.28,.23,.19,0),(2.37,.19,.17,0)],36),"NeckArmor","world","carbon")
add(loft([(1.10,.28,.20,.02),(1.18,.30,.21,.02),(1.30,.33,.20,.02)],40),"Belt","world","steel")
for side in (-1,1):
    for i in range(5):
        y=1.5+.142*i
        add(tube((side*.31,y,-.13),(side*(.33+i*.016),y+.09,-.12),.022),f"RibLED_{side}_{i}",
            mat="cy" if i%2==0 else "steel")
    add(ball((.18,.14,.06)),f"Pouch_{side}",mat="armor",at=(side*.31,1.18,-.18))

# Articulated arms with elbow pivots and armor
for side,tag in [(-1,"L"),(1,"R")]:
    group("world","Shoulder"+tag,(side*.54,2.18,0))
    arm=[(-.57,.104,.108,.02),(-.48,.115,.12,.01),(-.33,.16,.14,0),
         (-.16,.18,.16,0),(-.03,.23,.23,0),(.035,.25,.25,0)]
    add(loft(arm,32),"Deltoid"+tag,"Shoulder"+tag,"under")
    add(ball((.24,.17,.23)),"Pauldron"+tag,"Shoulder"+tag,"steel",(side*.02,-.04,-.02))
    add(plate(-.4,-.09,-.85,.85,arm),"BicepShield"+tag,"Shoulder"+tag)
    for i in range(3):
        y=-.35+i*.10
        add(tube((0,y,-.16),(0,y+.06,-.18),.013),f"ArmLED{tag}{i}","Shoulder"+tag,"cy")
    group("Shoulder"+tag,"Elbow"+tag,(0,-.51,.025))
    fore=[(-.43,.12,.11,-.01),(-.31,.14,.145,0),(-.18,.17,.15,0),(-.05,.12,.12,0),(.03,.11,.11,0)]
    add(loft(fore,32),"Forearm"+tag,"Elbow"+tag,"carbon")
    add(plate(-.40,-.12,-.95,.95,fore),"Gauntlet"+tag,"Elbow"+tag,"steel")
    add(ball((.132,.165,.10)),"Hand"+tag,"Elbow"+tag,"skin",(0,-.54,0))
    add(tube((side*.14,-.35,-.105),(side*.14,-.05,-.105),.015),
        "GauntletLED"+tag,"Elbow"+tag,"mag")

# Independent thigh, knee, ankle pivots allowing motion on a treadmill
for side,tag in [(-1,"L"),(1,"R")]:
    group("world","Hip"+tag,(side*.23,1.21,0))
    thigh=[(-.59,.135,.142,-.012),(-.51,.16,.19,0),(-.36,.205,.23,0),
           (-.19,.216,.224,0),(-.02,.205,.20,0),(.05,.18,.17,0)]
    add(loft(thigh,36),"Thigh"+tag,"Hip"+tag,"under")
    add(plate(-.53,-.10,-1.13,1.13,thigh),"ThighArmor"+tag,"Hip"+tag)
    add(ball((.18,.14,.19)),"KneeShield"+tag,"Hip"+tag,"steel",(0,-.55,-.09))
    for i in range(3):
        y=-.42+i*.11
        add(tube((side*.14,y,-.13),(side*.15,y+.07,-.145),.015),
            f"LegLED{tag}{i}","Hip"+tag,"mag")
    group("Hip"+tag,"Knee"+tag,(0,-.56,0))
    shin=[(-.48,.12,.14,0),(-.39,.155,.16,0),(-.22,.18,.20,0),(-.08,.185,.17,0),(.0,.17,.15,0)]
    add(loft(shin,36),"Shin"+tag,"Knee"+tag,"under")
    add(plate(-.43,-.10,-1.0,1.0,shin),"ShinArmor"+tag,"Knee"+tag,"steel")
    group("Knee"+tag,"Ankle"+tag,(0,-.48,0))
    add(ball((.178,.15,.29)),"Boot"+tag,"Ankle"+tag,"carbon",(0,-.04,-.105))
    add(ball((.17,.065,.29)),"Toe"+tag,"Ankle"+tag,"steel",(0,-.11,-.16))
    add(tube((-.095,-.075,-.34),(.095,-.075,-.34),.018),"ShoeLED"+tag,"Ankle"+tag,"cy")

# Actual curved 3D head, UV photo projected onto the front triangles, not Sprite3D.
group("world","Neck_Head",(0,2.39,0))
head=[(.075,.055,.11),(.10,.105,.14),(.15,.16,.16),(.22,.191,.17),
      (.29,.21,.176),(.36,.218,.184),(.43,.212,.188),(.50,.201,.183),
      (.56,.194,.17),(.615,.16,.147),(.67,.075,.095)]
v=[];uv=[];faces=[];N=40
for k,(y,rx,rz) in enumerate(head):
    for j in range(N+1):
        ang=-math.pi/2+math.pi*j/N
        nose=.06*math.exp(-((y-.39)/.078)**2)*math.exp(-(ang/.29)**2)
        cheek=.015*math.exp(-((y-.35)/.10)**2)*math.exp(-((abs(ang)-.76)/.26)**2)
        v.append((rx*math.sin(ang),y,-rz*math.cos(ang)-nose-cheek))
        uv.append((j/N,1-k/(len(head)-1)))
for k in range(len(head)-1):
    for j in range(N):
        a=k*(N+1)+j;b=a+1;c=a+N+1;d=c+1
        faces.extend(((a,c,b),(b,c,d)))
face=trimesh.Trimesh(vertices=v,faces=faces,process=False)
img=Image.open(DEST/"face_albedo.jpg").convert("RGB")
face.visual=TextureVisuals(uv=np.asarray(uv),
    material=PBRMaterial(name="RealFacePhotoMappedOnto3DGeometry",
       baseColorTexture=img,metallicFactor=0,roughnessFactor=.85))
add(face,"Real3DFace","Neck_Head",None)
v=[];faces=[]
for k,(y,rx,rz) in enumerate(head):
    for j in range(N+1):
        ang=math.pi/2+math.pi*j/N
        v.append((rx*math.sin(ang),y,-rz*math.cos(ang)))
for k in range(len(head)-1):
    for j in range(N):
        a=k*(N+1)+j;b=a+1;c=a+N+1;d=c+1
        faces.extend(((a,c,b),(b,c,d)))
add(trimesh.Trimesh(vertices=v,faces=faces,process=False),"BackOfHead","Neck_Head","hair")
add(loft([(.59,.17,.15),(.66,.175,.157),(.70,.16,.14),(.73,.06,.06)],36),"ShortHair","Neck_Head","hair")
for side,tag in [(-1,"L"),(1,"R")]:
    add(ball((.062,.114,.045)),"Ear"+tag,"Neck_Head","skin",(side*.222,.365,0))
    add(ball((.022,.062,.021)),"EarInner"+tag,"Neck_Head","beard",(side*.258,.36,-.02))
    for i in range(4):
        add(ball((.045,.11,.05)),f"HairStrand{tag}{i}","Neck_Head","hair",
            (side*(.12+i*.021),.63-i*.025,.025))
    add(ball((.035,.04,.03)),"Earpiece"+tag,"Neck_Head","metal",(side*.274,.35,.012))
    add(ball((.017,.015,.012)),"EarLED"+tag,"Neck_Head","cy",(side*.294,.36,-.009))
add(ball((.126,.045,.06)),"BeardChin","Neck_Head","beard",(0,.101,-.107))

# Detailed katana, saya scabbard and hand grip, entirely in 3D.
group("world","Katana",(.48,1.33,.13))
for name,a,b,rad,material in [
    ("Saya",(.02,.09,0),(.56,-.89,.06),.048,"carbon"),
    ("SayaGlow",(.06,.02,-.035),(.52,-.78,.015),.009,"mag"),
    ("Grip",(-.11,.29,-.01),(.04,.08,0),.044,"carbon"),
    ("Tsuba",(.01,.078,0),(.10,.062,0),.082,"steel")]:
    add(tube(a,b,rad),"Katana"+name,"Katana",material)
for i in range(7):
    t=i/6
    add(tube((-.11+.12*t,.29-.16*t,-.051),(-.09+.12*t,.30-.16*t,.042),.009),
        f"GripWrap{i}","Katana","gold")
group("world","BladeBack",(-.55,2.19,.28))
add(loft([(-1.03,.021,.016),(-.95,.035,.012),(-.2,.045,.012),(.025,.058,.015)],8),
    "BladeSteel","BladeBack","metal")
add(tube((0,-.9,-.012),(0,-.1,-.014),.008),"BladeGlow","BladeBack","cy")
path=DEST/"ronin_v2.glb"
scene.export(str(path))
print("Created",path,"submeshes",len(scene.geometry),
      "triangles",sum(len(x.faces) for x in scene.geometry.values()))
