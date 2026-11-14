"""Floor check for boss clips without Studio: forward kinematics on rig_boxes.json.

py -3 assets/Animations/Bosses/ground_check.py [clip name filter]

For each clip, samples 30 times a second and prints the lowest box corner relative to the
rest pose's lowest corner: "sink" is the deepest dip below rest (negative = into the floor),
"end" is the last frame. Boxes are the parts' bounding boxes, so a rotated piece reads a little
lower than its mesh. Easing is treated as linear, which is close enough for floor contact.
"""
import itertools
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import boss_clips  # noqa: E402

CORNERS = np.array(list(itertools.product((-0.5, 0.5), repeat=3)))


def load_rigs():
    raw = json.load(open(os.path.join(HERE, "rig_boxes.json"), encoding="utf-8"))
    rigs = {}
    for boss, parts in raw.items():
        if boss.startswith("_"):
            continue
        full = dict(parts)
        for name, v in parts.items():
            if name.startswith("Left"):
                twin = list(v)
                if twin[0].startswith("Left"):
                    twin[0] = "Right" + twin[0][4:]
                for i in (1, 7, 10):
                    if i < len(twin):
                        twin[i] = -twin[i]
                full["Right" + name[4:]] = twin
        rigs[boss] = full
    return rigs


def rot(rx, ry, rz):
    cx, sx, cy, sy, cz, sz = np.cos(rx), np.sin(rx), np.cos(ry), np.sin(ry), np.cos(rz), np.sin(rz)
    X = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Y = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    Z = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]])
    return X @ Y @ Z


def mat(R=np.eye(3), p=(0, 0, 0)):
    m = np.eye(4)
    m[:3, :3] = R
    m[:3, 3] = p
    return m


def pose_at(clip, t):
    keys = clip["keyframes"]
    fps = clip["fps"]
    times = [k["f"] / fps for k in keys]
    if t <= times[0]:
        a = b = keys[0]
        w = 0
    elif t >= times[-1]:
        a = b = keys[-1]
        w = 0
    else:
        i = max(j for j, tt in enumerate(times) if tt <= t)
        a, b = keys[i], keys[i + 1]
        w = (t - times[i]) / (times[i + 1] - times[i])
    out = {}
    for part in a["poses"]:
        ra, rb = np.radians(a["poses"][part]["r"]), np.radians(b["poses"][part]["r"])
        pa, pb = np.array(a["poses"][part].get("p", (0, 0, 0))), np.array(b["poses"][part].get("p", (0, 0, 0)))
        out[part] = mat(rot(*(ra + (rb - ra) * w)), pa + (pb - pa) * w)
    return out


def lowest(rig, pose):
    world = {"Root": mat(p=(0, 2, 0))}
    rootc = np.array([0, 2, 0])
    low = (np.inf, "")

    def solve(name):
        if name in world:
            return world[name]
        v = rig[name]
        parent = v[0]
        W0 = solve(parent)
        if len(v) > 7:
            pc = np.array(v[1:4]) if parent != "Root" else None
            c0, c1 = np.array(v[7:10]), np.array(v[10:13])
            W = W0 @ mat(p=c0) @ pose.get(name, np.eye(4)) @ mat(p=-c1)
        else:  # welded extra: fixed offset from its parent's centre
            pc0 = np.array(rig[parent][1:4])
            W = W0 @ mat(p=np.array(v[1:4]) - pc0)
        world[name] = W
        return W

    for name, v in rig.items():
        W = solve(name)
        size = np.array(v[4:7])
        pts = (W[:3, :3] @ (CORNERS * size).T).T + W[:3, 3]
        y = pts[:, 1].min()
        if y < low[0]:
            low = (y, name)
    return low


def main():
    rigs = load_rigs()
    filt = sys.argv[1] if len(sys.argv) > 1 else ""
    rest = {b: lowest(r, {})[0] for b, r in rigs.items()}
    for clip in boss_clips.all_clips():
        if filt not in clip["name"]:
            continue
        rig = rigs[clip["boss"]]
        length = clip["keyframes"][-1]["f"] / clip["fps"]
        worst = (np.inf, "", 0)
        for t in np.arange(0, length + 1e-6, 1 / 30):
            y, part = lowest(rig, pose_at(clip, t))
            if y < worst[0]:
                worst = (y, part, t)
        end = lowest(rig, pose_at(clip, length))
        sink = worst[0] - rest[clip["boss"]]
        flag = "  <-- sinks" if sink < -1.5 else ""
        endoff = end[0] - rest[clip["boss"]]
        flag += "  <-- floats at end" if endoff > 1.5 and not clip["loop"] else ""
        print(f"{clip['name']:<30} sink {sink:6.1f} ({worst[1]} @ {worst[2]:.2f}s)  end {endoff:5.1f}{flag}")


if __name__ == "__main__":
    main()
