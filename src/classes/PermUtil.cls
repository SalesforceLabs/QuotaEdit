public with sharing class PermUtil {

	private static boolean manageQuotas = null;
	private static boolean viewAllForecasts = null;
	private static boolean forecastingEnabled = null;
	
	private static boolean hasManageQuotas() {
		if (manageQuotas == null) {
			Id userId = Id.valueOf(UserInfo.getUserId());
			List<PermissionSet> b = [SELECT Name FROM PermissionSet
				WHERE PermissionsManageQuotas=true AND ProfileId IN (SELECT ProfileId from User WHERE Id=:userId)];
			manageQuotas = b != null && b.size() > 0;
		}
		return manageQuotas;				
	}
	
	private static boolean hasViewAllForecasts() {
		if (viewAllForecasts == null) {
			Id userId = Id.valueOf(UserInfo.getUserId());
			List<PermissionSet> b = [SELECT Name FROM PermissionSet
				WHERE PermissionsViewAllForecasts=true AND ProfileId IN (SELECT ProfileId from User WHERE Id=:userId)];
			viewAllForecasts = b != null && b.size() > 0;
		}
		return viewAllForecasts;		
	}
	
	public static boolean hasForecastingEnabled() {
		Id userId = Id.valueOf(UserInfo.getUserId());
		if (forecastingEnabled == null) {
			List<User> b = [SELECT ForecastEnabled from User WHERE Id=:userId];
			forecastingEnabled = (b != null && b.size() > 0) ? b.get(0).ForecastEnabled : false;	
		}
		return forecastingEnabled;
	}
	
	
	public static boolean isReadOnlyAll() {
		return hasViewAllForecasts() && !hasManageQuotas();
	}
	
	public static boolean isReadWriteAll() {
		return hasViewAllForecasts() && hasManageQuotas();
	}
	
	public static boolean isReadWriteBelowMe() {
		return hasManageQuotas();
	}
	
	public static boolean isReadOnlyBelowMe() {
		return !hasViewAllForecasts() && !hasManageQuotas() && hasForecastingEnabled();
	}
	

}