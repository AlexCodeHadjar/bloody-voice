"""Grey Chapels layout for tools/gen_district_sketch.py (GDD 20): contour, zones, landmarks, street graph.
All coordinates are C space (see gen_district_sketch.py).
"""
from __future__ import annotations

# The district's border as drawn on the city map (traced along the black outline).
CONTOUR = [(150, 398), (200, 300), (290, 215), (400, 188), (500, 200), (590, 250), (665, 320), (700, 350),
           (745, 450), (778, 580), (795, 720), (797, 860), (785, 990), (700, 1000), (600, 1005), (490, 1020),
           (400, 1000), (350, 985), (300, 890), (285, 820), (260, 700), (200, 600), (150, 520), (140, 450)]

NEIGHBOURS = [  # locked at the start: shown darkened with a label
    ("NORDHAL", "Nordhal Quarter", "Нордхал", (250, 140)),
    ("LUMEN", "Lumen Campus", "Кампус Люмен", (180, 700)),
    ("MARKET", "Rowan Market", "Рынок Роуэн", (200, 930)),
    ("DEEPWRIGHT", "Deepwright Lifts", "Подъёмники Дипрайт", (300, 1060)),
    ("SCARLET", "Scarlet Lantern Row", "Алые Фонари", (620, 1055)),
]

ZONE_LABELS = {"ash_quarter": (260, 280), "shanty_roofs": (640, 410), "chapel_close": (690, 470),
               "fog_hollow": (360, 720), "lower_yards": (620, 860)}
ZONES = [  # id, English, Russian, polygon (C space), tint
    ("ash_quarter", "Ash Quarter", "Пепельный квартал",
     [(170, 400), (230, 290), (330, 225), (470, 260), (540, 330), (545, 450), (420, 500), (280, 520), (175, 480)], (196, 160, 110)),
    ("shanty_roofs", "Shanty Roofs", "Хибары на крышах",
     [(500, 215), (590, 255), (690, 345), (725, 440), (600, 450), (550, 400), (530, 300)], (150, 130, 110)),
    ("chapel_close", "Chapel Close", "Часовенный двор",
     [(560, 440), (722, 450), (745, 600), (738, 700), (600, 715), (530, 640), (540, 500)], (140, 140, 160)),
    ("fog_hollow", "Fog Hollow", "Туманный лог",
     [(270, 560), (420, 520), (530, 620), (580, 720), (440, 760), (300, 760), (265, 680)], (170, 175, 180)),
    ("lower_yards", "Lower Yards", "Нижние дворы",
     [(300, 790), (440, 770), (600, 745), (765, 790), (760, 985), (600, 1000), (420, 995), (330, 930)], (150, 120, 100)),
    ("edge_walk", "Edge Walk", "Дорожка над Бездной",
     [(725, 440), (745, 450), (778, 580), (795, 720), (797, 860), (785, 990), (760, 985), (768, 860), (766, 720),
      (748, 590), (722, 470)], (120, 135, 150)),
]

# id, English, Russian, role in the game, C position, footprint (w, h) in C px, kind
LANDMARKS = [
    ("old_grey_chapel", "The Old Grey Chapel", "Старая Серая Часовня",
     "story hub of the Grey Communion; heart of the district", (610, 520), (110, 140), "chapel"),
    ("silent_belfry", "The Silent Belfry", "Безмолвная колокольня",
     "tall spire on the Nordhal border; lookout, rumors", (465, 215), (34, 34), "tower"),
    ("north_gate", "North Gate", "Северные ворота",
     "exit to Nordhal (locked at the start)", (385, 222), (40, 20), "gate"),
    ("ash_market", "Ash Market", "Пепельный рынок",
     "stalls round bonfires; daily trade", (455, 330), (70, 50), "market"),
    ("rag_and_bone", "Rag-and-Bone Shop", "Лавка старьёвщика",
     "SHOP: weapons, modules, consumables", (360, 320), (40, 30), "shop"),
    ("lantern_and_hook", "The Lantern & Hook", "Таверна «Фонарь и Крюк»",
     "TAVERN: contract board, tavern shifts, gossip", (320, 410), (55, 40), "tavern"),
    ("ash_garret", "Ash Garret", "Пепельный чердак",
     "HOME: the hunter's rented room; rest, rent, stash", (240, 470), (36, 30), "home"),
    ("rusty_cog", "The Rusty Cog", "Мастерская «Ржавая Шестерня»",
     "WORKSHOP: craft and fit modules", (420, 425), (48, 34), "workshop"),
    ("bonfire_square", "Bonfire Square", "Костровая площадь",
     "leaflet post: rumors are pinned here", (495, 470), (50, 40), "square"),
    ("candle_bridge", "Candle Bridge", "Мост Свечей",
     "arched bridge over the fog, lit by votive candles", (385, 560), (120, 26), "bridge"),
    ("fog_cellars", "The Fog Cellars", "Туманные подвалы",
     "flooded cellars full of grey fog; night hunts", (470, 655), (60, 36), "cellar"),
    ("crypt_scriptorium", "Crypt Scriptorium", "Склеп-скрипторий",
     "LIBRARY: old books in a crypt under the chapel", (650, 660), (40, 30), "crypt"),
    ("god_in_the_wall", "The God in the Wall", "Бог в стене",
     "shrine carved into the Ringwall; whispered prayers", (752, 600), (26, 46), "shrine"),
    ("edge_walk", "Edge Walk", "Дорожка над Бездной",
     "railing path along the platform edge", (775, 760), (20, 60), "walk"),
    ("old_aqueduct", "The Old Aqueduct", "Старый акведук",
     "viaduct with a walkway on top across the district", (610, 735), (180, 22), "aqueduct"),
    ("ash_sisters", "Ash Sisters' Infirmary", "Лазарет Пепельных сестёр",
     "heal HP and Sanity for money", (335, 800), (46, 34), "infirmary"),
    ("nameless_yard", "The Nameless Yard", "Безымянное кладбище",
     "paupers' graves; ichor, ghouls", (480, 880), (80, 54), "graveyard"),
    ("broken_hoist", "The Broken Hoist", "Сломанный подъёмник",
     "sealed hoist down to the slums below (Chapter II)", (745, 950), (40, 40), "hoist"),
    ("south_passage", "South Passage", "Южный проход",
     "exit to Deepwright Lifts (locked at the start)", (430, 992), (40, 20), "gate"),
    ("west_crossing", "West Crossing", "Западный переезд",
     "rail crossing to Lumen / Rowan Market (locked)", (205, 610), (36, 22), "gate"),
    ("tram_depot", "The Tram Depot", "Трамвайное депо",
     "end of the tram line: sheds, tracks, a turntable; later the way to other districts", (372, 928), (78, 50), "depot"),
]

NODES = {  # street graph (C space)
    "north_gate": (385, 235), "belfry": (462, 240), "market": (455, 340), "shop": (365, 340),
    "tavern": (330, 432), "home": (255, 488), "workshop": (420, 445), "square": (495, 480),
    "roofs": (610, 360), "edge_n": (716, 446), "chapel": (560, 600), "bridge_w": (325, 562),
    "bridge_e": (445, 566), "west_crossing": (226, 628), "hollow": (470, 680), "scriptorium": (650, 690),
    "god_wall": (735, 610), "aqueduct_w": (520, 735), "edge_s": (775, 800), "infirmary": (340, 822),
    "yard": (480, 910), "south_passage": (430, 978), "hoist": (735, 935), "depot": (420, 922),
}
STREETS = [  # name, Russian, nodes in order, width class (3 main, 2 street, 1 alley, 0 rope bridge)
    ("Ash Street", "Пепельная улица", ["north_gate", "market", "square", "chapel"], 3),
    ("Hook Lane", "Крюков переулок", ["market", "shop", "tavern", "home"], 2),
    ("Tinker's Row", "Жестянщицкий ряд", ["tavern", "workshop", "square"], 2),
    ("Belfry Steps", "Ступени колокольни", ["north_gate", "belfry", "market"], 1),
    ("Rope Bridges", "Верёвочные мосты", ["square", "roofs", "edge_n"], 0),
    ("Bridge Lane", "Мостовой переулок", ["home", "bridge_w", "bridge_e", "square"], 2),
    ("Rail Track Lane", "Путейский проулок", ["home", "west_crossing"], 1),
    ("Hollow Stair", "Лестница в лог", ["bridge_e", "hollow", "aqueduct_w"], 1),
    ("Cloister Path", "Монастырская тропа", ["chapel", "scriptorium", "god_wall"], 2),
    ("Railing Path", "Тропа у перил", ["edge_n", "god_wall", "edge_s", "hoist"], 1),
    ("Aqueduct Walk", "Тропа по акведуку", ["aqueduct_w", "edge_s"], 1),
    ("Gutter Road", "Сточная дорога", ["hollow", "infirmary", "yard", "south_passage"], 2),
    ("Grave Path", "Кладбищенская тропа", ["yard", "hoist"], 1),
    ("Depot Lane", "Деповской проулок", ["yard", "depot"], 1),
]
HOME_NODE = "home"
LANDMARK_NODE = {  # where the hero stands to use a landmark
    "old_grey_chapel": "chapel", "silent_belfry": "belfry", "north_gate": "north_gate", "ash_market": "market",
    "rag_and_bone": "shop", "lantern_and_hook": "tavern", "ash_garret": "home", "rusty_cog": "workshop",
    "bonfire_square": "square", "candle_bridge": "bridge_e", "fog_cellars": "hollow",
    "crypt_scriptorium": "scriptorium", "god_in_the_wall": "god_wall", "edge_walk": "edge_s",
    "old_aqueduct": "aqueduct_w", "ash_sisters": "infirmary", "nameless_yard": "yard", "broken_hoist": "hoist",
    "south_passage": "south_passage", "west_crossing": "west_crossing", "tram_depot": "depot",
}

# What forms each stretch of the border (CONTOUR indices, inclusive). There is NO wall between districts:
# the edge is a street, the tram line or a viaduct; the game darkens what lies beyond.
BORDER = [
    (0, 7, "street", "Пограничная улица (к Нордхалу)", "boundary street towards Nordhal"),
    (7, 12, "ringwall", "Кольцевая стена — край платформы", "the Ringwall, edge of the platform"),
    (12, 17, "viaduct", "Кирпичный виадук с дорогой, без рельсов (к югу)", "brick road viaduct along the south, no rails"),
    (17, 18, "street", "Улица у депо", "street past the depot"),
    (18, 24, "rail", "Трамвайная насыпь (к западу), кончается в депо", "tram embankment along the west, ends in the depot"),
    # 24 = back to 0. The tram line ENDS in the Tram Depot (landmark 21); no rails continue onto the viaduct.
]
# The sunken gully of the Fog Hollow (two storeys below the streets); the Candle Bridge spans it.
GULLY = [(348, 505), (352, 600), (382, 662), (468, 708), (560, 748), (578, 716), (492, 664), (418, 618),
         (412, 505)]
BRIDGE = ("bridge_w", "bridge_e")               # Candle Bridge: stone deck at street level over the gully
AQUEDUCT = ((505, 722), (790, 802))             # raised brick viaduct, walkway on top, houses under the arches
BONFIRES = [(440, 318), (470, 318), (455, 345), (495, 470)]
