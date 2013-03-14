public with sharing class CalendarUtil {

	private static String[] months = new String[] {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};

	// Expecting a number between 1 and 12
	public static String getMonthName(integer m) {
		if (m < 1 || m > 12)
			return null;
		else return months[m-1];
	}
	
	public static List<SelectOption> getAvailableMonths() {
		List<SelectOption> options = new List<SelectOption>();
		for (Integer i = 1; i <= 12; i++) {
			options.add(new SelectOption(String.valueOf(i), months[i-1]));	
		}	
		return options;
	}
	
	public static List<SelectOption> getAvailableYears() {
		List<SelectOption> options = new List<SelectOption>();
		String y = String.valueOf(Date.today().year());
        options.add(new Selectoption(y,y));
        y = String.valueOf(Date.today().year()+1);
        options.add(new Selectoption(y,y));
		return options;		
	}
	
	
}