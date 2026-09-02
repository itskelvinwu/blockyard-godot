extends Control
## Codigames-style HUD. Cash, energy, builders, gems, build / upgrade sheets.

var _panel := "none"
@onready var cash_lbl: Label = $Top/Cash
@onready var energy_lbl: Label = $Top/Energy
@onready var build_lbl: Label = $Top/Builders
@onready var gem_lbl: Label = $Top/Gems
@onready var clock_lbl: Label = $Clock
@onready var sheet: Control = $Sheet
@onready var sheet_title: Label = $Sheet/Panel/Title
@onready var sheet_body: VBoxContainer = $Sheet/Panel/Body


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Top.mouse_filter = Control.MOUSE_FILTER_STOP
	$Dock.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.visible = false
	Session.changed.connect(_redraw)
	_redraw()


func _process(_dt: float) -> void:
	var m := int(Session.clock_min) % (24 * 60)
	var h24 := int(m / 60.0)
	var mm := m % 60
	var am := h24 < 12
	var h := h24 % 12
	if h == 0:
		h = 12
	clock_lbl.text = "%d:%02d %s" % [h, mm, "AM" if am else "PM"]
	cash_lbl.text = "$%s" % _money(Session.cash)
	energy_lbl.text = "%d/%d" % [int(Session.energy), Session.ENERGY_MAX]
	build_lbl.text = "%d/%d" % [Session.builders_free(), Session.BUILDERS_MAX]
	gem_lbl.text = str(Session.gems)


func _money(n: int) -> String:
	if n >= 1000000:
		return "%.2fM" % (n / 1000000.0)
	return str(n)


func _redraw() -> void:
	pass


func _on_build() -> void:
	_open("build")


func _on_upgrade() -> void:
	_open("upgrade")


func _on_staff() -> void:
	_open("staff")


func _on_close() -> void:
	_panel = "none"
	sheet.visible = false
	Session.panel = "none"


func _open(which: String) -> void:
	_panel = which
	Session.panel = which
	sheet.visible = true
	for c in sheet_body.get_children():
		c.queue_free()
	match which:
		"build":
			sheet_title.text = "BUILD"
			for r in MapData.rooms():
				if r["start"]:
					continue
				var b := Button.new()
				b.text = "%s  $%d" % [r["name"], r["cost"]]
				b.pressed.connect(_build_room.bind(str(r["id"]), str(r["name"]), int(r["cost"])))
				sheet_body.add_child(b)
			var lot := Button.new()
			lot.text = "Parking lot  $%d" % Session.lot_next_cost()
			lot.pressed.connect(_build_room.bind("lot", "Parking lot", Session.lot_next_cost()))
			sheet_body.add_child(lot)
		"upgrade":
			sheet_title.text = "UPGRADE"
			for k in Session.UPGRADE_KINDS:
				var cost := Session.next_cost(k)
				var t: int = int(Session.upgrades.get(k, 1))
				var b := Button.new()
				var can := t < 10 and Session.cash >= cost
				b.text = ("%s  L%d%s") % [k.capitalize(), t, "  ▲" if can else ""]
				b.pressed.connect(func(): Session.bump(k))
				sheet_body.add_child(b)
		"staff":
			sheet_title.text = "STAFF"
			for row in ["Chef x2", "Server x2", "Busser x1", "Janitor x1", "Manager x1"]:
				var l := Label.new()
				l.text = row
				l.add_theme_color_override("font_color", Color("3a2e22"))
				sheet_body.add_child(l)


func _build_room(id: String, nam: String, cost: int) -> void:
	var res := Session.start_build(id, nam, cost)
	if res != "ok":
		sheet_title.text = res.to_upper()
