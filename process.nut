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
				
				this._companies[cid] <- Company(cid, {});
				this._completion_checker.InitAssociatedGoals(this._companies[cid]);
				GSGoal.Question(0, cid, GSText(GSText.STR_WELCOME), GSGoal.QT_INFORMATION, GSGoal.BUTTON_START);
				GSLog.Info("Found new company! " + cid);

				break;
			}
		}
	}
}

function Completionist::RecomputeCompletion(cid) {
	this._completion_checker.RecomputeCompanyCompletion(this._companies[cid]);
}

function Completionist::Process() {
    this.HandleEvents();

	foreach(cid, _ in this._companies) {
		GSLog.Info("About to check the completion of company id " + cid);
		this.RecomputeCompletion(cid);	
	}
}