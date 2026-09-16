extends Node
const Catalog = preload("res://game/art/holo_card_catalog.gd")
func _ready() -> void:
	var cards = Catalog.cards()
	assert(cards.size() >= 1)
	assert(cards.any(func(card): return card.resource_path.ends_with("/class_photo/card.tres")))
	# An isolated user directory tests discovery without registering a real card.
	var root = "user://holo-catalog-check-" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(root)
	assert(Catalog.cards(root).is_empty())
	var template = "res://.agents/skills/art-implementation/assets/holo_card/card.tres"
	if FileAccess.file_exists(template):
		var text = FileAccess.get_file_as_string(template).replace("REPLACE_CARD_ID","class_photo")
		var output = FileAccess.open(root.path_join("template.tres"),FileAccess.WRITE)
		output.store_string(text)
		output.close()
		var from_template = load(root.path_join("template.tres"))
		assert(from_template is Catalog.Visual and from_template.photo != null)
		DirAccess.remove_absolute(root.path_join("template.tres"))
	for id in ["zeta","alpha"]:
		DirAccess.make_dir_recursive_absolute(root.path_join(id))
		var copy = cards[0].duplicate()
		copy.title = id
		assert(ResourceSaver.save(copy,root.path_join(id).path_join("card.tres")) == OK)
	var discovered = Catalog.cards(root)
	assert(discovered.size() == 2 and discovered[0].title == "alpha" and discovered[1].title == "zeta")
	DirAccess.make_dir_recursive_absolute(root.path_join("invalid"))
	ResourceSaver.save(Resource.new(),root.path_join("invalid/card.tres"))
	assert(Catalog.cards(root).size() == 2)
	for id in ["zeta","alpha","invalid"]:
		DirAccess.remove_absolute(root.path_join(id).path_join("card.tres"))
		DirAccess.remove_absolute(root.path_join(id))
	DirAccess.remove_absolute(root)
	print("HOLO_CATALOG_CHECK PASS cards=",cards.size())
	get_tree().quit()
