class_name PlayerProfile
extends RefCounted
## Persistent profile of the player (UC-11, "PlayerProfile").
##
## Maps 1:1 to `user://save/player_profile.json`.
##
## The per-department numbers live in [DepartmentStats], not here. UC-11 lists
## `getDepartmentStats()` on this class, but a model should not own a lookup
## over a collection it cannot see, so that call belongs to the `DbService`
## singleton (`DbService.get_department_stats()`).

## Stable identifier of the profile, generated the first time the game runs.
var id: String = ""
var username: String = DbDefaults.DEFAULT_USERNAME
var company_level: int = DbDefaults.STARTING_COMPANY_LEVEL
var total_play_time_seconds: int = 0
## Unix timestamp (UTC) of the last time the profile was loaded.
var last_login_unix: int = 0


## Builds a brand-new profile, used the first time the game runs.
static func create(new_username: String = "") -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.id = _generate_id()
	profile.username = new_username if not new_username.is_empty() else DbDefaults.DEFAULT_USERNAME
	profile.touch_login()
	return profile


## Rebuilds a profile from parsed JSON. Never fails: missing or odd fields
## fall back to the defaults, so a hand-edited file cannot break the game.
static func from_dict(data: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new()
	var stored_id := JsonUtil.as_string(data.get("id"))
	profile.id = stored_id if not stored_id.is_empty() else _generate_id()
	profile.username = JsonUtil.as_string(data.get("username"), DbDefaults.DEFAULT_USERNAME)
	profile.company_level = maxi(
		DbDefaults.STARTING_COMPANY_LEVEL,
		JsonUtil.as_int(data.get("company_level"), DbDefaults.STARTING_COMPANY_LEVEL)
	)
	profile.total_play_time_seconds = maxi(0, JsonUtil.as_int(data.get("total_play_time_seconds")))
	profile.last_login_unix = maxi(0, JsonUtil.as_int(data.get("last_login_unix")))
	return profile


## Plain data for `JSON.stringify()`. The keys are the JSON field names.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"username": username,
		"company_level": company_level,
		"total_play_time_seconds": total_play_time_seconds,
		"last_login_unix": last_login_unix,
	}


## Stamps the login time. `now_unix` exists so tests can inject a fixed time.
func touch_login(now_unix: int = -1) -> void:
	last_login_unix = now_unix if now_unix > 0 else int(Time.get_unix_time_from_system())


## Adds (or, with a negative value, removes) play time, never below zero.
func add_play_time(seconds: int) -> void:
	total_play_time_seconds = maxi(0, total_play_time_seconds + seconds)


func set_company_level(level: int) -> void:
	company_level = maxi(DbDefaults.STARTING_COMPANY_LEVEL, level)


## `last_login_unix` as a readable UTC date ("" when never logged in).
func last_login_iso() -> String:
	if last_login_unix <= 0:
		return ""
	return Time.get_datetime_string_from_unix_time(last_login_unix, true)


static func _generate_id() -> String:
	return "player_%d" % int(Time.get_unix_time_from_system())
