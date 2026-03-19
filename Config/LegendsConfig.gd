extends Node

const LEGENDS : Dictionary = {
	"Realtime Relationships" : RT_LEGENDS,
	"Component Evolution" : BG_LEGENDS
}

const RT_LEGENDS : Dictionary = {
	"Slower than realtime" : StyleConfig.Timescale.SLOWER_THAN_REALTIME,
	"Realtime" : StyleConfig.Timescale.REALTIME,
	"Faster than realtime" : StyleConfig.Timescale.FASTER_THAN_REALTIME,
}

const BG_LEGENDS : Dictionary = {
	"Implemented": StyleConfig.DTElement.DIMMED_COLOR,
	"Planned": StyleConfig.DTElement.PLANNED_COLOR
}
