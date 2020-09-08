/** Import SuperLib for GameScript **/

import("Util.SuperLib", "SuperLib", 40);
Result <- SuperLib.Result;
Log <- SuperLib.Log;
Helper <- SuperLib.Helper;
Tile <- SuperLib.Tile;
Direction <- SuperLib.Direction;
Town <- SuperLib.Town;
Industry <- SuperLib.Industry;
Story <- SuperLib.Story;

// Additional SuperLib sub libraries can be found here:
// http://dev.openttdcoop.org/projects/superlib/repository

/** Import other libs **/
// There are several other libraries for Game Scripts out there. Check out
// http://bananas.openttd.org/en/gslibrary/ for an up to date list.
//
// Remember to set dependencies in the bananas web manager for all libraries
// that you use. This way users will automatically get all libraries of the
// version you selected when they download your Game Script.


/** Import other source code files **/
require("version.nut"); // get SELF_VERSION
require("dataclasses.nut");
const TICKS_PER_DAY = 74;


class Completionist extends GSController 
{
	_loaded_data = null;
	_loaded_from_version = null;

	_init_done = false;
	_companies = {};

	_town_ids = [];
	_cargo_ids = [];
	_goal_ids = [];

	_default_associated_goals = {};

	_completion_rating_threshold = [];

	// true if we are running from a loaded game
	_loaded_from_save = false;

	constructor() {}

	function _get_default_associated_goals() {
		local _default_associated_goals = {};
		foreach(townid, _ in this._town_ids){
			_default_associated_goals[townid] <- null;
		}
		return _default_associated_goals;
	}
}


function Completionist::Start()
{
	// Some OpenTTD versions are affected by a bug where all API methods
	// that create things in the game world during world generation will
	// return object id 0 even if the created object has a different ID. 
	// In that case, the easiest workaround is to delay Init until the 
	// game has started.
	if (Helper.HasWorldGenBug()) GSController.Sleep(1);

	this.Init();

	// Wait for the game to start (or more correctly, tell OpenTTD to not
	// execute our GS further in world generation)
	GSController.Sleep(1);

	// Game has now started and if it is a single player game,
	// company 0 exist and is the human company.

	local LOOP_TIME = (5 * TICKS_PER_DAY);

	// Main Game Script loop
	while (true) {
		local loop_start_tick = GSController.GetTick();

		// Handle incoming messages from OpenTTD
		this.Process();

		local ticks_used = GSController.GetTick() - loop_start_tick;
		GSController.Sleep(max(1, LOOP_TIME - ticks_used));
	}
}

/*
 * This method is called during the initialization of your Game Script.
 * As long as you never call Sleep() and the user got a new enough OpenTTD
 * version, all initialization happens while the world generation screen
 * is shown. This means that even in single player, company 0 doesn't yet
 * exist. The benefit of doing initialization in world gen is that commands
 * that alter the game world are much cheaper before the game starts.
 */
function Completionist::Init()
{
	if(!this._loaded_from_save) {
		
	}

	if(this._loaded_data != null) {
		this._companies = {};
		foreach(cid, company_table in this._loaded_data.companies) {
			this._companies[cid] <- Company.FromTable(company_table);
		}

		this._loaded_data = null;
	}
	
	this._completion_rating_threshold = 25;

	local townlist = GSTownList();
	foreach(townid, _ in townlist) {
		this._town_ids.append(townid);
		this._default_associated_goals[townid] <- null;
	}

	local cargolist = GSCargoList();
	foreach(cargoid, _ in cargolist) {
		this._cargo_ids.append(cargoid);
	}

	// Indicate that all data structures has been initialized/restored.
	this._init_done = true;
}

require("process.nut");
require("saveload.nut");