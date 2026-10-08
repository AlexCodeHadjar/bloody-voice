# Bloody Voice — Game Design Document

A story-driven monster-hunting game with roguelike elements: deck-building combat, investigation,
crafting, a living city. Engine: Godot 4.7 · GDScript. This folder **is** the design document:
edit these Markdown files directly (one file per section, so only the needed part is read).

| If you need… | Go to |
|---|---|
| The idea of the game in 2 minutes | [1. Vision](01-vision.md) |
| Rules of a system (combat, gear, investigation…) | sections 3–12 |
| The city: layout, districts, layers | [13. The City](13-the-city-of-hallowdeep.md) |
| How districts change after events | [14](14-the-living-city-district-states.md), [15](15-world-events.md) |
| Prompts for the city art | [16](16-art-direction-and-generation-prompts.md); modules, creatures, icons — [../art-prompts](../art-prompts/README.md) |
| The close-up district map (Grey Chapels), combat screen v2, tutorial hints and Russian | [20](20-district-view-grey-chapels.md), [21](21-combat-screen-layout.md), [22](22-tutorial-hints-and-localization.md); workshop and skill web screens — [23](23-workshop-and-skill-web-screens.md) |
| What to build and in which order | [18. Roadmap](18-development-roadmap.md) |
| How the code must be structured | [19. Architecture](19-technical-architecture-godot-4-7-gdscript.md) |

City sketch files (`docs/assets/map/`): `city_sketch.png`, `city_cross_section.png`, `city_grid.txt` —
regenerate with `python tools/gen_city_sketch.py`.

## Sections

- [1. Vision](01-vision.md)
- [2. Story Structure](02-story-structure.md)
- [3. Core Loops and Time](03-core-loops-and-time.md)
- [4. The Hunter](04-the-hunter.md)
- [5. Equipment, Weapons and the Deck](05-equipment-weapons-and-the-deck.md)
- [6. Workshop and Crafting](06-workshop-and-crafting.md)
- [7. Tavern and Contracts](07-tavern-and-contracts.md)
- [8. Investigation](08-investigation.md)
- [9. Combat](09-combat.md)
- [10. Capture and Research](10-capture-and-research.md)
- [11. Economy](11-economy.md)
- [12. Factions and Reputation](12-factions-and-reputation.md)
- [13. The City of Hallowdeep](13-the-city-of-hallowdeep.md)
- [14. The Living City: District States](14-the-living-city-district-states.md)
- [15. World Events](15-world-events.md)
- [16. Art Direction and Generation Prompts](16-art-direction-and-generation-prompts.md)
- [17. Procedural Generation](17-procedural-generation.md)
- [18. Development Roadmap](18-development-roadmap.md)
- [19. Technical Architecture (Godot 4.7, GDScript)](19-technical-architecture-godot-4-7-gdscript.md)
- [20. District View — the Grey Chapels](20-district-view-grey-chapels.md)
- [21. Combat Screen v2](21-combat-screen-layout.md)
- [22. Tutorial Hints and Localization](22-tutorial-hints-and-localization.md)
- [23. Workshop and Skill Web Screens](23-workshop-and-skill-web-screens.md)
- [Appendix A. Names and Inspiration Mapping](appendix-a-names-and-inspiration-mapping.md)
- [Appendix B. MVP Monster Roster](appendix-b-mvp-monster-roster.md)
- [Appendix C. Starter Deck and Example Cards](appendix-c-starter-deck-and-example-cards.md)
- [Appendix D. Glossary](appendix-d-glossary.md)
