public class ProductFamilyUtil {

    public static List<SelectOption> getActiveProductFamilies() {
        Schema.DescribeFieldResult f = Schema.sObjectType.Product2.fields.Family;
        List<Schema.PicklistEntry> entries = f.getPicklistValues();
        List<SelectOption> ret = new List<SelectOption>();
        
        ret.add(new SelectOption('', System.Label.QE_Products_Not_Categorized));
        
        for (Schema.Picklistentry entry : entries) {
            ret.add(new SelectOption(entry.getValue(), entry.getLabel()));
        }
        
        return ret;
    }
    
    public static Boolean usesFamilies() {
        Schema.DescribeFieldResult f = Schema.sObjectType.Product2.fields.Family;
        List<Schema.PicklistEntry> entries = f.getPicklistValues();
        return entries.size() > 0;
    }
}