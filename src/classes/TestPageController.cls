public with sharing class TestPageController 
{
    private static JSONGenerator gen {get; set;}

    public String getJsonString() 
    {
        String str = null;
		str = getTreeJSON(null);
        return str; 
    }
    
    public static String getTreeJSON(Id roleId) {
        gen = JSON.createGenerator(true);
        RoleNodeModel node = createNode(roleId);
        gen.writeStartArray();
        node.convertNodeToJSON(gen);
        gen.writeEndArray();
        return gen.getAsString();
    } 
    
    private static RoleNodeModel createNode(Id roleId) {
        UserRole role = [select Id, Name from UserRole where ParentRoleId = null];
        RoleNodeModel n = new RoleNodeModel(role);
        return n;
    }

    
    public String selectedValues {get; set;}

}