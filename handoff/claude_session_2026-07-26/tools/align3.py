import sys, zipfile, json, difflib
sys.path.insert(0,'/sessions/keen-confident-allen/mnt/outputs/v32')
from lxml import etree
import tracklib as T
from tracklib import w
V30="/sessions/keen-confident-allen/mnt/uploads/37a27e84-b9b8-4f60-8722-c8fb9e53a776-1785110454677_mer_manuscript_v30.docx"
V31="/sessions/keen-confident-allen/mnt/outputs/mer_manuscript_v31.docx"
def paras(path, accept=False):
    z=zipfile.ZipFile(path); root=etree.fromstring(z.read("word/document.xml"))
    if accept: T.accept_all(root)
    return [T.para_text(p) for p in root.find(w("body")).findall(w("p"))]
A=paras(V30,True); B=paras(V31)

# Monotonic best-similarity alignment: never cross, prefer high ratio.
def ratio(x,y):
    if not x.strip() and not y.strip(): return 1.0
    xs,ys=x.strip(),y.strip()
    r=difflib.SequenceMatcher(None,xs[:400],ys[:400],autojunk=False).ratio()
    if xs[:60]==ys[:60]: r=max(r,0.95)
    return r
n,m=len(A),len(B)
INF=-1e9
# DP over alignment with gap penalty
dp=[[INF]*(m+1) for _ in range(n+1)]; bt=[[None]*(m+1) for _ in range(n+1)]
dp[0][0]=0
GAP=-0.55
for i in range(n+1):
    for j in range(m+1):
        if dp[i][j]==INF: continue
        if i<n and j<m:
            r=ratio(A[i],B[j])
            s=dp[i][j]+(r if r>0.45 else -0.4)
            if s>dp[i+1][j+1]: dp[i+1][j+1]=s; bt[i+1][j+1]=("M",i,j)
        if i<n and dp[i][j]+GAP>dp[i+1][j]: dp[i+1][j]=dp[i][j]+GAP; bt[i+1][j]=("D",i,j)
        if j<m and dp[i][j]+GAP>dp[i][j+1]: dp[i][j+1]=dp[i][j]+GAP; bt[i][j+1]=("I",i,j)
i,j=n,m; ops=[]
while (i,j)!=(0,0):
    t,pi,pj=bt[i][j]; ops.append((t,pi,pj)); i,j=pi,pj
ops.reverse()
pairs=[(pi,pj) for t,pi,pj in ops if t=="M"]
del30=[pi for t,pi,pj in ops if t=="D"]
ins31=[pj for t,pi,pj in ops if t=="I"]
changed=[(i,j) for i,j in pairs if A[i].strip()!=B[j].strip()]
print("pairs %d | changed %d | v30-only %s | v31-only %s"%(len(pairs),len(changed),del30,ins31))
for i in del30: print("  DEL30[%d] %s"%(i,A[i].strip()[:120]))
for j in ins31: print("  INS31[%d] %s"%(j,B[j].strip()[:120]))
json.dump({"pairs":pairs,"changed":changed,"del30":del30,"ins31":ins31,
           "A":A,"B":B}, open("align.json","w"))
