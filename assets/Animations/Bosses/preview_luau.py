"""Needs the ServerStorage.BossAnimPreview module (Edit only, not used by the game). Write an Edit-mode Luau snippet for one boss's clip contact sheet.
py -3 preview_luau.py <Boss> <out.luau> '<times json>'   e.g. '{"Idle":[0,1,2]}'"""
import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
boss, out = sys.argv[1], sys.argv[2]
times = json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}
data = json.load(open(os.path.join(HERE, "build", "preview.json"), encoding="utf-8"))
def rnd(x):
    if isinstance(x, float): return round(x, 4)
    if isinstance(x, list): return [rnd(v) for v in x]
    if isinstance(x, dict): return {k: rnd(v) for k, v in x.items()}
    return x
clips = {}
for k, v in data.items():
    if not k.startswith(f"Boss_{boss}_"): continue
    if times and k[len(f"Boss_{boss}_"):] not in times: continue
    v["parts"] = {p: 1 for kf in v["keyframes"] for p in kf["poses"]}
    for kf in v["keyframes"]:  # drop rest poses: weight 0 and identity are the same here
        kf["poses"] = {p: s for p, s in kf["poses"].items() if any(abs(a) > 1e-6 for a in s["r"] + s["p"])}
    for kf in v["keyframes"]:
        kf["poses"] = {n: [round(a, 3) for a in s["r"] + s["p"]] for n, s in kf["poses"].items()}
        kf["poses"] = {n: (a if any(a[3:]) else a[:3]) for n, a in kf["poses"].items()}
    for key in ("name", "tree", "priority"): v.pop(key, None)
    clips[k] = v
times = {f"Boss_{boss}_{k}": v for k, v in times.items()}
src = ("local H = game:GetService('HttpService')" + chr(10) +
       "return require(game.ServerStorage.BossAnimPreview:Clone())(%r, H:JSONDecode([==[%s]==]), H:JSONDecode(%r))"
       % (boss, json.dumps(clips, separators=(",", ":")), json.dumps(times)))
open(out, "w", encoding="utf-8").write(src)
print(len(src))
