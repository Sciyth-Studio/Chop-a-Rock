import hashlib
import json
import os
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "Icons")
MANIFEST = os.path.join(ROOT, ".claude", "skills", "item-icons", "manifest.json")
UPLOADED = os.path.join(ICONS, "uploaded.json")
CONFIG = os.path.join(ROOT, "src", "shared", "Config", "ItemIconConfig.luau")
GROUP_ID = "10962733"
API = "https://apis.roblox.com/assets/v1"
KEY_VAR = "ROBLOX_API_KEY"


def api_key():
    key = os.environ.get(KEY_VAR)
    if not key and os.name == "nt":
        import winreg

        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as reg:
                key = winreg.QueryValueEx(reg, KEY_VAR)[0]
        except OSError:
            key = None
    if not key:
        sys.exit(f"{KEY_VAR} is not set. See the item-icons skill for how to create the group API key.")
    return key


def curl(key, args):
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as header:
        header.write(f"x-api-key: {key}\n")
    try:
        result = subprocess.run(["curl", "-s", "-H", f"@{header.name}", *args], capture_output=True, text=True)
    finally:
        os.remove(header.name)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        return {"raw": result.stdout, "stderr": result.stderr}


def upload(key, path, display_name):
    request = {
        "assetType": "Image",
        "displayName": display_name,
        "description": "Chop a Rock item icon",
        "creationContext": {"creator": {"groupId": GROUP_ID}},
    }
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as req:
        json.dump(request, req)
    try:
        op = curl(key, ["-X", "POST", f"{API}/assets", "-F", f"request=<{req.name};type=application/json", "-F", f"fileContent=@{path};type=image/png"])
    finally:
        os.remove(req.name)
    if "path" not in op:
        raise RuntimeError(f"upload failed for {display_name}: {op}")
    for _ in range(30):
        time.sleep(2)
        status = curl(key, [f"{API}/{op['path']}"])
        if status.get("done"):
            asset_id = status.get("response", {}).get("assetId")
            if not asset_id:
                raise RuntimeError(f"upload failed for {display_name}: {status}")
            return f"rbxassetid://{asset_id}"
    raise RuntimeError(f"upload timed out for {display_name}: {op['path']}")


def file_hash(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def write_config(uploaded):
    kinds = {}
    for key, entry in uploaded.items():
        kind, name = key.split("/")
        kinds.setdefault(kind, {})[name] = entry["id"]
    for kind in ("Pet", "Rock"):
        kinds.setdefault(kind, {})
    lines = ["--!strict", "", "local ItemIconConfig: { [string]: { [string]: string } } = {"]
    for kind in sorted(kinds):
        names = kinds[kind]
        if not names:
            lines.append(f"\t{kind} = table.freeze({{}}),")
            continue
        lines.append(f"\t{kind} = table.freeze({{")
        for name in sorted(names):
            lines.append(f'\t\t{name} = "{names[name]}",')
        lines.append("\t}),")
    lines += ["}", "", "return table.freeze(ItemIconConfig)", ""]
    with open(CONFIG, "w", newline="\n") as f:
        f.write("\n".join(lines))


def main():
    manifest = json.load(open(MANIFEST))
    uploaded = json.load(open(UPLOADED)) if os.path.exists(UPLOADED) else {}
    if "--config-only" in sys.argv:
        write_config(uploaded)
        print(f"wrote {CONFIG}")
        return
    pending = []
    for key in manifest:
        path = os.path.join(ICONS, key.replace("/", "_") + ".png")
        if not os.path.exists(path):
            print(f"skip {key}: no PNG")
            continue
        digest = file_hash(path)
        if uploaded.get(key, {}).get("hash") != digest:
            pending.append((key, path, digest))
    if pending:
        key = api_key()
        for icon, path, digest in pending:
            kind, name = icon.split("/")
            uploaded[icon] = {"hash": digest, "id": upload(key, path, f"Icon {kind} {name}")}
            print(f"{icon} {uploaded[icon]['id']}")
            with open(UPLOADED, "w") as f:
                json.dump(uploaded, f, indent=2)
    else:
        print("all icons up to date")
    write_config(uploaded)
    print(f"wrote {CONFIG}")


if __name__ == "__main__":
    main()
