import json
import math
import os
import subprocess
import sys
import tempfile
import time
from xml.sax.saxutils import escape

GROUP_ID = "10962733"

R15_TREE = {
    "HumanoidRootPart": ["LowerTorso"],
    "LowerTorso": ["UpperTorso", "LeftUpperLeg", "RightUpperLeg"],
    "UpperTorso": ["Head", "LeftUpperArm", "RightUpperArm"],
    "LeftUpperArm": ["LeftLowerArm"],
    "LeftLowerArm": ["LeftHand"],
    "RightUpperArm": ["RightLowerArm"],
    "RightLowerArm": ["RightHand"],
    "LeftUpperLeg": ["LeftLowerLeg"],
    "LeftLowerLeg": ["LeftFoot"],
    "RightUpperLeg": ["RightLowerLeg"],
    "RightLowerLeg": ["RightFoot"],
    "Head": [],
    "LeftHand": [],
    "RightHand": [],
    "LeftFoot": [],
    "RightFoot": [],
}

EASING_STYLES = {"Linear": 0, "Constant": 1, "Elastic": 2, "Cubic": 3, "Bounce": 4, "CubicV2": 5}
EASING_DIRECTIONS = {"In": 0, "Out": 1, "InOut": 2}
PRIORITIES = {"Idle": 0, "Movement": 1, "Action": 2, "Core": 1000, "Action2": 3, "Action3": 4, "Action4": 5}


def angles_matrix(rx, ry, rz):
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    rxm = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    rym = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    rzm = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

    return mul(mul(rxm, rym), rzm)


def pose_values(spec):
    rot = spec.get("r", (0, 0, 0))
    pos = spec.get("p", (0, 0, 0))
    return [math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2])], list(pos)


def cframe_xml(spec):
    (rx, ry, rz), (x, y, z) = pose_values(spec)
    m = angles_matrix(rx, ry, rz)
    parts = [f"<X>{x:.6f}</X>", f"<Y>{y:.6f}</Y>", f"<Z>{z:.6f}</Z>"]
    for i in range(3):
        for j in range(3):
            parts.append(f"<R{i}{j}>{m[i][j]:.6f}</R{i}{j}>")
    return '<CoordinateFrame name="CFrame">' + "".join(parts) + "</CoordinateFrame>"


class Refs:
    def __init__(self):
        self.count = 0

    def next(self):
        self.count += 1
        return f"RBX{self.count}"


def pose_xml(refs, part, poses, default_style, default_direction):
    spec = poses.get(part, {})
    style = EASING_STYLES[spec.get("style", default_style)]
    direction = EASING_DIRECTIONS[spec.get("dir", default_direction)]
    weight = 1 if part in poses else 0
    children = "".join(
        pose_xml(refs, child, poses, default_style, default_direction) for child in R15_TREE[part]
    )
    return (
        f'<Item class="Pose" referent="{refs.next()}"><Properties>'
        + cframe_xml(spec)
        + f'<token name="EasingDirection">{direction}</token>'
        + f'<token name="EasingStyle">{style}</token>'
        + f'<string name="Name">{part}</string>'
        + f'<float name="Weight">{weight}</float>'
        + "</Properties>"
        + children
        + "</Item>"
    )


def keyframe_xml(refs, keyframe, fps):
    poses = keyframe["poses"]
    style = keyframe.get("style", "CubicV2")
    direction = keyframe.get("dir", "InOut")
    markers = "".join(
        f'<Item class="KeyframeMarker" referent="{refs.next()}"><Properties>'
        f'<string name="Name">{escape(name)}</string><string name="Value"></string>'
        "</Properties></Item>"
        for name in keyframe.get("events", [])
    )
    return (
        f'<Item class="Keyframe" referent="{refs.next()}"><Properties>'
        f'<string name="Name">Keyframe</string><float name="Time">{keyframe["f"] / fps:.6f}</float>'
        "</Properties>"
        + pose_xml(refs, "HumanoidRootPart", poses, style, direction)
        + markers
        + "</Item>"
    )


def clip_xml(clip):
    fps = clip.get("fps", 60)
    refs = Refs()
    keyframes = "".join(keyframe_xml(refs, keyframe, fps) for keyframe in clip["keyframes"])
    return (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        f'<Item class="KeyframeSequence" referent="{refs.next()}"><Properties>'
        f'<bool name="Loop">{"true" if clip.get("loop") else "false"}</bool>'
        f'<string name="Name">{escape(clip["name"])}</string>'
        f'<token name="Priority">{PRIORITIES[clip.get("priority", "Action")]}</token>'
        "</Properties>"
        + keyframes
        + "</Item></roblox>"
    )


def clip_json(clip):
    fps = clip.get("fps", 60)
    keyframes = []
    for keyframe in clip["keyframes"]:
        poses = {}
        for part, spec in keyframe["poses"].items():
            rot, pos = pose_values(spec)
            poses[part] = {
                "r": rot,
                "p": pos,
                "style": spec.get("style", keyframe.get("style", "CubicV2")),
                "dir": spec.get("dir", keyframe.get("dir", "InOut")),
            }
        keyframes.append({"t": keyframe["f"] / fps, "poses": poses, "events": keyframe.get("events", [])})
    return {"name": clip["name"], "loop": bool(clip.get("loop")), "keyframes": keyframes}


def upload(path, display_name):
    key = os.environ.get("ROBLOX_API_KEY")
    if not key:
        raise SystemExit("ROBLOX_API_KEY missing")
    request = {
        "assetType": "Animation",
        "displayName": display_name,
        "description": "Chop a Rock animation",
        "creationContext": {"creator": {"groupId": GROUP_ID}},
    }
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
        json.dump(request, handle)
        request_path = handle.name
    try:
        raw = subprocess.run(
            [
                "curl.exe", "-s", "-X", "POST", "https://apis.roblox.com/assets/v1/assets",
                "-H", f"x-api-key: {key}",
                "-F", f"request=<{request_path};type=application/json",
                "-F", f"fileContent=@{path};type=model/x-rbxm",
            ],
            capture_output=True, text=True, check=False,
        ).stdout
    finally:
        os.remove(request_path)
    operation = json.loads(raw) if raw.strip().startswith("{") else {}
    if "path" not in operation:
        return None, raw
    for _ in range(30):
        time.sleep(2)
        status = json.loads(
            subprocess.run(
                ["curl.exe", "-s", f"https://apis.roblox.com/assets/v1/{operation['path']}", "-H", f"x-api-key: {key}"],
                capture_output=True, text=True, check=False,
            ).stdout
        )
        if status.get("done"):
            asset_id = status.get("response", {}).get("assetId")
            return asset_id, json.dumps(status)
    return None, "timeout"


if __name__ == "__main__":
    print("Import this module from a clip file.", file=sys.stderr)
