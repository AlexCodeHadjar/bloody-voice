---
name: bv-content
description: Добавление и правка игрового контента Bloody Voice в JSON — карты (cards), твари (monsters), их ходы, части тела и фазы, модули оружия, районы и их состояния, иконки, числа баланса. Используй всякий раз, когда нужно добавить/изменить карту, монстра, эффект, модуль, район, состояние района или любое значение в data/, даже если пользователь не говорит слово «контент».
---

# Контент: данные в `data/`

Новый контент — это данные, а не код. Код трогаешь, только если нужен новый оп-код эффекта или новое поле.

| Что | Файл | Описание полей |
|---|---|---|
| Карты | `data/cards/*.json` (массив) | `core/content/defs/card_def.gd` |
| Твари | `data/monsters/*.json` | `core/content/defs/monster_def.gd` |
| Районы / состояния / регионы карты | `data/city/*.json` | `district_def.gd`, `district_state_def.gd`, `map_regions_def.gd` |
| Модули и фигуры клеток | `data/gear/modules.json`, `shapes.json` | этап 2 (в игру ещё не грузятся) |
| Иконки | `data/ui/icons.json` | набор = одна картинка, `grid` [столбцы, строки] |
| Числа | `data/balance.json` | `balance_def.gd` |

## Эффекты (карты и ходы тварей)

Список оп-кодов и обязательных полей — `core/content/effect_schema.gd`:
`damage{amount, hits?}`, `block`, `heal`, `lose_hp`, `sanity`, `draw`, `gain_ap`, `reload`, `foresight`,
`apply_status{status, stacks, to: target|self}`, `add_card{card, pile?, count?}`, `capture{chance}`.
Статусы: `weak`, `exposed`, `bleed`, `dodge`, `enraged`.

Нужен новый оп-код → добавь его в `EffectSchema.OPS`, ветку в `EffectApplier.apply`, фразу в
`core/content/effect_text.gd` и пример в `tests/test_combat.gd::test_every_effect_op_is_implemented`.

Нужен новый статус → `EffectSchema.STATUSES`; когда он действует — `core/rules/combat/status_rules.gd`
(начало/конец хода, `FADING`), как влияет на урон — `damage_rules.gd`; тест в `tests/test_combat.gd`;
иконка — набор `STATUS` в `data/ui/icons.json`.

## Карта (пример)

```json
{ "id": "shock_harpoon", "name": "Shock Harpoon", "type": "attack", "cost": 2, "ammo": 1,
  "target": "enemy_or_part", "text": "Deal 7 damage. Apply 2 Exposed.",
  "effects": [ {"op": "damage", "amount": 7}, {"op": "apply_status", "status": "exposed", "stacks": 2, "to": "target"} ] }
```
`type`: attack / support / consumable (сама исчезает) / capture / rage / curse. `target`: enemy / enemy_or_part / self / none.

## Тварь — правила

- В колоде (`deck`) хотя бы один ход, который не убирает ни одна часть тела (иначе валидатор не пустит).
- Часть тела `removes` — ходы, которые пропадают после её поломки; `trophy` — добыча.
- `phases[].below` — доля HP (0..1), `add`/`remove` — ходы.
- У ходов нет поля `text`: игра строит текст намерения из эффектов (`effect_text.gd`), он всегда совпадает с числами.
- `look` и `true_form` — описание для арта и бестиария (английский).
- Новую тварь добавь и в `data/monsters`, и проверь баланс (`bv-balance`), и сделай арт (`bv-art`).

## После правки

1. `tools/check_all.sh` — валидатор упадёт с понятной ошибкой «файл/id: что не так».
2. Тварь или карта влияет на бой → `bv-balance`.
3. Дальше — рабочий цикл из CLAUDE.md.
