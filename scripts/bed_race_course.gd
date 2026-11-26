extends Control

const Art = preload("res://scripts/art.gd")
const START_X = 29.0
const FINISH_X = 894.0
const TEAM_WIDTH = 173.0
const TEAM_HEIGHT = 79.0
var target := 0.0
var player := 0.0
var rival := 0.0
var pace := 0.0
var stride := 0.0
var victory := false
var beach: Texture2D
var teams: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	beach = Art.texture("bed-race-beach")
	teams = Art.texture("bed-race-teams")

func _process(delta: float) -> void:
	var advance := target-player
	player = move_toward(player,target,delta*1.4)
	pace = move_toward(pace,1.0 if advance>.001 else 0.0,delta*4.0)
	stride += delta*24
	queue_redraw()

func _draw() -> void:
	if beach==null or teams==null: return
	draw_texture_rect(beach,Rect2(Vector2.ZERO,size),false)
	for row in 12:
		for col in 2:
			var tile := Color("#fff0d0") if (row+col)%2==0 else Color("#282137")
			draw_rect(Rect2(FINISH_X+col*6,182+row*10,6,10),tile)
	for row in 11:
		draw_rect(Rect2(START_X,186+row*10,3,5),Color("#fbdf9c9e"))
	draw_team(1,rival,232,1.0)
	draw_team(0,player,294,pace)
	if victory:
		for i in 19:
			var t := fposmod(stride*.08+i*.32,1.0)
			var point := Vector2(FINISH_X-175+i*9+sin(stride*.2+i)*16,100+t*145)
			draw_rect(Rect2(point,Vector2(3,5)),[Color("#ffe697"),Color("#76ffd1"),Color("#ff80b2")][i%3])

func draw_team(index: int, progress: float, ground: float, motion: float) -> void:
	var left := lerpf(START_X,FINISH_X-TEAM_WIDTH+10,progress)
	var bob := roundf(sin(stride+index)*2.0*motion)
	var dest := Rect2(roundf(left),ground-TEAM_HEIGHT+bob,TEAM_WIDTH,TEAM_HEIGHT)
	draw_set_transform(Vector2(left+TEAM_WIDTH*.57,ground-3),0,Vector2(1,.14))
	draw_circle(Vector2.ZERO,TEAM_WIDTH*.41,Color("#20132874"))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(teams,dest,Rect2(0,index*88,192,88))
	var spin := progress*50.0
	var wheels: Array = [.435,.882] if index==0 else [.425,.865]
	for wheel in wheels:
		var hub := dest.position+Vector2(TEAM_WIDTH*float(wheel),TEAM_HEIGHT*.86)
		for spoke in 3:
			var axis := Vector2.from_angle(spin+TAU*spoke/3.0)*5
			draw_line(hub,hub+axis,Color("#ffdc91"),1)
	if motion>.4:
		for i in 4:
			var t := fposmod(stride*.24+i*.23,1.0)
			var p := Vector2(left-7-t*37,ground-5-i*4)
			draw_rect(Rect2(p,Vector2(8-t*5,2)),Color(1,.73,.42,(1-t)*.55))
