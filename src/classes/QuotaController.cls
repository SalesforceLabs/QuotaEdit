public with sharing class QuotaController {
	
	String quotaYear = String.valueOf(Date.today().year());
	String quotaMonth = String.valueOf(Date.today().month());
	String monthName = CalendarUtil.getMonthName(Integer.valueOf(quotaMonth));
	
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
		else {
			ret = 'You do not have permission to view quotas';
		}
		return ret;
	}
	
	public static boolean getSaveDisabled() {
		return PermUtil.isReadOnlyAll();
	}
	
	
	public String getQuotaYear() {
		return quotaYear;
	}
	
	public void setQuotaYear(String quotaYear) {
		this.quotaYear = quotaYear;
	}

	public String getQuotaMonth() {
		return quotaMonth;
	}	
	
	public void setQuotaMonth(String quotaMonth) {
		this.quotaMonth = quotaMonth;
		this.monthName = CalendarUtil.getMonthName(Integer.valueOf(quotaMonth));
	}
	
	public String getMonthName() {
		return monthName;
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
		Date quotaDate = Date.newInstance(Integer.valueOf(quotaYear), Integer.valueOf(quotaMonth), 1);
		return getQuotasForPeriod(quotaDate);
	}
	
	public static Map<Id,QuotaModel> quotaMap = null;
	
	public static List<QuotaModel> getQuotasForPeriod(Date startDate) {

		List<User> forecastUsers = new List<User>();
		quotaMap = new Map<Id,QuotaModel>();

		// Someone with "View All Forecasts" and "Manage Quotas" should
		// be able to see and set the quotas of all the Forecasting Enabled
		// users.	
		if (PermUtil.isReadWriteAll() || PermUtil.isReadOnlyAll()) {
			forecastUsers = [SELECT Id, Name FROM User WHERE ForecastEnabled = TRUE ORDER BY Name];
		}
		else if (PermUtil.isReadWriteBelowMe()){
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
			quotaMap.put(user.Id, quota);
		}
		
		Set<Id> userIds = quotaMap.keySet();
		
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
			QuotaModel quota = quotaMap.get(userId);
						
			quota.quotaId = sobj.Id;
			quota.periodId = (String) sobj.get('PeriodId');
			quota.amount = (Double) sobj.get('QuotaAmount');
			if (isMultiCurrencyOrg) {
				quota.currencyIsoCode = (String) sobj.get('CurrencyIsoCode');
			}				
		}			
		
		return quotaMap.values();
	}
	
	public static PageReference save() {
		List<ForecastingQuota> quotasList = new List<ForecastingQuota>();
		
		for (QuotaModel q : quotaMap.values()) {
			
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
			quotasList.add(fq);
		}
		upsert quotasList;
		return null;
	}
	
	public static List<SelectOption> getAvailableYears() {
		return CalendarUtil.getAvailableYears();
	}
	
	public static List<SelectOption> getAvailableMonths() {
		return CalendarUtil.getAvailableMonths();
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
	
	
}