public with sharing class QuotaController {
	
  	// Static variables. Should be able to be access beyond the first call
	public static final Boolean forecastingEnabled = isForecastingEnabledFirstTimeCheck(); 
	public static final Id thisUserId = Id.valueOf(UserInfo.getUserId());
    public static final Id currentPeriodId = CalendarUtil.getPeriodForNow('Month');

   	public static Map<Id, QuotaModel> quotaMap = new Map<Id, QuotaModel>();


	// Getters for all the static variables
    public static Id getThisUserId() {
        return thisUserId;
    }
    
	public static boolean getForecastingEnabled() {
		return forecastingEnabled;
	}
    
    
	// Variables only needed for first-time load / defaults
	String periodType = '';
	Id futurePeriod = null;
	public String isQuantityString = 'false';
	public String selectedPFString = '';


	public QuotaController() {
		if (!forecastingEnabled)
			return;
        // Initialize periodType based on this call:
        getAvailablePeriodTypes();
		futurePeriod = CalendarUtil.getPeriodForNow(periodType);
		getQuotas();
	}
	
	
	// Avoid runtime errors by checking in advance whether
	// Forecasting is enabled in the org
	private static Boolean isForecastingEnabledFirstTimeCheck() {
		String[] types = new String[]{'ForecastingItem','ForecastingQuota'};
		Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
		
		if (results.size() < 2)
			return false;
		
		for (Schema.DescribeSObjectResult res : results) {
			System.debug('sObject Label: ' + res.getLabel());
			if (!res.isAccessible())
				return false;
		}
		if (ForecastingTypeUtil.getNumberOfTypes() == 0)
			return false;
		return true;
	}
		
	public void onCheckProductFamily() {
	}
	
	public static String getHeaderMessage() {
		// If showing all quotas
		// If showing subordinates
		// If showing read-only
		// If not showing anything
		String ret = null;
		
		if (PermUtil.isReadOnlyAll()) {
			ret = System.Label.QE_Quota_ViewAll;
		}
		else if (PermUtil.isReadWriteAll()) {
			ret = System.Label.QE_Quota_EditAll;
		}
		else if (PermUtil.isReadWriteBelowMe()) {
			ret = System.Label.QE_Quota_EditReports;
		}
		else if (PermUtil.isReadOnlyBelowMe()) {
			ret = System.Label.QE_Quota_ViewReports;
		}
		else {
			ret = System.Label.QE_Quota_CannotView;
		}
		
		return ret;
	}
	
	public static boolean getSaveDisabled() {
		return PermUtil.isReadOnlyAll() || PermUtil.isReadOnlyBelowMe();
	}

	public String getSelectedPeriodType() {
		return periodType;
	}
	
	public void setSelectedPeriodType(String selectedPeriod) {
		periodType = selectedPeriod;
	}
			
	public void setStartDatePeriod(String startDateStr) {
		Date inputDate = Date.parse(startDateStr);
		quotaMap.clear();
	}
	
	public Id getFuturePeriod() {
		return futurePeriod;
	}
	
	public void setFuturePeriod(Id newFuturePeriod) {	
        futurePeriod = newFuturePeriod;
	}
	
	public Boolean getUsesFamilies() {
		return ProductFamilyUtil.usesFamilies();
	}
		
	public String getSelectedProductFamily() {
		return selectedPFString;
	}
	
	public void setSelectedProductFamily(String str) {
		selectedPFString = str;
	}
	
	// For testing
	public void setQuotas(List<QuotaModel> quotas) {
		quotaMap.clear();
		
		for (QuotaModel q : quotas) {
			Id userId = q.ownerId;
			quotaMap.put(userId, q);
		}
	}
	
	public List<QuotaModel> getQuotas() {
		if (!quotaMap.isEmpty()) {
			List<QuotaModel> ret = quotaMap.values();
			ret.sort();
			return ret;
		}
		return null;
	}
	
    private static List<User> getForecastUsers(Set<Id> roleIds) {
        List<User> forecastUsers;
        
        if (roleIds.size() == 0) {
            if (PermUtil.isReadWriteAll() || PermUtil.isReadOnlyAll()) {
                // Someone with "View All Forecasts" and "Manage Quotas" should
                // be able to see and set the quotas of all the Forecasting Enabled
                // users.
				forecastUsers = RoleUtils.getForecastUsersByRoleIds(new Set<Id>(), isMultiCurrencyOrg, true);
            }
            else {
                forecastUsers = RoleUtils.getRoleSubordinateUsers(thisUserId, isMultiCurrencyOrg);    
            }               
		}
		else {
			forecastUsers = RoleUtils.getForecastUsersByRoleIds(roleIds, isMultiCurrencyOrg, false);
		}
        return forecastUsers;
    }

    @RemoteAction
    public static LoadQuotasModel refreshQuotas(final Id forecastingTypeId, final Id periodId, final String selectedProductFamily, List<Id> roleIds) {
        Period period = CalendarUtil.getPeriodById(periodId);
        ForecastingType fType = ForecastingTypeUtil.getForecastingTypeById(forecastingTypeId);
        System.debug(loggingLevel.INFO, 'Refresh quotas for period=' + period.Id + ', isQuantity=' + fType.IsQuantity);
        System.debug(loggingLevel.INFO, 'Role IDs (' + roleIds.size() + ')=' + roleIds);
		List<QuotaModel> quotas = refreshQuotas(periodId, fType, selectedProductFamily, roleIds);
        
        List<String> columnHeaders = new List<String>();
        columnHeaders.add(getNameColumnHeader());
        columnHeaders.add(getQuotaColumnHeader(fType.IsQuantity));
        
        Map<String,String> currencyCodes = new Map<String,String>();
        
        if (isMultiCurrencyOrg && fType.IsAmount) {
            columnHeaders.add(getCurrencyColumnHeader());
            for (SelectOption so : availableIsoCodes) {
                currencyCodes.put(so.getLabel(), so.getValue());
            }    
        }
        LoadQuotasModel ret = new LoadQuotasModel(period.FullyQualifiedLabel, columnHeaders, quotas, currencyCodes, !PermUtil.isWriteAllowed());
        return ret;

    }
    
	private static List<QuotaModel> refreshQuotas(final Id periodId, final ForecastingType forecastingType, final String selectedProductFamily, List<Id> roleIds) {
        
        Boolean isQuant = forecastingType.IsQuantity;
        Boolean isProductFamily = ForecastingTypeUtil.isProductFamily(forecastingType);
        Id forecastingTypeId = forecastingType.Id;
        
        System.debug(loggingLevel.INFO, 'Fetching quotas for period=' + periodId + ', isQuantity=' + forecastingType.IsQuantity);
        quotaMap.clear();
        
        
		List<User> forecastUsers = getForecastUsers(roleIds.size() == 0 ? new Set<Id>() : new Set<Id>(roleIds));
		// Create blank quota records for all users
		for (User user : forecastUsers) {
			System.debug('Name = ' + user.Name + ', Id=' + User.Id);
			QuotaModel quota = new QuotaModel();
			quota.ownerName = user.Name;
			quota.ownerId = user.Id;
            quota.periodId = periodId;
			quota.isQuantity = isQuant;
			quota.currencyIsoCode = isMultiCurrencyOrg ? (String)((SObject)user).get('DefaultCurrencyIsoCode') : null;
			quota.productFamily = isProductFamily ? selectedProductFamily : null;
            quota.forecastingTypeId = forecastingTypeId;
			quotaMap.put(user.Id, quota);
		}
		
		Set<Id> userIds = quotaMap.keySet();
		
		// We have to use this clunky query creation, rather than using
		// the [SELECT... ] method, because if we reference CurrencyIsoCode
		// in a mono-currency org, we'll get a runtime error.
		String query = 'SELECT Id, QuotaOwnerId, PeriodId';
		
		if (isQuant) {
			query += ', QuotaQuantity';
		}
		else {
			query += ', QuotaAmount';
		}
		
		if (isMultiCurrencyOrg)
			query += ', CurrencyIsoCode';
			
		query += ' FROM ForecastingQuota WHERE QuotaOwnerId IN :userIds';
		query += ' AND PeriodId=:periodId';
		query += ' AND isQuantity=:isQuant';
		query += ' AND ForecastingTypeId=:forecastingTypeId';
		
		
		if (isProductFamily) {
			query += ' AND ProductFamily=:selectedProductFamily';
		}
		else {
			query += ' AND ProductFamily=\'\'';
		}
		
		List<SObject> quotasFromDB = Database.query(query);
		
		for (SObject sobj : quotasFromDB) {
			Id userId = (Id) sobj.get('QuotaOwnerId');
			QuotaModel quota = quotaMap.get(userId);
			quota.quotaId = sobj.Id;
			quota.periodId = (String) sobj.get('PeriodId');
			quota.amount = (Double) sobj.get(isQuant ? 'QuotaQuantity' : 'QuotaAmount');
			quota.isQuantity = isQuant;
			
			if (isMultiCurrencyOrg) {
				quota.currencyIsoCode = (String) sobj.get('CurrencyIsoCode');
			}
		}
		
		List<QuotaModel> ret = quotaMap.values();
		ret.sort();
        System.debug(loggingLevel.INFO, 'Returning ' + ret.size() + ' rows, # from DB= ' + quotasFromDB.size());
		return ret;
	}
    
    @RemoteAction
    public static void saveRemoteAction(List<QuotaModel> quotas, Id periodId) {
        if (!PermUtil.isWriteAllowed()) {
            NoAccessException e = new NoAccessException();
            e.setMessage(System.Label.QE_Quota_NoWritePerm);
            throw e;
        }
            
        saveInternal(quotas, periodId);        
    }
    
	
	private static void saveInternal(List<QuotaModel> quotaModelList, Id periodId) {
        Period period = CalendarUtil.getPeriodById(periodId);
        
		List<ForecastingQuota> quotasList = new List<ForecastingQuota>();
        List<Id> idsToDelete = new List<Id>();
		
		for (QuotaModel q : quotaModelList) {
			System.debug(loggingLevel.INFO, 'Save:' + q.ownerName + '=' + q.amount);
			
			// Don't save blank values. Look for objects where the ID and amount are null.
			if (q.quotaId == null && (q.amount == null || q.amount == 0 || q.amount == 0.0))
				continue;

            if (q.isDeleted != null && q.isDeleted) {
                idsToDelete.add(q.quotaId);
                continue;
            }
                
				
			ForecastingQuota fq = new ForecastingQuota(Id = q.quotaId,
					QuotaOwnerId = q.ownerId, StartDate = period.StartDate, ForecastingTypeId = q.forecastingTypeId);
					
			if (q.isQuantity) {
				fq.QuotaQuantity = q.amount;
			}
			else {
				fq.QuotaAmount = q.amount;
			}
			
			if (q.productFamily != null) {
				fq.ProductFamily = q.productFamily;
			}
			
			if (isMultiCurrencyOrg) {
				// Necessary because referencing CurrencyIsoCode in a mono-currency org
				// results in a runtime exception.
				sObject sobj = fq;
				sobj.put('CurrencyIsoCode', q.currencyIsoCode);
			}
			
			System.debug('Going to save this quota: quantity=' + (q.isQuantity ? 'true' : 'false') +
						 'amount=' + (q.isQuantity ? fq.QuotaQuantity : fq.QuotaAmount) + ', owner=' + fq.QuotaOwnerId);
			quotasList.add(fq);
		}
		
        if (quotasList.size() > 0)
			upsert quotasList;
        
        if (idsToDelete.size() > 0) {
            List<ForecastingQuota> objToDelete = [SELECT Id FROM ForecastingQuota WHERE Id IN :idsToDelete];
            delete objToDelete;
        }
		return;
	}
    
    public static Id getRootRoleId() {
        if (PermUtil.isReadOnlyAll() || PermUtil.isReadWriteAll())
            return null;
        else
            return RoleUtils.getRoleIdByUserId(thisUserId);
    }
	
	public List<SelectOption> getAvailablePeriodTypes() {
		List<SelectOption> types = new List<SelectOption>();
        List<SObject> typesFromQuery = [SELECT Type FROM Period WHERE Id IN (SELECT PeriodId from ForecastingItem) GROUP BY Type];
        for (Sobject s : typesFromQuery) {        
            types.add(new SelectOption((String)s.get('Type'),(String) s.get('Type')));
        }
        if (typesFromQuery.size() == 1) {
            periodType = types.get(0).getValue();
        }
		return types;
	}
	
	public List<SelectOption> getAvailablePeriods() {
		return CalendarUtil.getAvailablePeriods(null, periodType);
	}
	
	public static List<SelectOption> getActiveForecastingTypes() {
		return ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
	}
	
	public static List<SelectOption> getQuantityOptions() {
		List<SelectOption> ret = new List<SelectOption>();
		ret.add(new SelectOption('true', System.Label.QE_Quantity));
		ret.add(new SelectOption('false', System.Label.QE_Revenue));
		return ret;
	}
	
	public static List<SelectOption> getProductFamilies() {
		return ProductFamilyUtil.getActiveProductFamilies();
	}
	
    public static String getNameColumnHeader() {
        Map<String, Schema.SObjectField> M = Schema.SObjectType.User.fields.getMap();
        return M.get('Name').getDescribe().getLabel();
    }
    
	public static String getCurrencyColumnHeader() {
		if (UserInfo.isMultiCurrencyOrganization()) {
			Map<String, Schema.SObjectField> M = Schema.SObjectType.ForecastingQuota.fields.getMap();
			Schema.SObjectField isof = M.get('currencyIsoCode');
			return isof.getDescribe().getLabel();
			//return ForecastingQuota.currencyIsoCode.getDescribe().getLabel();
		}
		else {
			return 'Currency';
		}
	}
	
	public static String getQuotaColumnHeader(Boolean isQuantity) {
		Map<String, Schema.SObjectField> M = Schema.SObjectType.ForecastingQuota.fields.getMap();
		
		if (isQuantity) {
			return M.get('QuotaQuantity').getDescribe().getLabel();
		}
		else {
			return M.get('QuotaAmount').getDescribe().getLabel();
		}		
	}
	
	public boolean getRenderCurrencyColumn(Boolean isQuantity) {
		return isMultiCurrencyOrg && !isQuantity;
	}
	
	public List<SelectOption> getAvailableIsoCodes() {
		return availableIsoCodes;
	}
	
	private static boolean isMultiCurrencyOrg = CurrencyUtil.isMultiCurrencyOrg();
	private static List<SelectOption> availableIsoCodes = isMultiCurrencyOrg ? CurrencyUtil.getAvailableIsoCodes() : null;
	
	public boolean displayPopup {get; set;}
    
    public String selectedRoles {get; set;}
	
	public void closePopup() {
		displayPopup = false;
	}
	public void showPopup() {
		displayPopup = true;
	}
	
    @RemoteAction
    public static void saveToPeriodRemoteAction(final Id forecastingTypeId, final Id futurePeriodId, final String selectedProductFamily, List<Id> roleIds, List<QuotaModel> quotas) {

        if (!PermUtil.isWriteAllowed()) {
            NoAccessException e = new NoAccessException();
            e.setMessage(System.Label.QE_Quota_NoWritePerm);
            throw e;
        }

        ForecastingType forecastingType = ForecastingTypeUtil.getForecastingTypeById(forecastingTypeId);
        List<QuotaModel> futureQuotas = refreshQuotas(futurePeriodId, forecastingType, selectedProductFamily, roleIds);
        Period futurePeriod = CalendarUtil.getPeriodById(futurePeriodId);
        
        // Get any saved quotas for the future period
		Map<Id, QuotaModel> quotasForFuture = new Map<Id, QuotaModel>();
        for (QuotaModel q : futureQuotas) {
            quotasForFuture.put(q.ownerId, q);
        }
		
		// Modify future period's quotas with this period's numbers
		for (QuotaModel m : quotas) {
			QuotaModel m2 = quotasForFuture.get(m.ownerId);
            m2.startDate = futurePeriod.StartDate;
            m2.periodId = futurePeriodId;
			m2.amount = m.amount;
			
			if (isMultiCurrencyOrg) {
				m2.currencyIsoCode = m.currencyIsoCode;
			}
		}
        
        saveInternal(quotasForFuture.values(), futurePeriodId);

	}
}