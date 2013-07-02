public with sharing class QuotaController {
	
	Date startDate = CalendarUtil.getPeriodForNow();
	
	public static Date futureDate = CalendarUtil.getPeriodForNow();

	static Id editUserId = null;
	
	public static Map<Id,QuotaModel> quotaMap = new Map<Id,QuotaModel>();
	
	
	public static String getHeaderMessage() {
		// If showing all quotas
		// If showing subordinates
		// If showing read-only
		// If not showing anything
		String ret = null;
		if (PermUtil.isReadOnlyAll()) {
			ret = 'You have permission to view quotas for all Forecast Enabled users, but no write permission';
		}
		else if (PermUtil.isReadWriteAll()) {
			ret = 'You have permission to view and edit quotas for all Forecast Enabled users';
		}
		else if (PermUtil.isReadWriteBelowMe()) {
			ret = 'You have permission to view and edit quotas for Forecast Enabled users in your forecasting hierarchy';
		}
		else if (PermUtil.isReadOnlyBelowMe()) {
			ret = 'You have permission to view (not edit) quotas for Forecast Enabled users in your forecasting hierarchy';
		}
		else {
			ret = 'You do not have permission to view quotas';
		}
		return ret;
	}
	
	public static boolean getSaveDisabled() {
		return PermUtil.isReadOnlyAll() || PermUtil.isReadOnlyBelowMe();
	}
	
	
	public String getStartDatePeriod() {
		return startDate.format();
	}
	 
	public void setStartDatePeriod(String startDateStr) {
		Date inputDate = Date.parse(startDateStr);
		this.startDate = Date.newInstance(inputDate.year(), inputDate.month(), inputDate.day());
		quotaMap.clear(); 
	}
	
	public static String getFuturePeriod() {
		return futureDate.format();
	}
	
	public static void setFuturePeriod(String futurePeriodStr) {
		Date inputDate = Date.parse(futurePeriodStr);
		futureDate = Date.newInstance(inputDate.year(), inputDate.month(), inputDate.day());		
	}

	public static Id getEditUserId() {
		return editUserId;
	}
	
	public static void setEditUserId(Id ownerId) {
		editUserId = ownerId;
	}
		

//	static List<QuotaModel> quotas { get; set; }
	
	public QuotaController() {
		getQuotas();
	}
	
	// For testing
	public static void setQuotas(List<QuotaModel> quotas) {
		quotaMap.clear();
		for (QuotaModel q : quotas) {
			Id userId = q.ownerId;
			quotaMap.put(userId, q);
		}
	}
	
	public List<QuotaModel> getQuotas() {
//		setEditUserId(null);
		if (!quotaMap.isEmpty()) {
			List<QuotaModel> ret = quotaMap.values();
			ret.sort();
			return ret;
		}
		System.debug(loggingLevel.INFO, 'Fetching quotas for date=' + startDate);
		return getQuotasForPeriod(startDate, quotaMap);
	}
	
	public static List<QuotaModel> getQuotasForPeriod(Date startDate, Map<Id,QuotaModel> quotaMapForFetch) {

		List<User> forecastUsers = new List<User>();
		quotaMapForFetch.clear();

		// Someone with "View All Forecasts" and "Manage Quotas" should
		// be able to see and set the quotas of all the Forecasting Enabled
		// users.	
		if (PermUtil.isReadWriteAll() || PermUtil.isReadOnlyAll()) {
			forecastUsers = [SELECT Id, Name FROM User WHERE ForecastEnabled = TRUE];
		}
		else if (PermUtil.isReadWriteBelowMe() || PermUtil.isReadOnlyBelowMe()) {
			// Traverse the role hierarchy and find all the subordinates.
			forecastUsers = RoleUtils.getRoleSubordinateUsers(Id.valueOf(UserInfo.getUserId()));  
		}

		// Create blank quota records for all users
		for (User user : forecastUsers) {
			System.debug('Name = ' + user.Name + ', Id=' + User.Id);
			QuotaModel quota = new QuotaModel();
			quota.ownerName = user.Name;
			quota.ownerId = user.Id;
			quota.startDate = startDate;
			quota.currencyIsoCode = isMultiCurrencyOrg ? CurrencyUtil.getUserDefaultCurrency(quota.OwnerId) : null;
			quotaMapForFetch.put(user.Id, quota);
		}
		
		Set<Id> userIds = quotaMapForFetch.keySet();
		
		// We have to use this clunky query creation, rather than using
		// the [SELECT... ] method, because if we reference CurrencyIsoCode
		// in a mono-currency org, we'll get a runtime error.
		String query = 'SELECT Id, QuotaOwnerId, PeriodId, QuotaAmount';
		if (isMultiCurrencyOrg)
			query += ', CurrencyIsoCode';
			
		query += ' FROM ForecastingQuota WHERE QuotaOwnerId IN :userIds';
		query += ' AND StartDate=:startDate';
						
		List<SObject> quotasFromDB = Database.query(query);
			
		for (SObject sobj : quotasFromDB) {
			Id userId = (Id) sobj.get('QuotaOwnerId');
			QuotaModel quota = quotaMapForFetch.get(userId);
						
			quota.quotaId = sobj.Id;
			quota.periodId = (String) sobj.get('PeriodId');
			quota.amount = (Double) sobj.get('QuotaAmount');
			if (isMultiCurrencyOrg) {
				quota.currencyIsoCode = (String) sobj.get('CurrencyIsoCode');
			}				
		}			
		List<QuotaModel> ret = quotaMapForFetch.values();
		ret.sort();
		return ret;
	}
	
	public static PageReference save() {
		PageReference ret = saveInternal(quotaMap.values());
		quotaMap.clear();
		return ret;
	}
	
	private static PageReference saveInternal(List<QuotaModel> quotaModelList) {
		
//		setEditUserId(null);
		List<ForecastingQuota> quotasList = new List<ForecastingQuota>();
		
		for (QuotaModel q : quotaModelList) {
			System.debug(loggingLevel.INFO, 'Save:' + q.ownerName + '=' + q.amount);
			
			// Don't save blank values. Look for objects where the ID and amount are null.
			// No support for deleting quotas - if clearing out a prevoiusly-saved quota,
			// then it's updated to a 0 quota.
			if (q.quotaId == null && (q.amount == 0))
				continue;
			
			ForecastingQuota fq = new ForecastingQuota(Id=q.quotaId, QuotaAmount=q.amount, QuotaOwnerId=q.ownerId, StartDate=q.startDate);
			if (isMultiCurrencyOrg) {
				// Necessary because referencing CurrencyIsoCode in a mono-currency org
				// results in a runtime exception.
				sObject sobj = fq;
				sobj.put('CurrencyIsoCode', q.currencyIsoCode);				
			}
			System.debug('Going to save this quota: amount=' + fq.QuotaAmount + ', owner=' + fq.QuotaOwnerId);
			quotasList.add(fq);
		}
		upsert quotasList;
		return null;
	}
		
	public static List<SelectOption> getAvailablePeriods() {
		return CalendarUtil.getAvailableMonthlyPeriods();
	}
	
	public boolean getRenderCurrencyColumn() {
		return isMultiCurrencyOrg;
	}
	
	public List<SelectOption> getAvailableIsoCodes() {
		return availableIsoCodes;
	}
	
	private static boolean isMultiCurrencyOrg = CurrencyUtil.isMultiCurrencyOrg();
	private static List<SelectOption> availableIsoCodes = isMultiCurrencyOrg ? CurrencyUtil.getAvailableIsoCodes() : null;
	
	public boolean displayPopup {get; set;}     
    
    public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {        
        displayPopup = true;    
    }
		
	public PageReference editCell() {
		Id paramId = ApexPages.currentPage().getParameters().get('editOwnerId');
		System.debug(logginglevel.INFO, 'Called edit with userId=' + paramId);
		setEditUserId(paramId);
		return null;
    }
    
    public static PageReference applyToPeriod() {
    	// Get current period's quotas
    	List<QuotaModel> currentPeriodQuotas = quotaMap.values();
    	// Create new ones with the future start date
    	List<QuotaModel> futurePeriodQuotas = new List<QuotaModel>();
    	for (QuotaModel m : currentPeriodQuotas) {
    		if (m.amount == null || m.amount == 0.0)
    			continue;
    		QuotaModel m2 = new QuotaModel();
    		m2.ownerName = m.ownerName;
			m2.ownerId = m.ownerId;
			m2.startDate = futureDate;
			m2.amount = m.amount;
			m2.currencyIsoCode = m.currencyIsoCode;
    		futurePeriodQuotas.add(m2);
    	}
    	return saveInternal(futurePeriodQuotas);
    }
	
	
}