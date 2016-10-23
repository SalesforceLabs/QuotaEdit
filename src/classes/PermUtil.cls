public class PermUtil {

    private static boolean manageQuotas = null;
    private static boolean viewAllForecasts = null;
    private static boolean forecastingEnabled = null;
    
    private static boolean hasManageQuotas() {
        if (manageQuotas == null) {
            Id userId = Id.valueOf(UserInfo.getUserId());
            List<PermissionSetAssignment> b = [SELECT p.Id FROM PermissionSetAssignment p
                WHERE p.PermissionSet.PermissionsManageQuotas=true AND p.assigneeId=:userId];
            manageQuotas = b != null && b.size() > 0;
        }
        return manageQuotas;                
    }
    
    private static boolean hasViewAllForecasts() {
        if (viewAllForecasts == null) {
            Id userId = Id.valueOf(UserInfo.getUserId());
            List<PermissionSetAssignment> b = [SELECT p.Id FROM PermissionSetAssignment p
                WHERE p.PermissionSet.PermissionsViewAllForecasts=true AND p.assigneeId=:userId];
            viewAllForecasts = b != null && b.size() > 0;
        }
        return viewAllForecasts;        
    }
    
    public static boolean hasForecastingEnabled() {
        if (forecastingEnabled == null) {
            Id userId = Id.valueOf(UserInfo.getUserId());
            List<User> b = [SELECT ForecastEnabled from User WHERE Id=:userId];
            forecastingEnabled = (b != null && b.size() > 0) ? b.get(0).ForecastEnabled : false;    
        }
        return forecastingEnabled;
    }
    
    public static boolean isWriteAllowed() {
    	return hasManageQuotas();    
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