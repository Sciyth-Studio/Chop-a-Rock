import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "..", "scripts"))
import animation_rbxmx as rb

ARMS_UP = {
    "RightUpperArm": {"r": (165, 0, -6), "style": "Linear", "dir": "In"},
    "LeftUpperArm": {"r": (165, 0, 6), "style": "Linear", "dir": "In"},
    "RightLowerArm": {"r": (12, 0, 0), "style": "Linear", "dir": "In"},
    "LeftLowerArm": {"r": (12, 0, 0), "style": "Linear", "dir": "In"},
    "RightHand": {"r": (0, 0, 0), "style": "Linear", "dir": "In"},
    "LeftHand": {"r": (0, 0, 0), "style": "Linear", "dir": "In"},
}


def hold_overhead():
    return {
        "name": "Held_Overhead",
        "loop": True,
        "priority": "Action",
        "frames": 60,
        "keyframes": [{"f": 0, "poses": ARMS_UP}, {"f": 60, "poses": ARMS_UP}],
    }


def main():
    here = os.path.dirname(__file__)
    out_dir = os.path.join(here, "build")
    os.makedirs(out_dir, exist_ok=True)
    clip = hold_overhead()
    path = os.path.join(out_dir, "Held_Overhead.rbxmx")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(rb.clip_xml(clip))
    if len(sys.argv) > 1 and sys.argv[1] == "upload":
        asset_id, detail = rb.upload(path, "Held Overhead")
        print(asset_id or detail[:300])
        if asset_id:
            with open(os.path.join(here, "ids.json"), "w", encoding="utf-8") as handle:
                json.dump({"Held_Overhead": asset_id}, handle, indent=2)


if __name__ == "__main__":
    main()
