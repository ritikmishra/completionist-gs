class CompletionDetector {

    init_called = false;

    // Initializes this CompletionDetector, which may involve 
    // getting a list of all the items that can be completed or whatnot
    function Init();
    
    // Initialize the associated_goals table of a company
    function InitAssociatedGoals(company) {}

    // Recompute the associated_goals table of a company 
    function RecomputeCompanyCompletion(company) {}
}

// A completion detector that handles passengers and mail
class PAXMCompletionDetector extends CompletionDetector {
    
    _mail_mode = false;
    _town_ids = [];
    _cargo_ids = [];
    _minimum_rating_threshold = null;

    constructor() {
    }

    function Init() {
        local townlist = GSTownList();
        foreach(townid, _ in townlist) {
            this._town_ids.append(townid);
        }

        local cargolist = GSCargoList();
        foreach(cargoid, _ in cargolist) {
            local cargo_towneffect = GSCargo.GetTownEffect(cargoid);
            if(cargo_towneffect == GSCargo.TE_PASSENGERS || (this._mail_mode && GSCargo.TE_MAIL)) {
                this._cargo_ids.append(cargoid);
            }
        }

        this._minimum_rating_threshold = GSController.GetSetting("rating_threshold");
    };
    
    function InitAssociatedGoals(company) {
        local assd_goals = {};
        foreach(townid in this._town_ids) {
            local goalid = GSGoal.New(company.id, GSText(GSText.STR_UNCOMPLETED_TOWN, townid), GSGoal.GT_TOWN, townid);
            GSGoal.SetCompleted(goalid, false);
            assd_goals[townid] <- Goal(goalid, townid);
        }
        company.associated_goals = assd_goals;
    }

    function RecomputeCompanyCompletion(company) {
        local station_list = GSStationList(GSStation.STATION_ANY);
        local towns_with_our_presence = {};
        
        foreach(station_id, _ in station_list) {
            if(GSStation.GetOwner(station_id) == company.id) {
                local station_location = GSStation.GetLocation(station_id); // TileIndex
                local local_authority = GSTile.GetTownAuthority(station_location); // TownID

                GSLog.Info("Checking to see if station " + GSStation.GetName(station_id) + " of company " + company.id + "will count");

                if( !(local_authority in towns_with_our_presence) ) {
                    foreach(cargoid in this._cargo_ids) {
                        if(GSStation.HasCargoRating(station_id, cargoid)) {
                            if(GSStation.GetCargoRating(station_id, cargoid) > this._minimum_rating_threshold) {
                                towns_with_our_presence[local_authority] <- station_location;
                                GSLog.Info("it did");
                            }
                        }
                    }
                }
            }
        }

        foreach(townid in this._town_ids) {
            local old_goal = company.associated_goals[townid];
            if(townid in towns_with_our_presence) {
				GSGoal.SetText(old_goal.goal_id, GSText(GSText.STR_COMPLETED_TOWN, townid));
				GSGoal.SetCompleted(old_goal.goal_id, true);
				GSLog.Info("old goal, town name " + GSTown.GetName(townid) + ", completed");
			} else {
				GSGoal.SetText(old_goal.goal_id, GSText(GSText.STR_UNCOMPLETED_TOWN, townid));
				GSGoal.SetCompleted(old_goal.goal_id, false);
				GSLog.Info("old goal, town name " + GSTown.GetName(townid) + ", not completed");
			}
        }
    }
}
