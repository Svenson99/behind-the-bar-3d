extends RefCounted

const RECIPES = [
	{"name":"Gin & Tonic", "liquid":{"gin":50.0,"tonic":150.0}, "glass":"highball", "method":"build", "garnish":"lime"},
	{"name":"Rum & Cola", "liquid":{"rum":50.0,"cola":150.0}, "glass":"highball", "method":"build", "garnish":"lime"},
	{"name":"Screwdriver", "liquid":{"vodka":50.0,"orange":100.0}, "glass":"highball", "method":"build", "garnish":"orange"},
	{"name":"Daiquiri", "liquid":{"rum":60.0,"lime":25.0,"syrup":15.0}, "glass":"coupe", "method":"shake", "garnish":"lime"},
	{"name":"Gin Martini", "liquid":{"gin":60.0,"vermouth":10.0}, "glass":"coupe", "method":"stir", "garnish":"olive"}
]
var liquid: Dictionary
var ice: Dictionary
var method: Dictionary
var glass_type = "highball"
var garnish = "none"
var spilled = 0.0

func decant(source: String, destination: String, amount: float) -> void:
	if source == destination or not liquid.has(source) or amount <= 0: return
	var total = volume(source)
	if total <= 0: return
	var ratio = minf(1.0, amount / total)
	for ingredient in liquid[source].keys():
		var moved = liquid[source][ingredient] * ratio
		liquid[source][ingredient] -= moved
		if liquid.has(destination): pour(ingredient, moved, destination)
		else: spilled += moved
	if liquid.has(destination):
		ice[destination] = ice[destination] or ice[source]
		method[destination] = method[source]

func _init() -> void:
	clear()

func clear() -> void:
	liquid = {"glass":{}, "jigger":{}, "shaker":{}}
	ice = {"glass":false, "jigger":false, "shaker":false}
	method = {"glass":"build", "jigger":"build", "shaker":"build"}
	glass_type = "highball"
	garnish = "none"
	spilled = 0.0

func volume(container: String) -> float:
	var amount = 0.0
	for n in liquid[container].values():
		amount += float(n)
	return amount

func pour(ingredient: String, amount: float, container: String) -> void:
	if not is_finite(amount) or amount <= 0.0 or not liquid.has(container):
		return
	var capacity = 50.0 if container == "jigger" else (150.0 if container == "glass" and glass_type == "coupe" else 350.0)
	var accepted = minf(amount, maxf(0.0, capacity - volume(container)))
	liquid[container][ingredient] = float(liquid[container].get(ingredient, 0.0)) + accepted
	spilled += amount - accepted

func transfer(source: String, destination: String) -> void:
	if source == destination or not liquid.has(source) or not liquid.has(destination):
		return
	for ingredient in liquid[source]:
		pour(ingredient, liquid[source][ingredient], destination)
	if volume(source) > 0.0:
		ice[destination] = ice[destination] or ice[source]
		if method[source] != "build":
			method[destination] = method[source]
	liquid[source] = {}
	ice[source] = false
	method[source] = "build"

func breakdown(index: int) -> Dictionary:
	var recipe = RECIPES[index % RECIPES.size()]
	var parts = {"Ingredients":0, "Glass":0, "Ice":0, "Technique":0, "Garnish":0}
	if volume("glass") <= 0.0:
		return parts
	var expected = 0.0
	var error = 0.0
	var keys = recipe.liquid.keys()
	for key in liquid.glass:
		if not keys.has(key):
			keys.append(key)
	for key in recipe.liquid:
		expected += float(recipe.liquid[key])
	for key in keys:
		error += absf(float(recipe.liquid.get(key, 0.0)) - float(liquid.glass.get(key, 0.0)))
	parts.Ingredients = roundi(maxf(0.0, 60.0 * (1.0 - error / expected)))
	parts.Glass = 10 if glass_type == recipe.glass else 0
	parts.Ice = 10 if ice.glass else 0
	parts.Technique = 10 if method.glass == recipe.method else 0
	parts.Garnish = 10 if garnish == recipe.garnish else 0
	return parts

func quality(index: int) -> int:
	var total = 0
	for part in breakdown(index).values():
		total += int(part)
	return total
