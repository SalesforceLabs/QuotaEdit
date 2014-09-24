public with sharing class ForecastingTypeUtil {

    public static List<ForecastingType> types = getActiveForecastingTypes();
    
    public static Map<Id,ForecastingType> typesMap = null;
    
    public static void initTypesMap() {
        if (typesMap != null) return;
        typesMap = new Map<Id,ForecastingType>();
        for (ForecastingType t : types) {
            typesMap.put(t.Id, t);
        }
    }
    
    public static List<ForecastingType> getActiveForecastingTypes() {
        return [SELECT Id, DeveloperName, MasterLabel, IsAmount, IsQuantity 
                FROM ForecastingType WHERE isActive=true ORDER BY MasterLabel];
    }
    
    public static ForecastingType getForecastingTypeById(Id typeId) {
        return [SELECT Id, DeveloperName, MasterLabel, IsAmount, IsQuantity FROM ForecastingType WHERE Id=:typeId];
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