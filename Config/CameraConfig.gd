extends Node

#Movement config
class Movement:
	const MAX_VELOCITY : float = 20
	const SECONDS_TO_REACH_MAX_VELOCITY : float = 0.2
	const SECONDS_TO_STOP_FROM_MAX_VELOCITY : float = 0.05

#Camera config
class Zoom:
	const MAX_ZOOM_IN_SCALE : float = 2
	const MAX_ZOOM_OUT_SCALE : float = 0.3
	const ZOOM_KEY_SPEED : float = 1.5
	const ZOOM_SCROLL_SPEED : float = 0.2
