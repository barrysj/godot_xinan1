extends RefCounted
const STAFF_PATHS = {
	"archivist":"res://assets/art/ui/dispatch/asset_002/archivist.png",
	"liaison":"res://assets/art/ui/dispatch/asset_002/liaison.png",
	"technician":"res://assets/art/ui/dispatch/asset_002/technician.png",
}

static func staff(id: String) -> Texture2D:
	return load(STAFF_PATHS.get(id,STAFF_PATHS.archivist)) as Texture2D

static func portrait(id: String) -> Texture2D:
	var portrait := AtlasTexture.new()
	portrait.atlas = staff(id)
	portrait.region = Rect2(250,0,540,550)
	return portrait
