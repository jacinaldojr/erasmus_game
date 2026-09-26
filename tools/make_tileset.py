"""Generate the placeholder 16x16 tile atlas (pure stdlib, no Pillow).
Run: python tools/make_tileset.py  -> assets/tiles/tileset.png
Tile order must match MapBuilder.T in src/world/map_builder.gd."""
import struct, zlib, random, pathlib

TILE = 16
def hexc(h): h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)

def solid(base, speck=None, n=6, seed=1):
    px = [[base] * TILE for _ in range(TILE)]
    if speck:
        rnd = random.Random(seed)
        for _ in range(n):
            x, y = rnd.randrange(TILE), rnd.randrange(TILE)
            px[y][x] = speck
    return px

def floor_tile():
    px = solid(hexc('#d8c9a3'))
    for i in range(TILE):
        px[0][i] = hexc('#c4b58f'); px[i][0] = hexc('#c4b58f')
    return px

def wall_tile():
    px = solid(hexc('#4a4a5a'))
    for i in range(TILE):
        for y in range(4): px[y][i] = hexc('#6a6a7a')
        px[8][i] = hexc('#3a3a48')
    for y in range(4, 8): px[y][7] = hexc('#3a3a48')
    for y in range(9, 16): px[y][3] = hexc('#3a3a48'); px[y][11] = hexc('#3a3a48')
    return px

def water_tile():
    px = solid(hexc('#3f7fbf'))
    for x in range(2, 8): px[4][x] = hexc('#6aa5dd')
    for x in range(8, 14): px[11][x] = hexc('#6aa5dd')
    return px

def tree_tile():
    px = solid(hexc('#5da84a'))
    for y in range(TILE):
        for x in range(TILE):
            if (x - 7.5) ** 2 + (y - 6) ** 2 < 42: px[y][x] = hexc('#2f6b32')
            if (x - 6) ** 2 + (y - 5) ** 2 < 8: px[y][x] = hexc('#3f8a42')
    for y in range(11, 16):
        for x in range(6, 10): px[y][x] = hexc('#5a3a1e')
    return px

def mat_tile():
    px = solid(hexc('#c9b27c'))
    for y in range(3, 13):
        for x in range(2, 14): px[y][x] = hexc('#b0603c')
    for x in range(4, 12): px[7][x] = hexc('#d98a5c'); px[8][x] = hexc('#d98a5c')
    return px

tiles = [
    solid(hexc('#5da84a'), hexc('#6fbf5a'), 8, 1),   # 0 GRASS
    floor_tile(),                                    # 1 FLOOR
    wall_tile(),                                     # 2 WALL
    solid(hexc('#c9b27c'), hexc('#b39c66'), 5, 2),   # 3 PATH
    solid(hexc('#7a5230'), hexc('#5e3d22'), 10, 3),  # 4 SOIL
    water_tile(),                                    # 5 WATER
    tree_tile(),                                     # 6 TREE
    mat_tile(),                                      # 7 MAT (door)
    solid(hexc('#a03c5a'), hexc('#b8506e'), 6, 4),   # 8 CARPET
]

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
