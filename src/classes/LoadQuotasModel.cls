// Used for returning header and row information for the UI quota table
global class LoadQuotasModel {
    public String periodName {get; set; }
    public List<String> columnHeaders {get; set; }
    public List<QuotaModel> quotaRows {get; set; }
    public Map<String,String> currencyCodes {get; set; }
    public Boolean readOnly {get; set; }
    
    public LoadQuotasModel(String periodName, List<String> columnHeaders, List<QuotaModel> quotaRows, Map<String,String> currencyCodes, Boolean readOnly) {
        this.periodName = periodName;
        this.columnHeaders = columnHeaders;
        this.quotaRows = quotaRows;
        this.currencyCodes = currencyCodes;
        this.readOnly = readOnly;
    }
    
}