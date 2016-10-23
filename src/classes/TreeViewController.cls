public with sharing class TreeViewController {
	
    private static JSONGenerator gen {get; set;}

    public Boolean selectable {get; set;}
	
	public String selectNodeKeys {get; set;}

	{
		selectable = false;
		selectNodeKeys = 'No value selected';
	}
	
	public String JsonData {get; set;}
	
	public static Id roleId {get; set;}
	
    public String getJsonString()
    {
        if (JsonData == null){
			JsonData = getTreeJSON(null);
        }
        return JsonData;
    }
    
    @RemoteAction
    public static String getChildNodesJSON(Id parentId) {
        return getTreeJSON(parentId);
    }
    
    private static String getTreeJSON(Id parentId) {
        gen = JSON.createGenerator(true);
        gen.writeStartArray();
        for (RoleNodeModel node : getRoleNodesByParentId(parentId)) {
            node.convertNodeToJSON(gen);
        }
        gen.writeEndArray();
        return gen.getAsString();
    } 
    
    private static List<RoleNodeModel> getRoleNodesByParentId(Id parentId) {
        if (parentId == null) 
            parentId = roleId;
        List<UserRole> roles = RoleUtils.getSubRolesOneLevel(parentId);
        List<RoleNodeModel> ret = new List<RoleNodeModel>();
        for (UserRole role : roles) {
            RoleNodeModel n = new RoleNodeModel(role);
            ret.add(n);
        }
        return ret;
    }
    
}