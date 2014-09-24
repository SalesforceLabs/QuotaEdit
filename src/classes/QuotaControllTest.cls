/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class QuotaControllTest {
    
    private static User createUser(String username, String lastName, Boolean forecastEnabled) {
        
        String alias = username.split('@').get(0);
        Profile profile = [
           select Id from Profile where Name='Standard User'
        ];

        User user = new User(
            Username = username,
            Email = username,
            LastName = lastName,
            Alias = alias,
            ProfileID = profile.Id,
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey='UTF-8',
            ForecastEnabled = forecastEnabled
        );
        insert user;
        return user;
    }

    static testMethod void getOnlyForecastingUsers() {
        String emaila = 'a@quota.com';
        User a = createUser(emaila, 'ForecastingUser', TRUE);
        
        User b = createUser('b@quota.com', 'Non-ForecastingUser', FALSE);
        QuotaController qc = new QuotaController();
        
        List<QuotaModel> ret = qc.getQuotasForPeriod(Date.newInstance(2013, 3, 1), qc.quotaMap);
        System.debug(ret);
        
        Boolean aFound = false;
        Boolean bFound = false;
        
        for (QuotaModel q : ret) {
            if (q.ownerName.equals(a.Lastname))
                aFound = true;
            if (q.ownerName.equals(b.Lastname))
                bFound = true;
        }
        System.assert(aFound);
        System.assert(!bFound);
        
    }
    
    static testMethod void updateQuotas() {
        String emaila = 'a@quota.com';
        User a = createUser(emaila, 'ForecastingUser', TRUE);
        QuotaController qc = new QuotaController();
        List<QuotaModel> ret = qc.getQuotasForPeriod(Date.newInstance(date.today().year(), 3, 1), qc.quotaMap);
        
        for (QuotaModel qm : ret) {
            qm.amount = 5555;
        }
        qc.setQuotas(ret);
        qc.save();
        
        qc = new QuotaController();
        List<QuotaModel> ret2 = qc.getQuotasForPeriod(Date.newInstance(date.today().year(), 3, 1), qc.quotaMap);
        for (QuotaModel qm : ret2) {
            System.assertEquals(5555, qm.amount);
        }
        
    }
    
    
    static testMethod void testForecastingEnabled() {
        Id userId = Id.valueOf(UserInfo.getUserId());
        User u = [select ForecastEnabled from User where Id=:userId];
        u.ForecastEnabled = true;
        update u;
        System.assert(PermUtil.hasForecastingEnabled());
        PermUtil.isReadWriteBelowMe(); // dummy call for code coverage
    }
    
    static testMethod void testGetAvailableMonthlyPeriods() {
        CalendarUtil.getAvailableMonthlyPeriods(Date.today());
    }
    
    static testMethod void testGetAvailableIsoCodes() {
        if (!CurrencyUtil.isMultiCurrencyOrg())
            return;
        List<SelectOption> currencies = CurrencyUtil.getAvailableIsoCodes();
        System.assert(currencies != null && currencies.size() > 0);
        
        String userCurrency = CurrencyUtil.getUserDefaultCurrency(Id.valueOf(UserInfo.getUserId()));
        System.assert(userCurrency != null && userCurrency.length() > 0);
        boolean found = false;
        for (Selectoption option : currencies) {
            if (option.getValue().equals(userCurrency))
                found = true;
        }
        System.assert(found);
    }    
    
    static testMethod void testQuotaModelStr() {
        QuotaModel qm = new QuotaModel();
        System.assert(qm.getAmountString() == null);
        double amount = 1234.0;
        qm.setAmount(amount);
        qm.getAmountString();
        System.assert(qm.getAmount() == amount);
        
        
        // won't work for foreign locales
        // System.assert(qm.getAmountString().equals('1,234.00'));
        qm.amount = 52.3;
        //System.assert(qm.getAmountString().equals('52.30'));      
    }
    
    static testMethod void testHeaderMessage() {
        String ret = QuotaController.getHeaderMessage();
    }
    
    static testMethod void testSaveDisabled() {
        Boolean b = QuotaController.getSaveDisabled();
    }  
    
    static testMethod void testMiscGetSet() {
        QuotaController qc = new QuotaController();
        qc.setStartDatePeriod(Date.today().format());
        qc.getStartDatePeriod();
        qc.setFuturePeriod(Date.today().format());
        qc.getFuturePeriod();
        qc.getAvailablePeriodsForApplyFuture();
        QuotaController.getAvailablePeriods();
        qc.getIsApplyToPeriodDisabled();
        QuotaController.getQuantityOptions();
        qc.getQuotaColumnHeader();
        qc.getRenderCurrencyColumn();
        qc.getAvailableIsoCodes();
        qc.showPopup();
        qc.closePopup();
        qc.getSelectedForecastingType();
        qc.getSelectedProductFamily();
        qc.onChangeForecastType();
        qc.getUsesFamilies();
        QuotaController.getActiveForecastingTypes();
        QuotaController.getProductFamilies();
        qc.getCurrencyColumnHeader();
    } 
    
    static testMethod void testProductFamily() {
        ProductFamilyUtil.getActiveProductFamilies();
        QuotaController qc = new QuotaController();
        qc.onCheckProductFamily();
        qc.getIsProductFamily();
        qc.getSelectedProductFamily();
        qc.setSelectedProductFamily('abc');
        ProductFamilyUtil.usesFamilies();
        
    }
    
    static testmethod void testForecastingType() {
        ForecastingTypeUtil.initTypesMap();
        List<ForecastingType> t = ForecastingTypeUtil.getActiveForecastingTypes();
        ForecastingTypeUtil.getActiveForecastingTypesAsOptions();
        ForecastingTypeUtil.getForecastingTypeById(t.get(0).Id);
    }
    
}