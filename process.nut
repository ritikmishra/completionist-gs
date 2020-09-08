function Completionist::HandleEvents() {
    while(GSEventController.IsEventWaiting()) {
		local event = GSEventController.GetNextEvent();
		if(event == null) continue;
		local eventType = event.GetEventType();
		switch(eventType){
			case GSEvent.ET_COMPANY_BANKRUPT:	{
				// Delete the company from the company pool and unclaim town
				local deadcompany = GSEventCompanyBankrupt.Convert(event);
				this.CompanyRemoveByID(deadcompany.GetCompanyID());
				GSLog.Info("Found bankrupted company!");
				break;
			}
			case GSEvent.ET_COMPANY_MERGER: {
				// Merge the companies, remove old company and unclaim town
				local merge = GSEventCompanyMerger.Convert(event);
				this.CompanyRemoveByID(merge.GetOldCompanyID());
				GSLog.Info("Company merge of company " + merge.GetOldCompanyID() + " into " + GSCompany.GetName(merge.GetNewCompanyID()));
				break;
			}
			case GSEvent.ET_COMPANY_NEW: {
				//new company
				local new_company_event = GSEventCompanyNew.Convert(event);
				local cid = new_company_event.GetCompanyID();
				
				this._companies[cid] <- Company(cid, this._default_associated_goals);
				
				GSGoal.Question(0, cid, GSText(GSText.STR_WELCOME), GSGoal.QT_INFORMATION, GSGoal.BUTTON_START);
				GSLog.Info("Found new company! " + cid);

				break;
			}
		}
	}
}

function Completionist::RecomputeCompletion(cid) {

	local station_list = GSStationList(GSStation.STATION_ANY);
	local this_company_station_ids = [];
	// table between town ID and the station that gives presence
	// use a table like a set 
	local towns_with_our_presence = {};
	
	foreach(station_id, _ in station_list) {
		if(GSStation.GetOwner(station_id) == cid) {
			this_company_station_ids.append(cid);
			local station_location = GSStation.GetLocation(station_id); // TileIndex
			local local_authority = GSTile.GetTownAuthority(station_location); // TownID

			GSLog.Info("Checking to see if station " + GSStation.GetName(station_id) + " of company " + cid + "will count");

			if( !(local_authority in towns_with_our_presence) ) {
				foreach(cargoid in this._cargo_ids) {
					if(GSStation.HasCargoRating(station_id, cargoid)) {
						if(GSStation.GetCargoRating(station_id, cargoid) > this._completion_rating_threshold) {
							towns_with_our_presence[local_authority] <- station_location;
							GSLog.Info("it did");
						}
					}
				}
			}
		}
	}


	local company = this._companies[cid];

	foreach(local_authority, old_goal in company.associated_goals) {
		local town_name = GSTown.GetName(local_authority);
		local completed_town = local_authority in towns_with_our_presence;

		if(old_goal == null) {
			local new_goal_id = null;
			if(completed_town) {
				new_goal_id = GSGoal.New(cid, GSText(GSText.STR_COMPLETED_TOWN, local_authority), GSGoal.GT_TILE, towns_with_our_presence[local_authority]);	
				GSGoal.SetCompleted(new_goal_id, false);
				GSLog.Info("new goal, town name " + GSTown.GetName(local_authority) + ", completed");
			} else {
				new_goal_id = GSGoal.New(cid, GSText(GSText.STR_UNCOMPLETED_TOWN, local_authority), GSGoal.GT_TOWN, local_authority);	
				GSGoal.SetCompleted(new_goal_id, true);
				GSLog.Info("new goal, town name " + GSTown.GetName(local_authority) + ", not completed");
			}

			if(new_goal_id == GSGoal.GOAL_INVALID) {
				GSLog.Warning("problem creating goal");
			}
			this._goal_ids.append(new_goal_id);
			company.associated_goals[local_authority] = Goal(new_goal_id, local_authority);
		} else {
			if(completed_town) {
				GSGoal.SetText(old_goal.goal_id, GSText(GSText.STR_COMPLETED_TOWN, local_authority));
				GSGoal.SetCompleted(old_goal.goal_id, true);
				GSLog.Info("old goal, town name " + GSTown.GetName(local_authority) + ", completed");
			} else {
				GSGoal.SetText(old_goal.goal_id, GSText(GSText.STR_UNCOMPLETED_TOWN, local_authority));
				GSGoal.SetCompleted(old_goal.goal_id, false);
				GSLog.Info("old goal, town name " + GSTown.GetName(local_authority) + ", not completed");
			}
		}
	}	

}

function Completionist::Process() {
    this.HandleEvents();

	foreach(cid, _ in this._companies) {
		GSLog.Info("About to check the completion of company id " + cid);
		this.RecomputeCompletion(cid);	
	}
}