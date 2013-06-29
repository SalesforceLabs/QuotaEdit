public with sharing class CalendarUtil {

	public static List<SelectOption> getAvailableMonthlyPeriods() {
		Date today = Date.today();
		List<SelectOption> options = new List<SelectOption>();
		
		List<Period> periods = [SELECT StartDate FROM Period WHERE EndDate > :today AND Type='Month' ORDER BY StartDate];
		if (periods == null || periods.size() == 0)
			return options;
		
		for (Period p : periods) {
			options.add(new SelectOption(p.StartDate.format(), p.StartDate.format()));
		}
		return options;
	}
	
	public static Date getPeriodForNow() {
		Date today = Date.today();
		List<Period> periods = [SELECT StartDate FROM Period Where EndDate <= :today AND StartDate >= :today LIMIT 1];
		if (periods == null || periods.size() == 0)
			return today;
		return periods.get(0).StartDate;
	}
	
}