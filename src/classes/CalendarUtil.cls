public with sharing class CalendarUtil {

	public static List<SelectOption> getAvailableMonthlyPeriods(Date startDateToDisable) {
		return getAvailablePeriods(startDateToDisable, 'Month');
	}
	
    public static List<SelectOption> getAvailablePeriods(Date startDateToDisable, String typeOfPeriod) {
    	if(typeOfPeriod == null || typeOfPeriod == ''){
    		typeOfPeriod='Month';
    	}
        // By popular request, the lookback is expanded to a year.
        Date startDate = Date.today().addMonths(-13);
        List<SelectOption> options = new List<SelectOption>();
        
        List<FiscalYearSettings> fysettings = [SELECT Id, IsStandardYear, QuarterPrefix, PeriodPrefix, Name FROM FiscalYearSettings LIMIT 999];

        List<Period> periods = [SELECT StartDate, FiscalYearSettingsId, Number, Type FROM Period WHERE EndDate > :startDate AND Type=:typeOfPeriod ORDER BY StartDate LIMIT 999];
        if (periods == null || periods.size() == 0)
            return options;
        
        
        for (Period p : periods) {
            SelectOption o = new SelectOption(p.StartDate.format(), CalendarUtil.getLabelForOption(p, fysettings));
            if (startDateToDisable != null && p.StartDate.daysBetween(startDateToDisable) == 0) {
                o.setDisabled(True);
            }
            options.add(o);
        }
        return options;
    }
    
    public static String getLabelForOption(Period p, List<FiscalYearSettings> fySettings){
    	FiscalYearSettings currentSetting;
    	for (FiscalYearSettings fySetting : fySettings) {
    		if(fySetting.Id.equals(p.FiscalYearSettingsId)){
    			currentSetting = fySetting;
    			break;
    		}
    	}
    	
    	if(p.Type.equals('Month')){
	    	if(currentSetting.IsStandardYear){
	    		return p.StartDate.month() + ' FY ' + currentSetting.Name;
	    	}else{
				return currentSetting.periodPrefix + ' ' + p.Number + ' FY ' + currentSetting.Name;
	    	}
    	}else if(p.Type.equals('Quarter')){
    		if(currentSetting.IsStandardYear){
	    		return 'FQ' + p.Number + ' FY ' + currentSetting.Name;
	    	}else{
				return currentSetting.quarterPrefix + ' ' + p.Number + ' FY ' + currentSetting.Name;
	    	}
    	}
    	return p.StartDate.format();
    }
    
    public static Date getPeriodForNow(String periodType) {
        Date today = Date.today();
        List<Period> periods = [SELECT StartDate FROM Period Where EndDate >= :today AND StartDate <= :today AND Type = :periodType ORDER BY StartDate DESC LIMIT 1];
        if (periods == null || periods.size() == 0)
            return today;
        return periods.get(0).StartDate;
    }
    
}