extends PanelContainer

@onready var rabbit_button : BaseButton = $%RabbitButton

func _ready() -> void:
	FusekiSignals.fuseki_data_updated.connect(_on_fuseki_updated)

func _on_fuseki_updated() -> void:
	rabbit_button.disabled = false
