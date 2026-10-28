import json
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "..", "scripts"))
import animation_rbxmx as rb

JOINTS = [
    "LowerTorso", "UpperTorso", "Head",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
]

SAMPLE_FRAMES = 3


def ease(name, a):
    a = max(0.0, min(1.0, a))
    if name == "linear":
        return a
    if name == "in":
        return a * a * a
    if name == "out":
        return 1 - (1 - a) ** 3
    if name == "back":
        s = 1.70158
        b = a - 1
        return 1 + (s + 1) * b ** 3 + s * b ** 2
    if name == "snap":
        return 1 - (1 - a) ** 5
    return a * a * (3 - 2 * a)


def blank():
    return {joint: [0.0] * 6 for joint in JOINTS}


def pose(**joints):
    result = blank()
    for joint, values in joints.items():
        rot = list(values[0]) if len(values) > 0 else [0, 0, 0]
        pos = list(values[1]) if len(values) > 1 else [0, 0, 0]
        result[joint] = [float(v) for v in rot + pos]
    return result


def merge(base, **joints):
    result = {joint: list(values) for joint, values in base.items()}
    for joint, values in joints.items():
        rot = list(values[0]) if len(values) > 0 else result[joint][:3]
        pos = list(values[1]) if len(values) > 1 else result[joint][3:]
        result[joint] = [float(v) for v in rot + pos]
    return result


def lerp_pose(a, b, alpha):
    return {joint: [a[joint][i] + (b[joint][i] - a[joint][i]) * alpha for i in range(6)] for joint in JOINTS}


def add_pose(a, delta):
    result = {joint: list(values) for joint, values in a.items()}
    for joint, values in delta.items():
        for i, value in enumerate(values):
            result[joint][i] += value
    return result


def evaluate(keys, frame):
    if frame <= keys[0][0]:
        return keys[0][1]
    for index in range(1, len(keys)):
        start_frame, start_pose = keys[index - 1][0], keys[index - 1][1]
        end_frame, end_pose = keys[index][0], keys[index][1]
        curve = keys[index][2] if len(keys[index]) > 2 else "smooth"
        if frame <= end_frame:
            alpha = (frame - start_frame) / max(1, end_frame - start_frame)
            return lerp_pose(start_pose, end_pose, ease(curve, alpha))
    return keys[-1][1]


def build(name, frames, keys, layers=(), events=None, loop=False, holds=()):
    events = events or {}
    sample_frames = set(range(0, frames + 1, SAMPLE_FRAMES))
    sample_frames.add(frames)
    for key in keys:
        sample_frames.add(key[0])
    sample_frames.update(events.keys())
    sample_frames.update(holds)
    keyframes = []
    for frame in sorted(f for f in sample_frames if 0 <= f <= frames):
        current = evaluate(keys, frame)
        for layer in layers:
            current = add_pose(current, layer(frame))
        poses = {}
        for joint, values in current.items():
            poses[joint] = {"r": tuple(values[:3]), "p": tuple(values[3:]), "style": "Linear", "dir": "In"}
        keyframe = {"f": frame, "poses": poses}
        if frame in events:
            keyframe["events"] = events[frame]
        keyframes.append(keyframe)
    return {"name": name, "loop": loop, "keyframes": keyframes, "frames": frames}


def wave(frame, period, amplitude, phase=0.0):
    return amplitude * math.sin(2 * math.pi * (frame / period + phase))


def window(frame, start, end, fade=4):
    if frame < start or frame > end:
        return 0.0
    return min(1.0, (frame - start) / fade, (end - frame) / fade) if fade > 0 else 1.0


SEATED_LEGS = {
    "LeftUpperLeg": [(90, 0, -4)],
    "LeftLowerLeg": [(-88, 0, 0)],
    "RightUpperLeg": [(90, 0, 4)],
    "RightLowerLeg": [(-88, 0, 0)],
}

WHEEL_ARMS = {
    "LeftUpperArm": [(58, 0, 14)],
    "LeftLowerArm": [(38, 0, 0)],
    "RightUpperArm": [(58, 0, -14)],
    "RightLowerArm": [(38, 0, 0)],
}

DRIVE_BASE = pose(UpperTorso=[(6, 0, 0)], **SEATED_LEGS, **WHEEL_ARMS)


def player_drive():
    def layer(frame):
        cycle = (frame % 30) / 30
        bump = -0.1 * math.sin(math.pi * min(1, cycle / 0.5)) if cycle < 0.5 else 0.0
        head_bump = -0.1 * math.sin(math.pi * min(1, max(0, cycle - 0.12) / 0.5)) if 0.12 <= cycle < 0.62 else 0.0
        steer = wave(frame, 120, 6, 0)
        tilt = wave(frame, 120, 8, 0)
        return {
            "LowerTorso": [0, 0, 0, 0, bump, 0],
            "UpperTorso": [head_bump * 20, 0, 0],
            "Head": [head_bump * 25, 0, tilt],
            "LeftUpperArm": [0, 0, 0],
            "LeftLowerArm": [steer, 0, 0],
            "RightLowerArm": [-steer, 0, 0],
            "LeftHand": [0, 0, steer],
            "RightHand": [0, 0, steer],
        }

    return build("Intro_Player_Drive", 120, [(0, DRIVE_BASE), (120, DRIVE_BASE)], [layer], loop=True)


YIKES_ARMS = {
    "LeftUpperArm": [(70, 0, -55)],
    "LeftLowerArm": [(95, 0, 0)],
    "RightUpperArm": [(70, 0, 55)],
    "RightLowerArm": [(95, 0, 0)],
    "LeftHand": [(-20, 0, 0)],
    "RightHand": [(-20, 0, 0)],
}

LOOKUP_END = merge(
    DRIVE_BASE,
    UpperTorso=[(18, 0, 0)],
    Head=[(40, 0, 0)],
    **YIKES_ARMS,
)


def player_lookup():
    startle = merge(DRIVE_BASE, UpperTorso=[(4, 0, 0), (0, 0.1, 0)], Head=[(0, 12, 0)])
    looking = merge(DRIVE_BASE, UpperTorso=[(18, 0, 0)], Head=[(40, 0, 0)])

    def tremble(frame):
        strength = 0.0 if frame < 30 else 1.5 + 1.0 * (frame - 30) / 30
        shake = strength * (1 if (frame // 2) % 2 == 0 else -1)
        return {
            "Head": [shake * 0.8, 0, shake],
            "LeftUpperArm": [shake, 0, 0],
            "RightUpperArm": [-shake, 0, 0],
        }

    keys = [
        (0, DRIVE_BASE),
        (4, startle, "snap"),
        (8, startle),
        (20, looking, "out"),
        (30, LOOKUP_END, "snap"),
        (60, LOOKUP_END),
    ]
    return build("Intro_Player_LookUp", 60, keys, [tremble], holds=(58, 60))


DAZED_BASE = pose(
    LowerTorso=[(0, 0, 0), (0, -1.55, 0)],
    UpperTorso=[(10, 0, 0)],
    Head=[(0, 0, 0)],
    LeftUpperArm=[(-35, 0, -12)],
    LeftLowerArm=[(10, 0, 0)],
    RightUpperArm=[(-35, 0, 12)],
    RightLowerArm=[(10, 0, 0)],
    LeftUpperLeg=[(84, 0, -10)],
    LeftLowerLeg=[(-14, 0, 0)],
    LeftFoot=[(-20, 0, 0)],
    RightUpperLeg=[(84, 0, 10)],
    RightLowerLeg=[(-14, 0, 0)],
    RightFoot=[(-20, 0, 0)],
)

BOING_END_OFFSET = (-9.0, -1.5, 0.0)
BOING_END_TURN = -90.0


def player_boing():
    squash = merge(
        LOOKUP_END,
        LowerTorso=[(0, 0, 0), (0, -0.3, 0)],
        UpperTorso=[(-10, 0, 0)],
        Head=[(-15, 0, 0)],
        LeftUpperArm=[(20, 0, 10)],
        LeftLowerArm=[(110, 0, 0)],
        RightUpperArm=[(20, 0, -10)],
        RightLowerArm=[(110, 0, 0)],
    )

    def starfish(x, y, turn, flail=0):
        return pose(
            LowerTorso=[(10, turn, 0), (x, y, 0)],
            UpperTorso=[(8, 0, 0)],
            Head=[(15, 0, 0)],
            LeftUpperArm=[(20 + flail, 0, -150)],
            LeftLowerArm=[(10, 0, 0)],
            RightUpperArm=[(20 - flail, 0, 150)],
            RightLowerArm=[(10, 0, 0)],
            LeftUpperLeg=[(25, 0, -40)],
            LeftLowerLeg=[(-25, 0, 0)],
            RightUpperLeg=[(25, 0, 40)],
            RightLowerLeg=[(-25, 0, 0)],
        )

    def falling(x, y, turn):
        return pose(
            LowerTorso=[(-5, turn, 0), (x, y, 0)],
            UpperTorso=[(12, 0, 0)],
            Head=[(20, 0, 0)],
            LeftUpperArm=[(60, 0, -120)],
            LeftLowerArm=[(20, 0, 0)],
            RightUpperArm=[(60, 0, 120)],
            RightLowerArm=[(20, 0, 0)],
            LeftUpperLeg=[(80, 0, -14)],
            LeftLowerLeg=[(-20, 0, 0)],
            RightUpperLeg=[(80, 0, 14)],
            RightLowerLeg=[(-20, 0, 0)],
        )

    ex, ey, _ = BOING_END_OFFSET
    landed = merge(DAZED_BASE, LowerTorso=[(0, BOING_END_TURN, 0), (ex, ey, 0)])
    bounce_up = merge(landed, LowerTorso=[(-6, BOING_END_TURN, 0), (ex, ey + 0.5, 0)], UpperTorso=[(18, 0, 0)])
    impact = merge(landed, LowerTorso=[(4, BOING_END_TURN, 0), (ex, ey - 0.08, 0)], UpperTorso=[(-4, 0, 0)])
    settle = merge(DAZED_BASE, LowerTorso=[(0, BOING_END_TURN, 0), (ex, ey, 0)])

    def arc(frame):
        if 6 <= frame <= 52:
            a = (frame - 6) / 46
            peak = 6.0
            height = 4 * peak * a * (1 - a) + ey * a
            x = ex * a
            turn = BOING_END_TURN * ease("smooth", a)
            return x, height, turn
        return None

    keys = [(0, LOOKUP_END), (6, squash, "out")]
    for frame in range(9, 31, 3):
        x, y, turn = arc(frame)
        flail = 40 * math.sin(frame * 0.5)
        keys.append((frame, starfish(x, y, turn, flail), "linear"))
    for frame in range(33, 52, 3):
        x, y, turn = arc(frame)
        keys.append((frame, falling(x, y, turn), "linear"))
    keys.append((52, impact, "in"))
    keys.append((58, bounce_up, "out"))
    keys.append((64, merge(impact), "in"))
    keys.append((72, settle, "smooth"))
    return build("Intro_Player_BoingOut", 72, keys, events={6: ["Boing"], 52: ["Touchdown"]})


def player_dazed():
    def layer(frame):
        a = 2 * math.pi * frame / 90
        return {
            "Head": [10 * math.sin(a), 0, 10 * math.cos(a)],
            "UpperTorso": [-4 * math.sin(a - 0.8), 0, -4 * math.cos(a - 0.8)],
        }

    return build("Intro_Player_Dazed", 90, [(0, DAZED_BASE), (90, DAZED_BASE)], [layer], loop=True)


def player_awe():
    dazed_start = add_pose(DAZED_BASE, {"Head": [0, 0, 10], "UpperTorso": [0, 0, -4 * math.cos(-0.8)]})
    snap = merge(DAZED_BASE, Head=[(10, 0, 0)], UpperTorso=[(4, 0, 0)])
    wonder = merge(
        DAZED_BASE,
        UpperTorso=[(-20, 0, 0)],
        Head=[(18, 0, 0)],
        LeftUpperArm=[(80, 0, 18)],
        LeftLowerArm=[(85, 0, 0)],
        RightUpperArm=[(80, 0, -18)],
        RightLowerArm=[(85, 0, 0)],
        LeftHand=[(0, 0, 0)],
        RightHand=[(0, 0, 0)],
    )
    pumped = merge(
        wonder,
        LowerTorso=[(0, 0, 0), (0, -1.35, 0)],
        UpperTorso=[(-14, 0, 0), (0, 0.15, 0)],
        Head=[(12, 0, 0)],
        LeftUpperArm=[(40, 0, 25)],
        LeftLowerArm=[(120, 0, 0)],
        RightUpperArm=[(40, 0, -25)],
        RightLowerArm=[(120, 0, 0)],
    )
    stare = merge(pumped, LowerTorso=[(0, 0, 0), (0, -1.55, 0)], UpperTorso=[(-22, 0, 0)], Head=[(16, 0, 0)])

    def vibrate(frame):
        v = 1.0 if (frame // 2) % 2 == 0 else -1.0
        amount = window(frame, 35, 55, 3)
        return {"Head": [v * amount, 0, -v * amount], "LeftUpperArm": [v * amount, 0, 0], "RightUpperArm": [-v * amount, 0, 0]}

    keys = [
        (0, dazed_start),
        (10, snap, "snap"),
        (35, wonder, "out"),
        (55, wonder),
        (62, pumped, "snap"),
        (70, merge(pumped, LowerTorso=[(0, 0, 0), (0, -1.55, 0)]), "in"),
        (90, stare, "smooth"),
    ]
    return build("Intro_Player_Awe", 90, keys, [vibrate])


IDLE_BASE = pose(
    UpperTorso=[(-2, 0, 0)],
    Head=[(6, 0, 0)],
    LeftUpperArm=[(-28, 0, 10)],
    LeftLowerArm=[(70, 0, 0)],
    LeftHand=[(0, 0, 0)],
    RightUpperArm=[(-28, 0, -10)],
    RightLowerArm=[(70, 0, 0)],
    LeftUpperLeg=[(0, 0, -4)],
    RightUpperLeg=[(0, 0, 4)],
)

STAND = pose(
    UpperTorso=[(0, 0, 0)],
    LeftUpperArm=[(0, 0, -6)],
    RightUpperArm=[(0, 0, 6)],
    LeftLowerArm=[(6, 0, 0)],
    RightLowerArm=[(6, 0, 0)],
)


def master_idle():
    def layer(frame):
        breath = 0.5 - 0.5 * math.cos(2 * math.pi * frame / 180)
        nod = -2 * math.exp(-(((frame - 120) / 10) ** 2))
        return {
            "UpperTorso": [-breath * 1.0, 0, 0, 0, breath * 0.03, 0],
            "Head": [nod - breath * 0.5, 0, 0],
            "LeftUpperArm": [0, 0, breath * 1.0],
            "RightUpperArm": [0, 0, -breath * 1.0],
        }

    return build("Intro_Master_Idle", 180, [(0, IDLE_BASE), (180, IDLE_BASE)], [layer], loop=True)


LEAP_FORWARD = 30.0
LEAP_DROP = 22.0
LEAP_PEAK = 4.0


def master_leap():
    crouch = pose(
        LowerTorso=[(-25, 0, 0), (0, -1.2, 0.3)],
        UpperTorso=[(-25, 0, 0)],
        Head=[(30, 0, 0)],
        LeftUpperArm=[(-60, 0, -12)],
        LeftLowerArm=[(20, 0, 0)],
        RightUpperArm=[(-60, 0, 12)],
        RightLowerArm=[(20, 0, 0)],
        LeftUpperLeg=[(75, 0, -6)],
        LeftLowerLeg=[(-100, 0, 0)],
        LeftFoot=[(25, 0, 0)],
        RightUpperLeg=[(75, 0, 6)],
        RightLowerLeg=[(-100, 0, 0)],
        RightFoot=[(25, 0, 0)],
    )

    def path(frame):
        a = max(0.0, min(1.0, (frame - 20) / 70))
        z = -LEAP_FORWARD * a
        top = LEAP_PEAK + LEAP_DROP
        y = top * (1 - ((a - 0.36) / 0.36) ** 2) if a < 0.36 else LEAP_PEAK - (LEAP_PEAK + LEAP_DROP) * ((a - 0.36) / 0.64) ** 2
        if a < 0.36:
            y = LEAP_PEAK * (1 - ((a - 0.36) / 0.36) ** 2)
        return y, z

    def airborne(frame, spin, tuck):
        y, z = path(frame)
        return pose(
            LowerTorso=[(spin, 0, 0), (0, y, z)],
            UpperTorso=[(-20 * tuck, 0, 0)],
            Head=[(-10 * tuck, 0, 0)],
            LeftUpperArm=[(150 - 90 * tuck, 0, -20)],
            LeftLowerArm=[(30 + 60 * tuck, 0, 0)],
            RightUpperArm=[(150 - 90 * tuck, 0, 20)],
            RightLowerArm=[(30 + 60 * tuck, 0, 0)],
            LeftUpperLeg=[(20 + 90 * tuck, 0, -6)],
            LeftLowerLeg=[(-20 - 110 * tuck, 0, 0)],
            RightUpperLeg=[(20 + 90 * tuck, 0, 6)],
            RightLowerLeg=[(-20 - 110 * tuck, 0, 0)],
        )

    land_y, land_z = -LEAP_DROP, -LEAP_FORWARD
    hero = pose(
        LowerTorso=[(-20, 0, 0), (0, land_y - 1.5, land_z)],
        UpperTorso=[(-30, 0, 0)],
        Head=[(-15, 0, 0)],
        LeftUpperArm=[(-40, 0, -50)],
        LeftLowerArm=[(10, 0, 0)],
        RightUpperArm=[(55, 0, 8)],
        RightLowerArm=[(10, 0, 0)],
        RightHand=[(-30, 0, 0)],
        LeftUpperLeg=[(95, 0, -10)],
        LeftLowerLeg=[(-95, 0, 0)],
        LeftFoot=[(0, 0, 0)],
        RightUpperLeg=[(10, 0, 8)],
        RightLowerLeg=[(-135, 0, 0)],
        RightFoot=[(40, 0, 0)],
    )
    hero_low = merge(hero, LowerTorso=[(-22, 0, 0), (0, land_y - 1.62, land_z)], UpperTorso=[(-33, 0, 0)])
    half_up = merge(
        STAND,
        LowerTorso=[(-8, 0, 0), (0, land_y - 0.6, land_z)],
        UpperTorso=[(-12, 0, 0)],
        Head=[(-20, 0, 0)],
        LeftUpperLeg=[(40, 0, -6)],
        LeftLowerLeg=[(-60, 0, 0)],
        RightUpperLeg=[(30, 0, 6)],
        RightLowerLeg=[(-50, 0, 0)],
    )
    standing = merge(STAND, LowerTorso=[(0, 0, 0), (0, land_y, land_z)], Head=[(0, 0, 0)])
    head_down = merge(standing, Head=[(-12, 0, 0)])

    keys = [(0, IDLE_BASE), (20, crouch, "smooth")]
    for frame in range(23, 91, 3):
        if frame < 30:
            spin, tuck = 0.0, 0.0
        elif frame <= 75:
            a = (frame - 30) / 45
            spin = -360 * ease("smooth", a)
            tuck = math.sin(math.pi * a)
        else:
            spin, tuck = -360.0, 0.0
        body = airborne(frame, spin, tuck)
        if frame > 75:
            body = merge(
                body,
                LeftUpperArm=[(40, 0, -80)],
                RightUpperArm=[(40, 0, 80)],
                LeftUpperLeg=[(25, 0, -8)],
                RightUpperLeg=[(15, 0, 8)],
                LeftLowerLeg=[(-30, 0, 0)],
                RightLowerLeg=[(-40, 0, 0)],
            )
        keys.append((frame, body, "linear"))
    keys.append((90, hero, "in"))
    keys.append((96, hero_low, "out"))
    keys.append((108, hero_low))
    keys.append((128, half_up, "smooth"))
    keys.append((140, head_down, "smooth"))
    keys.append((150, standing, "out"))
    return build("Intro_Master_Leap", 150, keys, events={90: ["Land"]})


def master_chop():
    start = STAND
    turned = merge(STAND, LowerTorso=[(0, 180, 0)])
    stance = pose(
        LowerTorso=[(0, 180, 0), (0, -0.9, 0)],
        UpperTorso=[(4, -15, 0)],
        Head=[(-4, 15, 0)],
        RightUpperArm=[(190, 0, 10)],
        RightLowerArm=[(45, 0, 0)],
        RightHand=[(0, -90, 0)],
        LeftUpperArm=[(80, 0, 0)],
        LeftLowerArm=[(10, 0, 0)],
        LeftHand=[(0, 90, 0)],
        LeftUpperLeg=[(35, 0, -35)],
        LeftLowerLeg=[(-45, 0, 0)],
        LeftFoot=[(10, 0, 20)],
        RightUpperLeg=[(35, 0, 35)],
        RightLowerLeg=[(-45, 0, 0)],
        RightFoot=[(10, 0, -20)],
    )
    gathered = merge(
        stance,
        LowerTorso=[(0, 180, 0), (0, -0.7, 0)],
        UpperTorso=[(12, -22, 0)],
        RightUpperArm=[(205, 0, 14)],
        RightLowerArm=[(75, 0, 0)],
        Head=[(-8, 22, 0)],
    )
    struck = merge(
        stance,
        LowerTorso=[(-8, 180, 0), (0, -1.25, 0)],
        UpperTorso=[(-25, 18, 0)],
        Head=[(10, -10, 0)],
        RightUpperArm=[(35, 0, -25)],
        RightLowerArm=[(5, 0, 0)],
        LeftUpperArm=[(-35, 0, -25)],
        LeftLowerArm=[(80, 0, 0)],
        LeftUpperLeg=[(45, 0, -38)],
        LeftLowerLeg=[(-60, 0, 0)],
        RightUpperLeg=[(45, 0, 38)],
        RightLowerLeg=[(-60, 0, 0)],
    )
    struck_hold = merge(struck, LowerTorso=[(-9, 180, 0), (0, -1.3, 0)])
    upright = merge(STAND, LowerTorso=[(0, 180, 0)])
    palms = merge(
        upright,
        LeftUpperArm=[(55, 0, 20)],
        LeftLowerArm=[(70, 0, 0)],
        RightUpperArm=[(55, 0, -20)],
        RightLowerArm=[(70, 0, 0)],
    )
    bow = merge(palms, UpperTorso=[(-15, 0, 0)], Head=[(-8, 0, 0)])

    keys = [
        (0, start),
        (20, turned, "smooth"),
        (40, stance, "out"),
        (150, gathered, "smooth"),
        (162, struck, "snap"),
        (185, struck_hold, "linear"),
        (200, palms, "smooth"),
        (210, bow, "out"),
    ]
    return build("Intro_Master_Chop", 210, keys, events={160: ["Impact"]}, holds=(150, 151, 153, 156, 159, 160))


def master_point():
    start = merge(STAND, LowerTorso=[(0, 180, 0)], UpperTorso=[(-15, 0, 0)], Head=[(-8, 0, 0)],
                  LeftUpperArm=[(55, 0, 20)], LeftLowerArm=[(70, 0, 0)],
                  RightUpperArm=[(55, 0, -20)], RightLowerArm=[(70, 0, 0)])
    hop = merge(STAND, LowerTorso=[(0, 90, 0), (0, 0.4, 0)])
    facing = merge(STAND, LowerTorso=[(0, 0, 0)])
    point = merge(
        facing,
        UpperTorso=[(6, 8, 0)],
        Head=[(-2, -8, 0)],
        RightUpperArm=[(90, 0, 0)],
        RightLowerArm=[(0, 0, 0)],
        LeftUpperArm=[(-10, 0, -35)],
        LeftLowerArm=[(100, 0, 0)],
    )
    nod = merge(point, Head=[(-10, -8, 0)])
    horizon = merge(
        point,
        UpperTorso=[(8, 20, 0)],
        Head=[(10, 25, 0)],
        RightUpperArm=[(120, 0, -60)],
    )

    keys = [
        (0, start),
        (10, hop, "out"),
        (20, facing, "in"),
        (38, point, "snap"),
        (50, point),
        (57, nod, "smooth"),
        (65, point, "smooth"),
        (90, point),
        (110, horizon, "smooth"),
        (150, horizon),
    ]
    return build("Intro_Master_Point", 150, keys, events={38: ["Point"]})


CLIPS = {
    "Intro_Player_Drive": player_drive,
    "Intro_Player_LookUp": player_lookup,
    "Intro_Player_BoingOut": player_boing,
    "Intro_Player_Dazed": player_dazed,
    "Intro_Player_Awe": player_awe,
    "Intro_Master_Idle": master_idle,
    "Intro_Master_Leap": master_leap,
    "Intro_Master_Chop": master_chop,
    "Intro_Master_Point": master_point,
}


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "build")
    os.makedirs(out_dir, exist_ok=True)
    names = sys.argv[2:] or list(CLIPS)
    mode = sys.argv[1] if len(sys.argv) > 1 else "build"
    ids_path = os.path.join(os.path.dirname(__file__), "ids.json")
    ids = json.load(open(ids_path)) if os.path.exists(ids_path) else {}
    for name in names:
        clip = CLIPS[name]()
        xml_path = os.path.join(out_dir, f"{name}.rbxmx")
        with open(xml_path, "w", encoding="utf-8") as handle:
            handle.write(rb.clip_xml(clip))
        with open(os.path.join(out_dir, f"{name}.json"), "w", encoding="utf-8") as handle:
            json.dump(rb.clip_json(clip), handle, separators=(",", ":"))
        print(name, len(clip["keyframes"]), "keyframes")
        if mode == "upload":
            asset_id, detail = rb.upload(xml_path, name.replace("_", " "))
            print(" ->", asset_id or detail[:300])
            if asset_id:
                ids[name] = asset_id
                with open(ids_path, "w", encoding="utf-8") as handle:
                    json.dump(ids, handle, indent=2)


if __name__ == "__main__":
    main()
