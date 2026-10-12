class_name ShopKit
extends RefCounted
## Texts and pictures of the shop's cards (GDD 11.1). Reads content and the run; never changes them.


static func picture(x: ShopState.Item) -> Texture2D:
	match x.kind:
		&"module", &"blueprint":
			return WorkshopKit.item_art(x.id)
		&"consumable":
			return UiKit.texture("res://art/ui/CARD__art__%s.webp" % ContentDB.data.card(x.id).art)
	return Icons.texture("RESOURCE", x.id)


static func title(x: ShopState.Item) -> String:
	match x.kind:
		&"module":
			return WorkshopKit.item_name(x.id)
		&"blueprint":
			return Loc.t("ui.shop.blueprint_of", {"name": WorkshopKit.item_name(x.id)})
		&"consumable":
			return ContentDB.data.card(x.id).name
	return "%s ×%d" % [WorkshopKit.stock_name(x.id), x.amount]


static func about(x: ShopState.Item) -> String:
	var data := ContentDB.data
	match x.kind:
		&"module":
			return data.module(x.id).effect_at(GameState.run.loadout.tier(x.id))
		&"blueprint":
			var bp := data.blueprint(x.id)
			var text := Loc.t("ui.shop.blueprint_about")
			if bp.unlock != &"":
				text += " " + Loc.t("ui.shop.blueprint_needs", {"trophy": WorkshopKit.stock_name(bp.unlock)})
			return text
		&"consumable":
			return "%s %s" % [data.card(x.id).text, Loc.t("ui.shop.consumable_about")]
	return Loc.t("ui.shop.lot_about")


## What one trophy or one unit of a resource fetches.
static func sell_price(id: StringName) -> int:
	var data := ContentDB.data
	if data.balance.workshop.resources.has(id):
		return ShopRules.resource_sell_price(data, id)
	return ShopRules.trophy_price(data, id)
