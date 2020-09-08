class Company
{
	id = 0;

	// table from TownID to Goal
	associated_goals = null;

	constructor(id, associated_goals = {}) {
		this.id = id;
		this.associated_goals = {};
		foreach(key, val in associated_goals) {
			this.associated_goals[key] <- val;
		}	
	}

	function AsTable() {
		local assd_goals_as_table = {};
		foreach(town_id, goal in this.associated_goals) {
			assd_goals_as_table[town_id] <- goal.AsTable();
		}

		return {
			id = this.id,
			associated_goals = assd_goals_as_table
		};
	}

	static function FromTable(tbl) {
		local associated_goals = {};
		foreach(town_id, goal_tbl in tbl.associated_goals) {
			associated_goals[town_id] <- Goal.FromTable(goal_tbl);
		}

		return Company(tbl.id, associated_goals);
	}
}

class Goal
{
	goal_id = -1;
	town_id = -1;

	constructor(goal_id, town_id){
		this.goal_id = goal_id;
		this.town_id = town_id;
	}

	function AsTable() {
		return {
			goal_id = this.goal_id,
			town_id = this.town_id
		};
	}

	static function FromTable(tbl) {
		return Goal(tbl.goal_id, tbl.town_id);
	}
}