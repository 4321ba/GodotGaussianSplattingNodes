class_name HealthAndMoney
extends Node

static var i: HealthAndMoney
static var tower_prices = [10, 20, 30]

@export var start_money: int = 16
@export var start_health: int = 20

var money: int
var health: int
var is_game_over: bool = false

func _enter_tree() -> void:
	# Set the global reference when this node enters the scene
	i = self

func _ready() -> void:
	money = start_money
	health = start_health
	# Initial UI update
	update_gui()

func _exit_tree() -> void:
	# Clean up the reference to prevent memory leaks or crashes
	if i == self:
		i = null

func add_money(amount: int) -> void:
	if is_game_over:
		return
	money += amount
	print("Money gained: ", amount)
	update_gui()

func remove_money(amount: int) -> bool:
	if is_game_over:
		return false
	if money >= amount:
		money -= amount
		update_gui()
		return true
	
	print("Not enough money! Required: ", amount, ", Current: ", money)
	return false

func remove_health(amount: int) -> void:
	if health > 0 and health - amount <= 0:
		game_over()
	health -= amount
	print("Health lost: ", amount)
	
	if health <= 0:
		health = 0
	update_gui()
	

func game_over() -> void:
	is_game_over = true
	print("!!! GAME OVER !!!")
	# Here you would typically pause the game or show a 'You Lose' screen
	# get_tree().paused = true

func update_gui() -> void:
	# This function will eventually interact with your Control nodes (Labels/TextureRects)
	# For now, it logs the current state to the console
	print(">> STATS UPDATE: Health = ", health, " | Money = ", money)
