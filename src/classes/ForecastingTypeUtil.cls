public with sharing class ForecastingTypeUtil {

    public static List<ForecastingType> types = getActiveForecastingTypes();
    
    public static List<ForecastingType> getActiveForecastingTypes() {
        return [SELECT Id, DeveloperName, MasterLabel, IsQuantity 
                FROM ForecastingType WHERE isActive=true ORDER BY MasterLabel];
    }
    
    public static ForecastingType getForecastingTypeById(Id typeId) {
        return [SELECT Id, DeveloperName, MasterLabel, IsQuantity FROM ForecastingType WHERE Id=:typeId];
    }
    
    public static List<SelectOption> getActiveForecastingTypesAsOptions() {
        List<SelectOption> ret = new List<SelectOption>();
        List<ForecastingType> ftypes = getActiveForecastingTypes();
        if (ftypes == null || ftypes.size() == 0)
            return ret;
        
        for (ForecastingType t : ftypes) {
            SelectOption o = new SelectOption(t.Id, t.MasterLabel);
            ret.add(o);
        }
        return ret;
    }
}