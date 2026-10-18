"""Rebuild Profile Desk's original, local-only geometric Lottie illustrations."""
import json
from pathlib import Path

OUT = Path(__file__).parent
COLORS = {
    'forest': '#21675E', 'deep': '#184E48', 'cream': '#F4F1E7',
    'sage': '#BBD0BF', 'lilac': '#D2C8E4', 'ink': '#29473F',
    'white': '#FFFDF7', 'mist': '#E6EBE0', 'muted': '#6D8B7F',
}


def color(name):
    value = COLORS.get(name, name).lstrip('#')
    return [int(value[i:i + 2], 16) / 255 for i in (0, 2, 4)] + [1]


def prop(value):
    return {'a': 0, 'k': value}


def keys(values):
    return {'a': 1, 'k': [
        {'t': t, 's': value if isinstance(value, list) else [value],
         **({'i': {'x': [.18], 'y': [1]},
             'o': {'x': [.22], 'y': [0]}} if i < len(values) - 1 else {})}
        for i, (t, value) in enumerate(values)
    ]}


def fill(name):
    return {'ty': 'fl', 'c': prop(color(name)), 'o': prop(100), 'r': 1}


def stroke(name, width=2):
    return {'ty': 'st', 'c': prop(color(name)), 'o': prop(100),
            'w': prop(width), 'lc': 2, 'lj': 2}


def rect(x, y, w, h, radius, name):
    return {'ty': 'gr', 'it': [
        {'ty': 'rc', 'p': prop([x, y]), 's': prop([w, h]), 'r': prop(radius)},
        fill(name),
    ]}


def ellipse(x, y, w, h, name):
    return {'ty': 'gr', 'it': [
        {'ty': 'el', 'p': prop([x, y]), 's': prop([w, h])}, fill(name),
    ]}


def path(points, closed=False, curves=None):
    n = len(points)
    incoming, outgoing = curves or ([[0, 0]] * n, [[0, 0]] * n)
    return {'ty': 'sh', 'ks': prop({'c': closed, 'i': incoming,
                                    'o': outgoing, 'v': points})}


def line(points, name, width=2):
    return {'ty': 'gr', 'it': [path(points), stroke(name, width)]}


def layer(name, shapes, position=(180, 160), rotation=0, scale=(100, 100, 100),
          opacity=100, frames=48):
    def animated_or_static(value):
        return value if isinstance(value, dict) else prop(value)
    return {'ddd': 0, 'ind': 0, 'ty': 4, 'nm': name, 'sr': 1,
            'ks': {'o': animated_or_static(opacity),
                   'r': animated_or_static(rotation),
                   'p': animated_or_static(list(position) if not isinstance(position, dict) else position),
                   'a': prop([0, 0, 0]), 's': animated_or_static(list(scale) if not isinstance(scale, dict) else scale)},
            'ao': 0, 'shapes': list(reversed(shapes)), 'ip': 0, 'op': frames, 'st': 0, 'bm': 0}


def write(name, layers, frames=48):
    for index, item in enumerate(layers, 1):
        item['ind'] = index
        item['op'] = frames
    doc = {'v': '5.12.2', 'fr': 30, 'ip': 0, 'op': frames,
           'w': 360, 'h': 320, 'nm': f'Profile Desk · {name}', 'ddd': 0,
           'assets': [], 'layers': layers, 'markers': []}
    (OUT / f'{name}.json').write_text(json.dumps(doc, separators=(',', ':')) + '\n')


def tile(name, base, foreground, position, rotation, start, large=False):
    w, h = (108, 140) if large else (92, 122)
    shapes = [
        rect(0, 0, w, h, 19, base),
        ellipse(0, -30, 34, 34, foreground),
        ellipse(0, -33, 10, 10, base),
        {'ty': 'gr', 'it': [path([[-10, -20], [0, -25], [10, -20]], False,
          ([[0, 0], [-5, 0], [0, 0]], [[0, 0], [5, 0], [0, 0]])), stroke(base, 3)]},
        rect(0, 6, 46, 5, 2.5, foreground),
        rect(0, 19, 31, 4, 2, foreground),
        line([[-w / 2 + 18, h / 2 - 24], [w / 2 - 18, h / 2 - 24]], foreground, 1.5),
    ]
    x, y = position
    return layer(name, shapes,
        position=keys([(0, [180, 200, 0]), (start, [180, 200, 0]), (start + 23, [x, y, 0]), (47, [x, y, 0])]),
        rotation=keys([(0, 0), (start, 0), (start + 23, rotation), (47, rotation)]),
        opacity=keys([(0, 0), (start, 0), (start + 9, 100), (47, 100)]))


write('accounts', [
    tile('Personal tile', 'forest', 'cream', (180, 151), 0, 4, True),
    tile('Studio tile', 'lilac', 'ink', (266, 169), 12, 8),
    tile('Community tile', 'sage', 'ink', (94, 169), -12, 0),
    layer('Top detail', [line([[0, -5], [0, 5]], 'muted'), line([[-5, 0], [5, 0]], 'muted')],
          position=(285, 74), scale=keys([(0, [0, 0, 100]), (20, [0, 0, 100]), (32, [100, 100, 100]), (47, [100, 100, 100])])),
    layer('Side detail', [ellipse(0, 0, 6, 6, 'muted')], position=(57, 106)),
    layer('Desk shadow', [ellipse(0, 0, 232, 19, 'mist')], position=(180, 249),
          opacity=keys([(0, 0), (22, 100), (47, 100)])),
])

# A workspace unfolds once, then remains a quiet illustration; it is not a
# percentage, connectivity indicator, or service-state animation.
write('opening', [
    layer('Workspace center', [rect(0, 0, 220, 158, 23, 'cream'),
                              line([[-110, -38], [110, -38]], 'sage', 1.5)],
          position=keys([(0, [180, 180, 0]), (20, [180, 156, 0]), (43, [180, 156, 0])]),
          scale=keys([(0, [90, 90, 100]), (20, [100, 100, 100]), (43, [100, 100, 100])]),
          opacity=keys([(0, 0), (10, 100), (43, 100)]), frames=44),
], 44)
# Prepend detail layers so they paint above the workspace background.
opening = json.loads((OUT / 'opening.json').read_text())['layers']
opening = [
    layer('Workspace glyph', [rect(0, 0, 72, 72, 17, 'forest'),
                              rect(-11, -11, 12, 12, 3, 'cream'),
                              rect(11, -11, 12, 12, 3, 'cream'),
                              rect(-11, 11, 12, 12, 3, 'cream'),
                              rect(11, 11, 12, 12, 3, 'sage')],
          position=keys([(0, [180, 205, 0]), (9, [180, 205, 0]), (30, [180, 174, 0]), (43, [180, 174, 0])]),
          rotation=keys([(0, -10), (9, -10), (30, 0), (43, 0)]),
          opacity=keys([(0, 0), (9, 0), (19, 100), (43, 100)])),
    layer('Window controls', [ellipse(-76, 0, 7, 7, 'forest'),
                              ellipse(-61, 0, 7, 7, 'sage'),
                              ellipse(-46, 0, 7, 7, 'lilac'),
                              rect(65, 0, 29, 4, 2, 'sage')],
          position=keys([(0, [180, 120, 0]), (20, [180, 96, 0]), (43, [180, 96, 0])]),
          opacity=keys([(0, 0), (8, 0), (17, 100), (43, 100)])),
    *opening,
    layer('Small side tile', [rect(0, 0, 40, 52, 12, 'lilac')],
          position=keys([(0, [265, 200, 0]), (11, [265, 200, 0]), (30, [291, 199, 0]), (43, [291, 199, 0])]),
          rotation=12, opacity=keys([(0, 0), (11, 0), (20, 100), (43, 100)])),
    layer('Small side tile', [rect(0, 0, 40, 52, 12, 'sage')],
          position=keys([(0, [100, 160, 0]), (4, [100, 160, 0]), (28, [67, 159, 0]), (43, [67, 159, 0])]),
          rotation=-12, opacity=keys([(0, 0), (4, 0), (15, 100), (43, 100)])),
    layer('Desk shadow', [ellipse(0, 0, 218, 16, 'mist')], position=(180, 250),
          opacity=keys([(0, 0), (22, 100), (43, 100)])),
]
write('opening', opening, 44)

shield_points = [[0, -74], [65, -48], [61, 17], [0, 78], [-61, 17], [-65, -48]]
shield_in = [[-20, 9], [0, 0], [4, -23], [26, -14], [9, 32], [0, 0]]
shield_out = [[20, 9], [0, 0], [-9, 32], [-26, -14], [-4, -23], [0, 0]]
shield_shape = path(shield_points, True, (shield_in, shield_out))
write('privacy', [
    layer('Secure check', [{'ty': 'gr', 'it': [
        path([[-23, 0], [-6, 17], [27, -17]]), stroke('cream', 7),
        {'ty': 'tm', 's': prop(0), 'e': keys([(0, 0), (21, 0), (36, 100), (47, 100)]), 'o': prop(0), 'm': 1},
    ]}], position=(180, 153)),
    layer('Forest shield', [{'ty': 'gr', 'it': [shield_shape, fill('forest')]}],
          position=keys([(0, [180, 178, 0]), (23, [180, 153, 0]), (47, [180, 153, 0])]),
          scale=keys([(0, [88, 88, 100]), (23, [100, 100, 100]), (47, [100, 100, 100])]),
          opacity=keys([(0, 0), (12, 100), (47, 100)])),
    layer('Lilac privacy layer', [{'ty': 'gr', 'it': [shield_shape, fill('lilac')]}],
          position=(201, 159), rotation=10,
          scale=keys([(0, [84, 84, 100]), (28, [100, 100, 100]), (47, [100, 100, 100])]),
          opacity=keys([(0, 0), (7, 0), (20, 100), (47, 100)])),
    layer('Sage privacy layer', [{'ty': 'gr', 'it': [shield_shape, fill('sage')]}],
          position=(158, 159), rotation=-10,
          scale=keys([(0, [84, 84, 100]), (28, [100, 100, 100]), (47, [100, 100, 100])]),
          opacity=keys([(0, 0), (3, 0), (18, 100), (47, 100)])),
    layer('Top detail', [line([[0, -5], [0, 5]], 'muted'), line([[-5, 0], [5, 0]], 'muted')], position=(285, 103)),
    layer('Side detail', [ellipse(0, 0, 6, 6, 'muted')], position=(70, 190)),
    layer('Desk shadow', [ellipse(0, 0, 182, 16, 'mist')], position=(180, 257),
          opacity=keys([(0, 0), (22, 100), (47, 100)])),
])
