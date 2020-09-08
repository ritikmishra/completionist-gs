
/*
 * This method is called by OpenTTD when an (auto)-save occurs. You should
 * return a table which can contain nested tables, arrays of integers,
 * strings and booleans. Null values can also be stored. Class instances and
 * floating point values cannot be stored by OpenTTD.
 */
function Completionist::Save()
{
	GSLog.Info("Saving data to savegame");

	// In case (auto-)save happens before we have initialized all data,
	// save the raw _loaded_data if available or an empty table.
	if (!this._init_done) {
		return this._loaded_data != null ? this._loaded_data : {};
	}
	local company_tables = {};
	foreach(cid, company in this._companies) {
		company_tables[cid] <- company.AsTable();
	}
	return { 
		companies = company_tables,
	};
}

/*
 * When a game is loaded, OpenTTD will call this method and pass you the
 * table that you sent to OpenTTD in Save().
 */
function Completionist::Load(version, tbl)
{
	GSLog.Info("Loading data from savegame made with version " + version + " of the game script");

	// Store a copy of the table from the save game
	// but do not process the loaded data yet. Wait with that to Init
	// so that OpenTTD doesn't kick us for taking too long to load.
	this._loaded_data = {}
   	foreach(key, val in tbl) {
		this._loaded_data.rawset(key, val);
	}

    this._loaded_from_save = true;
	this._loaded_from_version = version;
}
