extends Node

# Deployment relationship style
class Deployment:
	const ON_DEVICE : Color = Color(0.2, 0.6, 0.2)
	const EDGE : Color = Color(0.2, 0.4, 0.8)
	const FOG : Color = Color.LIGHT_STEEL_BLUE
	const CLOUD : Color = Color.AQUA
	
	const MAP : Dictionary = {
		"ON_DEVICE": ON_DEVICE,
		"EDGE": EDGE,
		"FOG": FOG,
		"CLOUD": CLOUD
	}

# Implementation relationship style
class Implementation:
	const PLANNED : Color = Color.YELLOW
	const ACTIVE : Color = Color.ORANGE
	const IMPLEMENTED : Color = Color.GREEN
	
	const MAP : Dictionary = {
		"PLANNED": PLANNED,
		"ACTIVE": ACTIVE,
		"IMPLEMENTED": IMPLEMENTED
	}

#DT/RT displayed element style
class DTElement:
	const BORDER_WIDTH : int = 5
	const BORDER_COLOR : Color = Color("454545")
	
	const DIMMED_COLOR : Color = Color.GRAY
	const HIGHLIGHT_COLOR : Color = Color.DIM_GRAY
	const TEXT_HIGHLIGHT_COLOR : Color = Color.WHITE_SMOKE
	const PLANNED_COLOR : Color = Color(Color.WHITE, 0.6)

#Visual link style
class Link:
	const WIDTH : int = 5
	
	const MEAN_OUTER_LINK_DISTANCE : int = 15 * WIDTH
	
	const DIMMED_COLOR : Color = Color.GRAY
	const HIGHLIGHT_COLOR : Color = Color.DIM_GRAY

#Legends style
class Legends:
	const PANEL_COLOR : Color = Color.DARK_GRAY
	const CATEGORY_ANNONCE_COLOR : Color = Color(0.3, 0.3, 0.3)
