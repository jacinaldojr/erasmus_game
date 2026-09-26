"""Generate the interior 16x16 tile atlas (pure stdlib, no Pillow).
Exterior tiles come from the Lakiiah "Cozy RPG Tileset"; this atlas only covers indoor
floors and walls, drawn to match its palette (dark warm outlines, soft fills).
Run: python tools/make_tileset.py  -> assets/tiles/tileset.png
Tile order must match MapBuilder.I in src/world/map_builder.gd."""
import struct, zlib, random, pathlib

TILE = 16
def hexc(h): h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)

def solid(base):
    return [[base] * TILE for _ in range(TILE)]

def wood_floor():
    base = hexc('#c99a6b')
    px = solid(base)
    line, seam, light, grain = hexc('#a97a4f'), hexc('#b98a5c'), hexc('#d6ac7f'), hexc('#c08f60')
    rnd = random.Random(7)
    for x in range(TILE):
        px[7][x] = line; px[15][x] = line
    for y in range(0, 7): px[y][3] = seam
    for y in range(8, 15): px[y][11] = seam
    for _ in range(6):
        x, y = rnd.randrange(TILE), rnd.randrange(TILE)
        if px[y][x] == base: px[y][x] = light
    for y in (2, 4, 10, 12):
        x0 = rnd.randrange(0, 10)
        for x in range(x0, x0 + 4):
            if px[y][x] == base: px[y][x] = grain
    return px

def wall():
    px = solid(hexc('#e9dcc3'))
    top, brick, skirt, skirt_dark = hexc('#c9b89a'), hexc('#dccbb0'), hexc('#8a5a3a'), hexc('#5a3a24')
    for x in range(TILE):
        px[0][x] = top
        for y in range(11, 16): px[y][x] = skirt
        px[11][x] = skirt_dark
    for y in (3, 7):
        for x in range(TILE):
            if (x + (0 if y == 3 else 4)) % 8 == 0: px[y][x] = brick
    return px

def carpet():
    px = solid(hexc('#a84a5a'))
    border, dot = hexc('#7e3244'), hexc('#c46a7a')
    for i in range(TILE):
        px[0][i] = border; px[15][i] = border; px[i][0] = border; px[i][15] = border
    for y in (4, 8, 12):
        for x in (4, 8, 12): px[y][x] = dot
    return px

def mat():
    px = solid(hexc('#c9a86b'))
    stripe = hexc('#a8884d')
    for y in range(TILE):
        if y % 4 == 1:
            for x in range(2, 14): px[y][x] = stripe
    return px

def tiled_floor():
    px = solid(hexc('#d8d2c6'))
    alt, grout = hexc('#c7c0b2'), hexc('#b0a898')
    for y in range(TILE):
        for x in range(TILE):
            if ((x // 8) + (y // 8)) % 2: px[y][x] = alt
            if x % 8 == 0 or y % 8 == 0: px[y][x] = grout
    return px

tiles = [wood_floor(), wall(), carpet(), mat(), tiled_floor()]   # I.WOOD, WALL, CARPET, MAT, TILED

W, H = TILE * len(tiles), TILE
raw = bytearray()
for y in range(H):
    raw.append(0)
    for t in tiles:
        for x in range(TILE):
            raw.extend(t[y][x])

def chunk(tag, data):
    c = struct.pack('>I', len(data)) + tag + data
    return c + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) \
    + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b'')
out = pathlib.Path(__file__).resolve().parent.parent / 'assets' / 'tiles' / 'tileset.png'
out.write_bytes(png)
print('wrote', out, W, 'x', H)
