"""Bolum ureticileri icin ortak yardimcilar (gen_bolum2.py, gen_bolum3.py ...).

Bina:  house("Ad", x, y, w, h, kapi, cati_rengi, locked="anahtar_adi")  -> ic harita otomatik
Asker: guard([[x, y], ...], facing, tur, drops="anahtar")              -> tek nokta = nobetci
Engel: ob("bush" | "tree" | "wall" | "sandbag" | "crate" | "tower" ..., rect(...) | circle=[x, y, r])
"""
import json
import math
import os
import random
import subprocess


def rect(x, y, w, h):
    return [[x, y], [x + w, y], [x + w, y + h], [x, y + h]]


class Lvl:
    def __init__(self, name, size, seed):
        self.W, self.H = size
        self.rnd = random.Random(seed)
        self.blocked = []
        self.d = {"name": name, "size": [self.W, self.H], "roads": [], "bridges": [], "buildings": [],
                  "obstacles": [], "surfaces": [], "guards": [], "npcs": [], "objectives": [],
                  "barracks": [], "pickups": [], "sirens": []}

    # ---------------------------------------------------------------- temel
    def block(self, x, y, w, h, pad=30):
        self.blocked.append((x - pad, y - pad, x + w + pad, y + h + pad))

    def road(self, x, y, w, h):
        self.d["roads"].append([x, y, w, h])
        self.block(x, y, w, h, 10)

    def house(self, name, x, y, w, h, door="S", roof=None, locked=None, style=None):
        b = {"name": name, "rect": [x, y, w, h], "door": door}
        if roof:
            b["roof"] = roof
        if locked:
            b["locked"] = locked
        if style:
            b["style"] = style
        self.d["buildings"].append(b)
        self.block(x, y, w, h, 50)
        return b

    def ob(self, kind, pts=None, circle=None, **kw):
        o = {"type": kind}
        if pts:
            o["points"] = pts
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            self.block(min(xs), min(ys), max(xs) - min(xs), max(ys) - min(ys), 20)
        if circle:
            o["circle"] = [round(v) for v in circle]
            self.block(circle[0] - circle[2], circle[1] - circle[2], circle[2] * 2, circle[2] * 2, 10)
        o.update(kw)
        self.d["obstacles"].append(o)
        return o

    def guard(self, path, facing=None, kind=None, drops=None):
        g = {"path": [[round(p[0]), round(p[1])] for p in path]}
        if facing is not None:
            g["facing"] = facing
        if kind:
            g["type"] = kind
        if drops:
            g["drops"] = drops
        self.d["guards"].append(g)
        return g

    def tower(self, x, y, facing):
        """gozetleme kulesi: dekor (gecilir) + ustunde kule nobetcisi (uzagi gorur, yerinden ayrilmaz)"""
        self.ob("tower", rect(x - 22, y - 22, 44, 44))
        self.guard([[x, y + 23]], facing, "kule")

    def bushes(self, pts, r=30):
        for p in pts:
            self.ob("bush", circle=[p[0], p[1], r])

    def bush_line(self, a, b, step=58, r=30):
        n = max(1, int(math.dist(a, b) / step))
        for i in range(n + 1):
            t = i / n
            self.ob("bush", circle=[a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, r])

    def walls_box(self, x0, y0, x1, y1, gaps, th=18, kind="wall"):
        """duvarla cevrili alan; gaps: {"S": [(a, b)], "N": [...], "W": [...], "E": [...]} (kapilar)"""
        def seg_h(y, xa, xb, cuts):
            xs = [xa] + [v for c in sorted(cuts) for v in c] + [xb]
            for i in range(0, len(xs), 2):
                if xs[i + 1] - xs[i] > 4:
                    self.ob(kind, rect(xs[i], y, xs[i + 1] - xs[i], th))

        def seg_v(x, ya, yb, cuts):
            ys = [ya] + [v for c in sorted(cuts) for v in c] + [yb]
            for i in range(0, len(ys), 2):
                if ys[i + 1] - ys[i] > 4:
                    self.ob(kind, rect(x, ys[i], th, ys[i + 1] - ys[i]))
        seg_h(y0, x0, x1, gaps.get("N", []))
        seg_h(y1 - th, x0, x1, gaps.get("S", []))
        seg_v(x0, y0 + th, y1 - th, gaps.get("W", []))
        seg_v(x1 - th, y0 + th, y1 - th, gaps.get("E", []))

    # ---------------------------------------------------------------- su
    def river(self, cx_fn, w_fn, y0, y1, gaps, step=200):
        """kuzey-guney akan nehir; gaps: [(ya, yb)] kopru/gecit bosluklari"""
        cuts = [y0] + [v for g in sorted(gaps) for v in g] + [y1]
        for i in range(0, len(cuts), 2):
            a, b = cuts[i], cuts[i + 1]
            pl, pr = [], []
            y = a
            while True:
                cx, wd = cx_fn(y), w_fn(y)
                pl.append([round(cx - wd / 2), y])
                pr.append([round(cx + wd / 2), y])
                if y >= b:
                    break
                y = min(b, y + step)
            self.ob("water", pr + pl[::-1])
            xs = [cx_fn(yy) for yy in range(int(a), int(b) + 1, 40)]
            self.block(min(xs) - w_fn(a) / 2 - 60, a, max(xs) - min(xs) + w_fn(a) + 120, b - a, 0)

    # ---------------------------------------------------------------- dolgu
    def free(self, x, y, r, gap=0):
        # gap: hareketi engelleyen dolgu (agac/kaya) digerlerine ya cok yakin ya da uzak olmali; sisirilmis
        # (ajan yaricapi 11) cokgenler teget gelirse navigasyonda "merge edge" hatasi cikar
        for (x0, y0, x1, y1) in self.blocked:
            if x0 - r - gap < x < x1 + r + gap and y0 - r - gap < y < y1 + r + gap:
                return False
        for g in self.d["guards"]:
            for p in g["path"]:
                if math.hypot(p[0] - x, p[1] - y) < r + 40:
                    return False
            # devriye hatlarini kapatma
            pts = g["path"]
            for i in range(len(pts) - 1):
                if _seg_dist((x, y), pts[i], pts[i + 1]) < r + 26:
                    return False
        st = self.d.get("start")
        if st and math.hypot(x - st[0], y - st[1]) < 160:
            return False
        return True

    def scatter(self, n, x0, y0, x1, y1, kind, rmin, rmax):
        placed = tries = 0
        while placed < n and tries < n * 50:
            tries += 1
            x, y, r = self.rnd.uniform(x0, x1), self.rnd.uniform(y0, y1), self.rnd.uniform(rmin, rmax)
            if self.free(x, y, r, 30 if kind in ("tree", "rock") else 0):
                self.ob(kind, circle=[x, y, r], _fill=True)
                placed += 1

    def save(self, path, validate=True):
        if validate and os.environ.get("GODOT"):
            self._fix_nav(path)
        for o in self.d["obstacles"]:
            o.pop("_fill", None)
        with open(path, "w") as f:
            json.dump(self.d, f, ensure_ascii=False, indent=1)
        d = self.d
        print("yazildi:", path, len(d["obstacles"]), "engel,", len(d["buildings"]), "bina,", len(d["guards"]), "asker,",
              len(d["barracks"]), "kisla,", len(d["objectives"]), "gorev")


    def _nav_error(self, path):
        tmp = path.replace(".json", "_dogrula.json")
        with open(tmp, "w") as f:
            json.dump(self.d, f, ensure_ascii=False)
        try:
            r = subprocess.run([os.environ["GODOT"], "--headless", "--script", "res://tests/sim_bolum.gd", "--",
                                "--level=res://" + tmp], capture_output=True, text=True, timeout=300)
            return "merge a navigation mesh" in (r.stdout + r.stderr)
        finally:
            os.remove(tmp)

    def _fix_nav(self, path):
        """navigasyonda 'merge edge' hatasina yol acan dolgu agac/calilarini bul ve cikar (ikili arama)"""
        for _ in range(6):
            if not self._nav_error(path):
                return
            obs = self.d["obstacles"]
            cand = [i for i, o in enumerate(obs) if o["type"] in ("tree", "rock") and o.get("_fill")]
            while len(cand) > 1:
                half = set(cand[:len(cand) // 2])
                keep = self.d["obstacles"]
                self.d["obstacles"] = [o for i, o in enumerate(keep) if i not in half]
                bad = self._nav_error(path)
                self.d["obstacles"] = keep
                cand = cand[len(cand) // 2:] if bad else sorted(half)
            if not cand:
                print("UYARI: merge edge hatasi dolgu disinda")
                return
            print("navigasyon hatasi: cikarildi", obs[cand[0]])
            del obs[cand[0]]


def _seg_dist(p, a, b):
    ax, ay = a
    bx, by = b
    px, py = p
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy
    t = 0 if L == 0 else max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / L))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))
