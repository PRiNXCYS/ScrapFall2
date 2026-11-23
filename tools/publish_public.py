"""Copies a finished build (APK + EXE) from the private ScrapFall release to the public
scrapfall2-releases repo, where players download it and the game's update check looks.

    git credential fill ... | python tools/publish_public.py v0.2.0 "What's new text"

Put [required] anywhere in the notes to force every player to update before playing; without it
the game shows an optional notice (UPDATE NOW / LATER). Notes with commas or one item per line
become the "what's new" list on that notice (at most 6 lines).

The GitHub token is read from stdin (the `password=` line of `git credential fill` output works too).
"""
import json
import sys
import urllib.request

PRIVATE = "PRiNXCYS/ScrapFall2"
PUBLIC = "PRiNXCYS/scrapfall2-releases"
FILES = ("SCRAPFALL2.apk", "SCRAPFALL2.exe")


def token_from_stdin() -> str:
    text = sys.stdin.read()
    for line in text.splitlines():
        if line.startswith("password="):
            return line.split("=", 1)[1].strip()
    return text.strip()


def call(method, url, token, body=None, data=None, ctype="application/json", accept="application/vnd.github+json"):
    payload = data if data is not None else (json.dumps(body).encode() if body is not None else None)
    req = urllib.request.Request(url, method=method, data=payload, headers={
        "Authorization": f"Bearer {token}", "Accept": accept, "User-Agent": "scrapfall-publish",
        "Content-Type": ctype})
    with urllib.request.urlopen(req) as r:
        raw = r.read()
        return json.loads(raw) if raw and accept.endswith("json") else raw


def main() -> None:
    tag, notes = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
    token = token_from_stdin()
    rel = call("GET", f"https://api.github.com/repos/{PRIVATE}/releases/tags/{tag}", token)
    blobs = {}
    for a in rel["assets"]:
        if a["name"] in FILES:
            blobs[a["name"]] = call("GET", a["url"], token, accept="application/octet-stream")
            print(f"downloaded {a['name']} ({len(blobs[a['name']]) / 1e6:.1f} MB)")
    missing = [f for f in FILES if f not in blobs]
    if missing:
        sys.exit(f"private release {tag} is missing {missing}; is the build finished?")
    pub = call("POST", f"https://api.github.com/repos/{PUBLIC}/releases", token, body={
        "tag_name": tag, "name": f"SCRAPFALL {tag}", "body": notes or f"SCRAPFALL {tag}",
        "draft": False, "prerelease": False, "make_latest": "true"})
    upload = pub["upload_url"].split("{")[0]
    for name, blob in blobs.items():
        ctype = "application/vnd.android.package-archive" if name.endswith(".apk") else "application/octet-stream"
        stem, ext = name.rsplit(".", 1)
        public_name = f"{stem}-{tag}.{ext}"  # SCRAPFALL-v0.5.1.apk: phones stop piling up "SCRAPFALL (4).apk"
        call("POST", f"{upload}?name={public_name}", token, data=blob, ctype=ctype)
        print(f"uploaded {public_name}")
    print(pub["html_url"])


if __name__ == "__main__":
    main()
