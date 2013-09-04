public with sharing class CurrencyUtil {

	public static List<SelectOption> getAvailableIsoCodes() {
		String supportedISOCodesQ = 'SELECT ISOCode FROM CurrencyType WHERE IsActive=TRUE ORDER BY ISOCode';
		List<SObject> supportedISOCodes = Database.query(supportedISOCodesQ);
		List<SelectOption> ret = new List<SelectOption>();
		for (SObject sobj : supportedIsoCodes) {
			String code = (String)sobj.get('ISOCode');
			ret.add(new SelectOption(code, code));
		}
		return ret;
		
	}

	private static boolean multiCurrencyOrg = null;
	public static boolean isMultiCurrencyOrg() {
		if (multiCurrencyOrg == null) {
			multiCurrencyOrg = Schema.getGlobalDescribe().get('CurrencyType')!=null;
		}
		return multiCurrencyOrg;
	}
	
	private static String userDefaultCurrency = null;
	
	public static String getUserDefaultCurrency(Id userId) {
		if (userDefaultCurrency == null) {
			// Can't use SOQL bracket syntax because it will not compile on mono-currency orgs
			List<SObject> res = Database.query('SELECT DefaultCurrencyIsoCode FROM User WHERE Id=:userId');
			userDefaultCurrency = res.size() == 1 ? (String)res.get(0).get('DefaultCurrencyIsoCode') : null;
		}
		return userDefaultCurrency;		
	}
	
}