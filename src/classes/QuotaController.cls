public with sharing class QuotaController {
    
    Date startDate = CalendarUtil.getPeriodForNow();
    Id forecastingTypeId = ForecastingTypeUtil.types.get(0).Id;
    ForecastingType selectedType = ForecastingTypeUtil.types.get(0);
    
    public Date futureDate = CalendarUtil.getPeriodForNow();
    public String isQuantityString = 'false';

    public Map<Id,QuotaModel> quotaMap = new Map<Id,QuotaModel>();
    
    public String selectedPFString = '';
    
    public void onCheckProductFamily() {
    }
    
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
    
    public String getSelectedForecastingType() {
        return forecastingTypeId;
    }
    
    public void setSelectedForecastingType(Id selectedId) {
        forecastingTypeId = selectedId;
        selectedType = ForecastingTypeUtil.getForecastingTypeById(selectedId);
    }
    
    public void onChangeForecastType() {
        selectedType = ForecastingTypeUtil.getForecastingTypeById(forecastingTypeId);        
    }
    
    public String getStartDatePeriod() {
        return startDate.format();
    }
     
    public void setStartDatePeriod(String startDateStr) {
        Date inputDate = Date.parse(startDateStr);
        this.startDate = Date.newInstance(inputDate.year(), inputDate.month(), inputDate.day());
        quotaMap.clear(); 
    }
    
    public String getFuturePeriod() {
        return futureDate.format();
    }
    
    public void setFuturePeriod(String futurePeriodStr) {
        if (futurePeriodStr == null) return;
        Date inputDate = Date.parse(futurePeriodStr);
        futureDate = Date.newInstance(inputDate.year(), inputDate.month(), inputDate.day());        
    }

    public Boolean isQuantity() {
        return selectedType.IsQuantity;
    }
    
    public Boolean isProductFamily() {
        return selectedType.DeveloperName.contains('LineItem');
    }
    
    public String getDeveloperName() {
        return selectedType.DeveloperName;
    }
    
    public Boolean getIsProductFamily() {
        return isProductFamily();
    }

    public String getSelectedProductFamily() {
        return selectedPFString;
    }
    
    public void setSelectedProductFamily(String str) {
        selectedPFString = str;
    }
    
    public QuotaController() {
        getQuotas();
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
        System.debug(loggingLevel.INFO, 'Fetching quotas for date=' + startDate + ', isQuantity='+isQuantity());
        return getQuotasForPeriod(startDate, quotaMap);
    }
    
    public List<QuotaModel> getQuotasForPeriod(Date startDate, Map<Id,QuotaModel> quotaMapForFetch) {

        List<User> forecastUsers = new List<User>();
        quotaMapForFetch.clear();

        // Someone with "View All Forecasts" and "Manage Quotas" should
        // be able to see and set the quotas of all the Forecasting Enabled
        // users.   
        if (PermUtil.isReadWriteAll() || PermUtil.isReadOnlyAll()) {
            forecastUsers = [SELECT Id, Name FROM User WHERE ForecastEnabled = TRUE LIMIT 999];
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
            quota.isQuantity = isQuantity();
            quota.currencyIsoCode = isMultiCurrencyOrg ? CurrencyUtil.getUserDefaultCurrency(quota.OwnerId) : null;
            quota.productFamily = isProductFamily() ? selectedPFString : null;
            quotaMapForFetch.put(user.Id, quota);
        }
        
        Set<Id> userIds = quotaMapForFetch.keySet();
        Boolean isQuant = isQuantity();
        String productFamilyStr = selectedPFString;
        
        // We have to use this clunky query creation, rather than using
        // the [SELECT... ] method, because if we reference CurrencyIsoCode
        // in a mono-currency org, we'll get a runtime error.
        String query = 'SELECT Id, QuotaOwnerId, PeriodId';
        if (isQuantity()) {
            query += ', QuotaQuantity';
        }
        else {
            query += ', QuotaAmount';
        }
        if (isMultiCurrencyOrg)
            query += ', CurrencyIsoCode';
            
        query += ' FROM ForecastingQuota WHERE QuotaOwnerId IN :userIds';
        query += ' AND StartDate=:startDate';
        query += ' AND isQuantity=:isQuant';
        query += ' AND ForecastingTypeId=:forecastingTypeId';
        
        
        if (isProductFamily()) {
            query += ' AND ProductFamily=:productFamilyStr';
        }
        else {
            query += ' AND ProductFamily=\'\'';
        }
        
        List<SObject> quotasFromDB = Database.query(query);
            
        for (SObject sobj : quotasFromDB) {
            Id userId = (Id) sobj.get('QuotaOwnerId');
            QuotaModel quota = quotaMapForFetch.get(userId);            
            quota.quotaId = sobj.Id;
            quota.periodId = (String) sobj.get('PeriodId');
            quota.amount = (Double) sobj.get(isQuantity() ? 'QuotaQuantity' : 'QuotaAmount');
            quota.isQuantity = isQuantity();
            if (isMultiCurrencyOrg) {
                quota.currencyIsoCode = (String) sobj.get('CurrencyIsoCode');
            }               
        }           
        List<QuotaModel> ret = quotaMapForFetch.values();
        ret.sort();
        return ret;
    }
    
    public PageReference save() {
        PageReference ret = null;
        try {
            ret = saveInternal(quotaMap.values());
        }
        catch(System.DMLException ex) {
            // Can't tell if Quantity is not enabled for this org, so need to rely
            // on runtime exceptions.
            if (StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE == ex.getDmlType(0)
                && ex.getDmlFields(0).get(0).getDescribe().getName().equals('QuotaQuantity')) {
               }
            else if (StatusCode.DUPLICATE_VALUE == ex.getDmlType(0)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                    'If Quarterly Forecasting is enabled, please edit the quota using the start month only.'));
            }
            else if (ex.getMessage().contains('unless Product Families for Forecasting is enabled')) {
            }
            else {
                throw ex;
            }
        }
        quotaMap.clear();
        return ret;
    }
    
    private PageReference saveInternal(List<QuotaModel> quotaModelList) {
        List<ForecastingQuota> quotasList = new List<ForecastingQuota>();
        
        for (QuotaModel q : quotaModelList) {
            System.debug(loggingLevel.INFO, 'Save:' + q.ownerName + '=' + q.amount);
            
            // Don't save blank values. Look for objects where the ID and amount are null.
            // No support for deleting quotas - if clearing out a prevoiusly-saved quota,
            // then it's updated to a 0 quota.
            if (q.quotaId == null && (q.amount == null || q.amount == 0 || q.amount == 0.0))
                continue;
            
            ForecastingQuota fq = new ForecastingQuota(Id=q.quotaId, 
                QuotaOwnerId=q.ownerId, StartDate=q.startDate, ForecastingTypeId=this.forecastingTypeId);
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
        upsert quotasList;
        return null;
    }
        
    public static List<SelectOption> getAvailablePeriods() {
        return CalendarUtil.getAvailableMonthlyPeriods(null);
    }
    
    public static List<SelectOption> getActiveForecastingTypes() {
        return ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
    }
    
    public List<SelectOption> getAvailablePeriodsForApplyFuture() {
        return CalendarUtil.getAvailableMonthlyPeriods(startDate);
    }
    
    
    
    public Boolean getIsApplyToPeriodDisabled() {
        return futureDate.monthsBetween(startDate) == 0;
    }
    
    public static List<SelectOption> getQuantityOptions() {
        List<SelectOption> ret = new List<SelectOption>();
        ret.add(new SelectOption('true', 'Quantity'));
        ret.add(new SelectOption('false', 'Revenue'));
        return ret;
    }
    
    public static List<SelectOption> getProductFamilies() {
        return ProductFamilyUtil.getActiveProductFamilies();
    }
    
    
    
    public String getQuotaColumnHeader() {
        return isQuantity() ? 'Quota (Units)' : 'Quota (amount)';
    }
    
    public boolean getRenderCurrencyColumn() {
        return isMultiCurrencyOrg && !isQuantity();
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
        
    public PageReference applyToPeriod() {
        // Get current period's quotas
        List<QuotaModel> currentPeriodQuotas = quotaMap.values();
        
        // Get any saved quotas for the future period
        Map<Id,QuotaModel> quotasForFuture = new Map<Id,QuotaModel>();
        getQuotasForPeriod(futureDate, quotasForFuture);
        
        // Modify future period's quotas with this period's numbers
        for (QuotaModel m : currentPeriodQuotas) {
            QuotaModel m2 = quotasForFuture.get(m.ownerId);
            m2.amount = m.amount;
            if (isMultiCurrencyOrg) { 
            	m2.currencyIsoCode = m.currencyIsoCode;
            }
        }
        return saveInternal(quotasForFuture.values());
    }
    
    
}