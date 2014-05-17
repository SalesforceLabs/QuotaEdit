public with sharing class CalendarUtil {

    public static List<SelectOption> getAvailableMonthlyPeriods(Date startDateToDisable) {
        // By popular request, the lookback is expanded to a year.
        Date startDate = Date.today().addMonths(-13);
        List<SelectOption> options = new List<SelectOption>();
        

        List<Period> periods = [SELECT StartDate FROM Period WHERE EndDate > :startDate AND Type='Month' ORDER BY StartDate LIMIT 999];
        if (periods == null || periods.size() == 0)
            return options;
        
        
        for (Period p : periods) {
            SelectOption o = new SelectOption(p.StartDate.format(), p.StartDate.format());
            if (startDateToDisable != null && p.StartDate.daysBetween(startDateToDisable) == 0) {
                o.setDisabled(True);
            }
            options.add(o);
        }
        return options;
    }
    
    public static Date getPeriodForNow() {
        Date today = Date.today();
        List<Period> periods = [SELECT StartDate FROM Period Where EndDate >= :today AND StartDate <= :today ORDER BY StartDate DESC LIMIT 1];
        if (periods == null || periods.size() == 0)
            return today;
        return periods.get(0).StartDate;
    }
    
}