extends Container

@onready var legends_panel = $PanelContainer
@onready var legends_container = $PanelContainer/LegendsContainer

const LegendElement = preload("res://Legends/LegendElement.tscn")

var timescales : Dictionary

func _ready() -> void:
	set_panel_color(StyleConfig.Legends.PANEL_COLOR)

func set_panel_color(color : Color):
	var panelStylebox : StyleBoxFlat = legends_panel.get_theme_stylebox("panel").duplicate()
	panelStylebox.bg_color = color
	panelStylebox.border_color
	legends_panel.add_theme_stylebox_override("panel", panelStylebox)

func build_legends(legends : Dictionary):
	for categoryKey : String in legends.keys():
		add_legend_indicator(categoryKey)
		for legend in legends[categoryKey].keys():
			instanciate_legend_element(legend, legends[categoryKey][legend])

func add_legend_indicator(legend : String):
	var new_label : Label = Label.new()
	new_label.text = legend
	new_label.add_theme_color_override("font_color", StyleConfig.Legends.CATEGORY_ANNONCE_COLOR)
	legends_container.add_child(new_label)

func instanciate_legend_element(text : String, color : Color):
	var new_legend_element : LegendElement = LegendElement.instantiate()
	new_legend_element.set_text(text)
	new_legend_element.set_color(color)
	legends_container.add_child(new_legend_element)

#Hiding function ---------------------------------------------------------------------------------
var legends_hidden : bool  = false


func _on_node_style_option_item_selected(index: int) -> void:
	for child in legends_container.get_children():
		child.queue_free()
	match index:
		1:
			var deployment_map = StyleConfig.Deployment.MAP
			for key in deployment_map.keys():
				instanciate_legend_element(key, deployment_map[key])
		2:
			var implementation_map = StyleConfig.Implementation.MAP
			for key in implementation_map.keys():
				instanciate_legend_element(key, implementation_map[key])
		3:
			for timescale in timescales.keys():
				instanciate_legend_element(timescale, timescales[timescale])
