public with sharing class ForecastingTypeUtil {

    public static List<ForecastingType> types = getActiveForecastingTypes();
    
    public static Map<Id,ForecastingType> typesMap = initTypesMap();
    
    private static Map<Id,ForecastingType> initTypesMap() {
        Map<Id,ForecastingType> ret = new Map<Id,ForecastingType>();
        for (ForecastingType t : types) {
            ret.put(t.Id, t);
        }
        return ret;
    }
    
    public static Integer getNumberOfTypes() {
        return types.size();
    }
    
    private static List<ForecastingType> getActiveForecastingTypes() {
        return [SELECT Id, DeveloperName, MasterLabel, IsAmount, IsQuantity 
                FROM ForecastingType WHERE isActive=true ORDER BY MasterLabel];
    }
    
    public static ForecastingType getForecastingTypeById(Id typeId) {
        return typesMap.get(typeId);
    }
    
    public static List<SelectOption> getActiveForecastingTypesAsOptions() {
        List<SelectOption> ret = new List<SelectOption>();
        
        for (ForecastingType t : types) {
            SelectOption o = new SelectOption(t.Id, t.MasterLabel);
            ret.add(o);
        }
        return ret;
    }
    
    public static Boolean isProductFamily(ForecastingType fType) {
        return fType.DeveloperName.contains('LineItem');
    }

    
}