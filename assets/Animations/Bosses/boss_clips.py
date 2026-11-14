"""World boss clips (Big Croc, Boulder Crab, Frost Yeti).

py -3 assets/Animations/Bosses/boss_clips.py build            writes build/<Clip>.rbxmx and build/preview.json
py -3 assets/Animations/Bosses/boss_clips.py upload [names]    uploads clips not yet in ids.json, or the named ones (each upload is a new, permanent group asset)

Rigs face -Z, +X is the boss's right. Joint frames are axis-aligned, so for a piece
pointing forward +rx tilts it up, for a piece hanging down +rx swings it forward,
+ry turns a forward piece to the boss's left, a backward piece (tail) to its right.
Root's own pose is never applied: lifts and drops go on Body / LowerTorso.
Every attack has Tele and Hit markers 1.5 s apart (WorldBossPlan 4.4 warning).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
import animation_rbxmx as rb

BOSSES = os.path.join(HERE, "..", "..", "Bosses")
FPS = 60


def tree(boss):
    return rb.rig_tree(os.path.join(BOSSES, boss, f"{boss}_rig.json"))


def r(x=0, y=0, z=0, p=(0, 0, 0), **kw):
    spec = {"r": (x, y, z), "p": p}
    spec.update(kw)
    return spec


def mirror(poses):
    """Copy every Left* pose to Right*, flipping y and z rotation and x offset."""
    out = dict(poses)
    for name, spec in poses.items():
        if name.startswith("Left"):
            rx, ry, rz = spec["r"]
            px, py, pz = spec.get("p", (0, 0, 0))
            twin = dict(spec)
            twin["r"] = (rx, -ry, -rz)
            twin["p"] = (-px, py, pz)
            out.setdefault("Right" + name[4:], twin)
    return out


def clip(boss, name, keys, loop=False, priority="Action"):
    """keys: list of (frame, poses, events). Parts missing from a key are keyed at rest."""
    parts = set()
    for _, poses, _ in keys:
        parts |= set(poses)
    keyframes = []
    for frame, poses, events in keys:
        full = {part: poses.get(part, r()) for part in parts}
        keyframes.append({"f": frame, "poses": full, "events": events})
    return {
        "name": f"Boss_{boss}_{name}",
        "boss": boss,
        "loop": loop,
        "priority": priority,
        "fps": FPS,
        "tree": tree(boss),
        "root": "Root",
        "keyframes": keyframes,
    }


# ---------------------------------------------------------------- Big Croc
def croc():
    def tail(a, b=0):
        # a: side sway per segment (degrees), b: droop
        return {f"Tail{i}": r(b, a * (0.6 + 0.2 * i)) for i in range(1, 5)}

    idle = clip("BigCroc", "Idle", [
        (0, {**tail(-5), "Head": r(0, 2), "Jaw": r(0)}, []),
        (60, {**tail(0), "Head": r(3, 0), "Jaw": r(-6)}, []),
        (120, {**tail(5), "Head": r(0, -2), "Jaw": r(0)}, []),
        (180, {**tail(0), "Head": r(3, 0), "Jaw": r(-4)}, []),
        (240, {**tail(-5), "Head": r(0, 2), "Jaw": r(0)}, []),
    ], loop=True, priority="Idle")

    brace = mirror({"LeftFrontUpper": r(-12), "LeftFrontLower": r(10), "LeftBackUpper": r(8)})
    lunge = mirror({"LeftFrontUpper": r(18), "LeftFrontLower": r(-8), "LeftBackUpper": r(-14)})
    attack = clip("BigCroc", "Attack", [
        (0, {}, ["Tele"]),
        (24, {"Body": r(4, p=(0, 0.5, 2)), "Head": r(14), "Jaw": r(-30), **brace, **tail(0, -5)}, []),
        (84, {"Body": r(7, p=(0, 1, 3.5)), "Head": r(24), "Jaw": r(-42), **brace, **tail(0, -8)}, []),
        (90, {"Body": r(-3, p=(0, -0.3, -5)), "Head": r(-10), "Jaw": r(2), **lunge, **tail(0, -3)}, ["Hit"]),
        (102, {"Body": r(-1, p=(0, 0, -4)), "Head": r(-4), "Jaw": r(0), **lunge, **tail(0, -1)}, []),
        (150, {}, []),
    ])

    rear = mirror({"LeftFrontUpper": r(-30), "LeftFrontLower": r(25), "LeftBackUpper": r(-10)})
    mad = clip("BigCroc", "Mad", [
        (0, {}, []),
        (30, {"Body": r(14, p=(0, 1.5, 2)), "Head": r(12), "Jaw": r(-40), **rear, **tail(0, -10)}, []),
        (42, {"Body": r(-2, p=(0, -0.3, 0)), "Head": r(2), "Jaw": r(-4), **tail(0, -3)}, []),
        (62, {"Body": r(12, p=(0, 1.2, 1.5)), "Head": r(10), "Jaw": r(-35), **rear, **tail(0, -9)}, []),
        (74, {"Body": r(-2, p=(0, -0.3, 0)), "Head": r(2), "Jaw": r(-4), **tail(0, -3)}, []),
        (90, {"Head": r(26, 10), "Jaw": r(-36), **tail(8)}, []),
        (108, {"Head": r(28, -10), "Jaw": r(-36), **tail(-8)}, []),
        (126, {"Head": r(26, 10), "Jaw": r(-36), **tail(8)}, []),
        (144, {"Head": r(22, 0), "Jaw": r(-30), **tail(0)}, []),
        (180, {}, []),
    ])
    return [idle, attack, mad]


# ---------------------------------------------------------------- Boulder Crab
def crab():
    def claws(c1, c2, pincer, c1y=0):
        return mirror({"LeftClaw1": r(c1, c1y), "LeftClaw2": r(c2), "LeftPincer": r(pincer)})

    def legs(a):
        # little shuffle: alternate pairs lift (rz: left tip down when positive)
        return mirror({"LeftLeg1_1": r(0, 0, -a), "LeftLeg2_1": r(0, 0, a), "LeftLeg3_1": r(0, 0, -a)})

    idle = clip("BoulderCrab", "Idle", [
        (0, {**claws(0, 0, 0), **legs(0), "Shell": r(0, 0, 0)}, []),
        (40, {**claws(6, 4, -18), **legs(3), "Shell": r(0, 0, 1.5)}, []),
        (80, {**claws(2, 0, -2), **legs(0), "Shell": r(0, 0, 0)}, []),
        (120, {**claws(6, 4, -18, 4), **legs(-3), "Shell": r(0, 0, -1.5)}, []),
        (160, {**claws(0, 0, 0), **legs(0), "Shell": r(0, 0, 0)}, []),
    ], loop=True, priority="Idle")

    attack = clip("BoulderCrab", "Attack", [
        (0, {}, ["Tele"]),
        (24, {"Body": r(4, p=(0, 0.5, 1)), **claws(28, 10, -30)}, []),
        (84, {"Body": r(7, p=(0, 0.8, 2)), **claws(42, 16, -38)}, []),
        (90, {"Body": r(-4, p=(0, -0.4, -2.5)), **claws(0, -1, 0)}, ["Hit"]),
        (102, {"Body": r(-2, p=(0, -0.2, -2)), **claws(-3, -2, 0)}, []),
        (150, {}, []),
    ])

    snap = [(f, -35 if i % 2 == 0 else 0) for i, f in enumerate(range(30, 130, 12))]
    mad_keys = [(0, {}, [])]
    for i, (f, pincer) in enumerate(snap):
        lift = 0.8 if i % 2 == 0 else 0.3
        mad_keys.append((f, {
            "Body": r(6, p=(0, lift, 1)),
            "Shell": r(0, 0, 3 if i % 2 == 0 else -3),
            **claws(55, 22, pincer, 10 if i % 2 == 0 else -6),
        }, []))
    mad_keys.append((140, {"Body": r(-3, p=(0, -0.4, -1)), **claws(-2, -1, 0)}, []))
    mad_keys.append((170, {}, []))
    mad = clip("BoulderCrab", "Mad", mad_keys)
    return [idle, attack, mad]


# ---------------------------------------------------------------- Frost Yeti
def yeti():
    idle = clip("FrostYeti", "Idle", [
        (0, mirror({"UpperTorso": r(0), "Head": r(0), "LeftUpperArm": r(0, 0, 0), "LeftLowerArm": r(4)}), []),
        (90, mirror({"UpperTorso": r(3), "Head": r(-3, 0, 2), "Jaw": r(-6),
                     "LeftUpperArm": r(-4, 0, -3), "LeftLowerArm": r(10)}), []),
        (180, mirror({"UpperTorso": r(0), "Head": r(0), "LeftUpperArm": r(0, 0, 0), "LeftLowerArm": r(4)}), []),
    ], loop=True, priority="Idle")

    up = mirror({"LeftUpperArm": r(150, 0, -10), "LeftLowerArm": r(30)})
    down = mirror({"LeftUpperArm": r(55, 0, 6), "LeftLowerArm": r(10)})
    crouch = mirror({"LeftUpperLeg": r(18), "LeftLowerLeg": r(-30), "LeftFoot": r(12)})
    attack = clip("FrostYeti", "Attack", [
        (0, {}, ["Tele"]),
        (30, {"UpperTorso": r(10), "Head": r(8), **up}, []),
        (84, {"UpperTorso": r(16), "Head": r(12), "Jaw": r(-20), **up}, []),
        (90, {"LowerTorso": r(0, p=(0, -2, -1)), "UpperTorso": r(-28), "Head": r(14), "Jaw": r(-8),
              **down, **crouch}, ["Hit"]),
        (104, {"LowerTorso": r(0, p=(0, -1.6, -1)), "UpperTorso": r(-24), "Head": r(10), **down, **crouch}, []),
        (160, {}, []),
    ])

    def beat(side):
        # one fist on the chest, the other pulled back
        on, off = ("Left", "Right") if side == "L" else ("Right", "Left")
        sign = 1 if on == "Left" else -1
        return {
            f"{on}UpperArm": r(70, 0, 30 * sign), f"{on}LowerArm": r(95),
            f"{off}UpperArm": r(40, 0, -10 * sign), f"{off}LowerArm": r(50),
        }

    mad = clip("FrostYeti", "Mad", [
        (0, {}, []),
        (18, {"UpperTorso": r(6), "Head": r(6), **beat("L")}, []),
        (30, {"UpperTorso": r(4), "Head": r(6), **beat("R")}, []),
        (42, {"UpperTorso": r(6), "Head": r(6), **beat("L")}, []),
        (54, {"UpperTorso": r(4), "Head": r(6), **beat("R")}, []),
        (66, {"UpperTorso": r(6), "Head": r(6), **beat("L")}, []),
        (90, {"UpperTorso": r(14), "Head": r(22), "Jaw": r(-35),
              **mirror({"LeftUpperArm": r(20, 0, -70), "LeftLowerArm": r(20)})}, []),
        (130, {"UpperTorso": r(16), "Head": r(24), "Jaw": r(-38),
               **mirror({"LeftUpperArm": r(24, 0, -76), "LeftLowerArm": r(26)})}, []),
        (170, {}, []),
    ])
    return [idle, attack, mad]


# ---------------------------------------------------------------- fight-flow clips (2026-11-11)
# Sleep (loop) -> Wake (roar) at the start; Stomp (75% Stomp Wave: Tele, Hit = ring spawns);
# BigAttack (half and 25%: Tele, jump, hang during the 4 s countdown, Hit = landing at 4.0 s);
# Dizzy (loop, "Finish it!"); Defeat (tumbles belly-up, the code poofs it after).

def swing(frames, a, b):
    """Alternate between pose dicts a and b on the given frames."""
    return [(f, a if i % 2 == 0 else b, []) for i, f in enumerate(frames)]


def croc_flow():
    B = "BigCroc"

    def tail(a, b=0):
        return {f"Tail{i}": r(b, a * (0.6 + 0.2 * i)) for i in range(1, 5)}

    splay = mirror({"LeftFrontUpper": r(0, 0, -12), "LeftBackUpper": r(0, 0, -12)})
    asleep = {"Body": r(0, p=(0, -1.2, 0)), "Head": r(-8), "Jaw": r(0), **splay, **tail(14, -2)}
    breathe = {"Body": r(1, p=(0, -0.9, 0)), "Head": r(-6), "Jaw": r(-3), **splay, **tail(16, -2)}
    sleep = clip(B, "Sleep", [(0, asleep, []), (90, breathe, []), (180, asleep, [])], loop=True, priority="Idle")

    roar = {"Body": r(10, p=(0, 0.8, 1)), "Head": r(20), "Jaw": r(-48), **tail(0, -8)}
    wake = clip(B, "Wake", [
        (0, asleep, []),
        (30, {**asleep, "Head": r(4, 12)}, []),
        (50, {**asleep, "Head": r(4, -12)}, []),
        (75, {"Body": r(-2, p=(0, -0.5, 0)), "Head": r(-6), **tail(0, 2)}, []),
        (100, roar, ["Roar"]),
        (125, {**roar, "Head": r(22, 8)}, []),
        (150, {**roar, "Head": r(22, -8)}, []),
        (180, {}, []),
    ])

    rear = mirror({"LeftFrontUpper": r(-35), "LeftFrontLower": r(30)})
    slam = mirror({"LeftFrontUpper": r(10, 0, -10)})
    stomp = clip(B, "Stomp", [
        (0, {}, ["Tele"]),
        (40, {"Body": r(16, p=(0, 1.5, 2)), "Head": r(10), "Jaw": r(-25), **rear, **tail(0, -10)}, []),
        (60, {"Body": r(-3, p=(0, -0.4, -1)), "Head": r(-8), "Jaw": r(0), **slam, **tail(0, -3)}, ["Hit"]),
        (75, {"Body": r(-1, p=(0, -0.2, -0.5)), "Head": r(-4), **slam}, []),
        (120, {}, []),
    ])

    tuck = mirror({"LeftFrontUpper": r(-30), "LeftFrontLower": r(40), "LeftBackUpper": r(30), "LeftBackLower": r(-30)})
    crouch = {"Body": r(-3, p=(0, -1, 0)), "Head": r(-6), **mirror({"LeftFrontUpper": r(10), "LeftBackUpper": r(-10)})}
    high = {"Body": r(4, p=(0, 26, 0)), "Head": r(14), "Jaw": r(-30), **tuck, **tail(0, -6)}
    big = clip(B, "BigAttack", [
        (0, {}, ["Tele"]),
        (24, crouch, []),
        (42, {"Body": r(6, p=(0, 18, 0)), "Head": r(12), "Jaw": r(-35), **tuck, **tail(0, -4)}, []),
        (60, high, []),
        (130, {**high, "Body": r(2, p=(0, 27.5, 0)), **tail(10, -6)}, []),
        (200, {**high, **tail(-10, -6)}, []),
        (225, {**high, "Body": r(-6, p=(0, 24, 0)), "Head": r(-6), "Jaw": r(-10)}, []),
        (240, {"Body": r(-2, p=(0, -0.5, 0)), "Head": r(-10), "Jaw": r(0), **splay, **tail(0, -2)}, ["Hit"]),
        (254, {"Body": r(0, p=(0, -0.6, 0)), "Head": r(-4), **splay}, []),
        (300, {}, []),
    ])

    wob_a = {"Body": r(0, 0, 5), "Head": r(8, 18, 10), "Jaw": r(-12), **tail(8, -2)}
    wob_b = {"Body": r(0, 0, -5), "Head": r(8, -18, -10), "Jaw": r(-6), **tail(-8, -2)}
    dizzy = clip(B, "Dizzy", swing([0, 45, 90], wob_a, wob_b), loop=True, priority="Action")

    up = {"Body": r(0, 0, 180, p=(0, 0.4, 0)), "Head": r(-10, 20), "Jaw": r(-30),
          **mirror({"LeftFrontUpper": r(0, 0, 20), "LeftBackUpper": r(0, 0, 20)}), **tail(10, 4)}
    defeat = clip(B, "Defeat", [
        (0, {}, []),
        (20, {"Body": r(4, 0, 30, p=(0, 8, 0)), "Head": r(10, 10), "Jaw": r(-30)}, []),
        (40, {"Body": r(0, 0, 120, p=(0, 13, 0)), "Head": r(0, 15), "Jaw": r(-35)}, []),
        (55, {**up, "Body": r(0, 0, 185, p=(0, -0.4, 0))}, ["Land"]),
        (75, up, []),
        (95, {**up, **mirror({"LeftFrontUpper": r(0, 0, 30), "LeftBackUpper": r(0, 0, 10)})}, []),
        (115, up, []),
    ])
    return [sleep, wake, stomp, big, dizzy, defeat]


def crab_flow():
    B = "BoulderCrab"

    def claws(c1, c2, pincer, c1y=0):
        return mirror({"LeftClaw1": r(c1, c1y), "LeftClaw2": r(c2), "LeftPincer": r(pincer)})

    legs_out = mirror({f"LeftLeg{i}_1": r(0, 0, -14) for i in (1, 2, 3)})
    asleep = {"Body": r(-3, p=(0, -1.5, 0)), **claws(2, 0, 0, -12), **legs_out}
    breathe = {"Body": r(-2, p=(0, -1.1, 0)), **claws(3, 0, -8, -12), **legs_out}
    sleep = clip(B, "Sleep", [(0, asleep, []), (100, breathe, []), (200, asleep, [])], loop=True, priority="Idle")

    roar = {"Body": r(8, p=(0, 0.8, 1)), "Shell": r(0, 0, 3), **claws(60, 25, -40, 15)}
    wake = clip(B, "Wake", [
        (0, asleep, []),
        (30, {**asleep, "Shell": r(0, 0, 3)}, []),
        (50, {**asleep, "Shell": r(0, 0, -3)}, []),
        (75, {"Body": r(0, p=(0, -0.3, 0)), **claws(0, 0, 0)}, []),
        (100, roar, ["Roar"]),
        (120, {**roar, "Shell": r(0, 0, -3), **claws(60, 25, 0, -5)}, []),
        (140, {**roar, **claws(60, 25, -40, 15)}, []),
        (175, {}, []),
    ])

    stomp = clip(B, "Stomp", [
        (0, {}, ["Tele"]),
        (40, {"Body": r(8, p=(0, 0.8, 1.5)), **claws(50, 20, -30)}, []),
        (60, {"Body": r(-4, p=(0, -0.5, -1)), **claws(0, -1, 0)}, ["Hit"]),
        (75, {"Body": r(-2, p=(0, -0.3, -0.5)), **claws(-3, -2, 0)}, []),
        (120, {}, []),
    ])

    tuck = mirror({f"LeftLeg{i}_1": r(0, 0, 25) for i in (1, 2, 3)})
    tuck.update(mirror({f"LeftLeg{i}_2": r(0, 0, 20) for i in (1, 2, 3)}))
    crouch = {"Body": r(0, p=(0, -1.2, 0)), **claws(0, 0, 0)}
    high = {"Body": r(4, p=(0, 24, 0)), **claws(55, 20, -35), **tuck}
    big = clip(B, "BigAttack", [
        (0, {}, ["Tele"]),
        (24, crouch, []),
        (42, {"Body": r(4, p=(0, 16, 0)), **claws(45, 15, -30), **tuck}, []),
        (60, high, []),
        (130, {**high, "Body": r(0, 0, 4, p=(0, 25.5, 0))}, []),
        (200, {**high, "Body": r(0, 0, -4, p=(0, 24, 0))}, []),
        (225, {**high, "Body": r(-6, p=(0, 22, 0)), **claws(0, 0, 0)}, []),
        (240, {"Body": r(-3, p=(0, -0.8, 0)), **claws(0, -1, 0), **legs_out}, ["Hit"]),
        (254, {"Body": r(0, p=(0, -0.4, 0)), **claws(-2, -1, 0), **legs_out}, []),
        (300, {}, []),
    ])

    wob_a = {"Body": r(0, 12, 5), "Shell": r(0, 0, 4), **claws(3, 0, -15, 10)}
    wob_b = {"Body": r(0, -12, -5), "Shell": r(0, 0, -4), **claws(3, 0, -4, -10)}
    dizzy = clip(B, "Dizzy", swing([0, 45, 90], wob_a, wob_b), loop=True, priority="Action")

    kick = lambda a: mirror({f"LeftLeg{i}_1": r(0, 0, a if i != 2 else -a) for i in (1, 2, 3)})
    up = {"Body": r(0, 0, 180, p=(0, 14, 0)), **claws(20, 10, -30), **kick(15)}
    defeat = clip(B, "Defeat", [
        (0, {}, []),
        (20, {"Body": r(0, 0, 35, p=(0, 10, 0)), **claws(30, 10, -30)}, []),
        (40, {"Body": r(0, 0, 120, p=(0, 31, 0)), **claws(45, 15, -30)}, []),
        (48, {"Body": r(0, 0, 158, p=(0, 27, 0)), **claws(40, 15, -30)}, []),
        (55, {**up, "Body": r(0, 0, 185, p=(0, 13, 0))}, ["Land"]),
        (75, up, []),
        (90, {**up, **kick(-15)}, []),
        (105, up, []),
        (120, {**up, **kick(-10)}, []),
    ])
    return [sleep, wake, stomp, big, dizzy, defeat]


def yeti_flow():
    B = "FrostYeti"
    slump = {"UpperTorso": r(-18), "Head": r(-20, 0, 8),
             **mirror({"LeftUpperArm": r(-6, 0, 4), "LeftLowerArm": r(6)})}
    breathe = {**slump, "UpperTorso": r(-14), "Head": r(-18, 0, 8), "Jaw": r(-6)}
    sleep = clip(B, "Sleep", [(0, slump, []), (100, breathe, []), (200, slump, [])], loop=True, priority="Idle")

    roar = {"UpperTorso": r(16), "Head": r(24), "Jaw": r(-40),
            **mirror({"LeftUpperArm": r(30, 0, -75), "LeftLowerArm": r(40)})}
    wake = clip(B, "Wake", [
        (0, slump, []),
        (30, {**slump, "Head": r(-10, 15, 0)}, []),
        (55, {**slump, "Head": r(-10, -15, 0)}, []),
        (80, {"UpperTorso": r(-8), "Head": r(-4), **mirror({"LeftUpperArm": r(20), "LeftLowerArm": r(60)})}, []),
        (105, roar, ["Roar"]),
        (150, {**roar, "Head": r(26, 0, 6)}, []),
        (185, {}, []),
    ])

    knee = mirror({"LeftUpperLeg": r(14), "LeftLowerLeg": r(-26), "LeftFoot": r(12)})
    stomp = clip(B, "Stomp", [
        (0, {}, ["Tele"]),
        (40, {"UpperTorso": r(8), "RightUpperLeg": r(60), "RightLowerLeg": r(-50),
              **mirror({"LeftUpperArm": r(0, 0, -50), "LeftLowerArm": r(30)})}, []),
        (60, {"LowerTorso": r(0, p=(0, -1.5, 0)), "UpperTorso": r(-10), "RightUpperLeg": r(10), **knee,
              **mirror({"LeftUpperArm": r(10, 0, -30), "LeftLowerArm": r(20)})}, ["Hit"]),
        (75, {"LowerTorso": r(0, p=(0, -1, 0)), "UpperTorso": r(-6), **knee}, []),
        (120, {}, []),
    ])

    tuckl = mirror({"LeftUpperLeg": r(50), "LeftLowerLeg": r(-70)})
    crouch = {"LowerTorso": r(0, p=(0, -2, 0)), "UpperTorso": r(-14), **knee,
              **mirror({"LeftUpperArm": r(-8, 0, 10)})}
    high = {"LowerTorso": r(0, p=(0, 28, 0)), "UpperTorso": r(10), "Head": r(12), "Jaw": r(-30),
            **mirror({"LeftUpperArm": r(160, 0, -15), "LeftLowerArm": r(20)}), **tuckl}
    land = {"LowerTorso": r(0, p=(0, -3, -1)), "UpperTorso": r(-30), "Head": r(14),
            **mirror({"LeftUpperArm": r(60, 0, 8), "LeftLowerArm": r(10)}), **knee}
    big = clip(B, "BigAttack", [
        (0, {}, ["Tele"]),
        (24, crouch, []),
        (42, {**high, "LowerTorso": r(0, p=(0, 20, 0))}, []),
        (60, high, []),
        (130, {**high, "LowerTorso": r(0, 0, 4, p=(0, 29.5, 0))}, []),
        (200, {**high, "LowerTorso": r(0, 0, -4, p=(0, 28, 0))}, []),
        (225, {**high, "LowerTorso": r(0, p=(0, 25, 0)), "UpperTorso": r(-10)}, []),
        (240, land, ["Hit"]),
        (256, {**land, "LowerTorso": r(0, p=(0, -2.4, -1))}, []),
        (300, {}, []),
    ])

    wob_a = {"UpperTorso": r(-6, 0, 8), "Head": r(-6, 15, 12), "Jaw": r(-18),
             **mirror({"LeftUpperArm": r(-4, 0, -6)})}
    wob_b = {"UpperTorso": r(-6, 0, -8), "Head": r(-6, -15, -12), "Jaw": r(-10),
             **mirror({"LeftUpperArm": r(-4, 0, 6)})}
    dizzy = clip(B, "Dizzy", swing([0, 50, 100], wob_a, wob_b), loop=True, priority="Action")

    flat = {"LowerTorso": r(90, p=(0, -1, 4)), "Head": r(10, 20), "Jaw": r(-30),
            **mirror({"LeftUpperArm": r(0, 0, -70), "LeftLowerArm": r(10)}), **mirror({"LeftUpperLeg": r(0, 0, -15)})}
    defeat = clip(B, "Defeat", [
        (0, {}, []),
        (20, {"UpperTorso": r(-12), "Head": r(-10, 15), "Jaw": r(-25),
              **mirror({"LeftUpperArm": r(30, 0, -20)})}, []),
        (45, {"LowerTorso": r(55, p=(0, 2, 2)), "Head": r(10), "Jaw": r(-30),
              **mirror({"LeftUpperArm": r(20, 0, -60)})}, []),
        (60, {**flat, "LowerTorso": r(92, p=(0, -0.5, 4))}, ["Land"]),
        (80, flat, []),
        (100, {**flat, **mirror({"LeftUpperLeg": r(15, 0, -15)})}, []),
        (120, flat, []),
    ])
    return [sleep, wake, stomp, big, dizzy, defeat]


def all_clips():
    return croc() + crab() + yeti() + croc_flow() + crab_flow() + yeti_flow()


def main():
    out_dir = os.path.join(HERE, "build")
    os.makedirs(out_dir, exist_ok=True)
    clips = all_clips()
    preview = {}
    for c in clips:
        with open(os.path.join(out_dir, c["name"] + ".rbxmx"), "w", encoding="utf-8") as handle:
            handle.write(rb.clip_xml(c))
        data = rb.clip_json(c)
        data["priority"] = c["priority"]
        data["tree"] = c["tree"]
        preview[c["name"]] = data
    with open(os.path.join(out_dir, "preview.json"), "w", encoding="utf-8") as handle:
        json.dump(preview, handle, separators=(",", ":"))
    print("built", len(clips), "clips")

    if len(sys.argv) > 1 and sys.argv[1] == "upload":
        names = set(sys.argv[2:])
        ids_path = os.path.join(HERE, "ids.json")
        ids = json.load(open(ids_path, encoding="utf-8")) if os.path.exists(ids_path) else {}
        for c in clips:
            if names and c["name"] not in names:
                continue
            if not names and c["name"] in ids:
                continue  # already uploaded; name it explicitly to upload a new version
            asset_id, detail = rb.upload(os.path.join(out_dir, c["name"] + ".rbxmx"), c["name"].replace("_", " "))
            print(c["name"], asset_id or detail[:300])
            if asset_id:
                ids[c["name"]] = asset_id
                with open(ids_path, "w", encoding="utf-8") as handle:
                    json.dump(ids, handle, indent=2)


if __name__ == "__main__":
    main()
