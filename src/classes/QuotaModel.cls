global class QuotaModel implements Comparable {
	public Id quotaId { get; set; }
	public Id ownerId { get; set; }
	public string ownerName { get; set; }
	public double amount;
	public string currencyIsoCode {get; set; }
	public date startDate {get; set; }
	public string periodId {get; set; }
	
	public void setAmount(double amount) {
		System.debug('Amount being set to ' + amount + ' for owner ' + ownerName);
		this.amount = amount;
	}
	
	public double getAmount() {
		return amount;
	}
	
	public String getAmountString() {
		String amountStr = String.valueOf(amount);
		if (amountStr == null) 
			return null;
		// Make the number display with two digits after the decimal. If a whole number, 
		// then text formatting usually adds just one digit, e.g. 1234 -> 1234.0 . We want
		// 1234.00
		integer decimalLocation = amountStr.lastIndexOf('.');
		if (decimalLocation == amountStr.length() - 2)
			amountStr += '0';
		return amountStr;
	}
	
	global Integer CompareTo(Object compareTo) {
		QuotaModel compareToQuota = (QuotaModel) compareTo;
		return this.ownerName.compareTo(compareToQuota.ownerName);
	}
	
}