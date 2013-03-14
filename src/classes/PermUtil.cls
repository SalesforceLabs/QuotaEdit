public with sharing class PermUtil {

	private static boolean manageQuotas = null;
	private static boolean viewAllForecasts = null;
	
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
	
	
	public static boolean isReadOnlyAll() {
		return hasViewAllForecasts() && !hasManageQuotas();
	}
	
	public static boolean isReadWriteAll() {
		return hasViewAllForecasts() && hasManageQuotas();
	}
	
	public static boolean isReadWriteBelowMe() {
		return hasManageQuotas();
	}
	

}