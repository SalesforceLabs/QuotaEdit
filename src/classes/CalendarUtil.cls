public with sharing class CalendarUtil {

	public static List<SelectOption> getAvailableMonthlyPeriods(Date startDateToDisable) {
		return getAvailablePeriods(startDateToDisable, 'Month');
	}
    
    public static Map<Id,Period> periodCache = new Map<Id,Period>();
    
    public static Period getPeriodById(Id periodId) {
        Period p = periodCache.get(periodId);
        if (p == null) {
            p = [SELECT FullyQualifiedLabel, StartDate, FiscalYearSettingsId, Number, Type FROM Period WHERE Id=:periodId];
            periodCache.put(periodId, p);
        }
        return p;
    }
	
    public static List<SelectOption> getAvailablePeriods(Date startDateToDisable, String typeOfPeriod) {
    	if(typeOfPeriod == null || typeOfPeriod == ''){
    		typeOfPeriod='Month';
    	}
        // By popular request, the lookback is expanded to a year.
        Date today = Date.today();
        Date startDate = today.addMonths(-13);
        List<SelectOption> options = new List<SelectOption>();
        
        List<Period> periods = [SELECT FullyQualifiedLabel, StartDate, EndDate FROM Period WHERE EndDate > :startDate AND Type=:typeOfPeriod ORDER BY StartDate LIMIT 999];
        
        for (Period p : periods) {
            periodCache.put(p.Id, p);
            String label = p.FullyQualifiedLabel + (p.EndDate > today ? '' : ' ' + System.Label.QE_In_the_past);
            SelectOption o = new SelectOption(p.Id, label);
            if (startDateToDisable != null && p.StartDate.daysBetween(startDateToDisable) == 0) {
                o.setDisabled(True);
            }
            options.add(o);
        }
        return options;
    }
    
    
    public static Id getPeriodForNow(String periodType) {
        Date today = Date.today();
        List<Period> periods;
        periods = [SELECT StartDate FROM Period Where EndDate >= :today AND StartDate <= :today AND Type = :periodType ORDER BY StartDate DESC LIMIT 1];
        if (periods == null || periods.size() == 0){
            // KA - updated the SOQL to avoid null exception
          periods = [SELECT StartDate FROM Period  ORDER BY StartDate DESC LIMIT 1];
           
        }
          
        return periods.isEmpty() ? null : periods.get(0).Id;
    }
    
}