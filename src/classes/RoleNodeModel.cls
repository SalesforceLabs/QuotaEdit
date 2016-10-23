public class RoleNodeModel {
    
    // Role info properties - begin
    public String myRoleName {get; set;}
    
    public Id myRoleId {get; set;}
    
    public String myParentRoleId {get; set;}
    // Role info properties - end   
    
    // Node children identifier properties - begin
    public Boolean hasChildren {get; set;}

    public List<RoleNodeModel> myChildNodes {get; set;}
    // Node children properties - end   
    
    public RoleNodeModel(UserRole role){
        hasChildren = false;
        this.myRoleId = role.Id;
        this.myRoleName = role.Name;
        this.myParentRoleId = null;
    }
    
    public void convertNodeToJSON(JSONGenerator gen){
        gen.writeStartObject();
        gen.writeStringField('title', myRoleName);
        gen.writeStringField('key', myRoleId);
        gen.writeBooleanField('isFolder', true);
        gen.writeBooleanField('isLazy', true);
        if (hasChildren)
        {
            gen.writeFieldName('children');
            gen.writeStartArray();
            if (hasChildren)
            {
                for (RoleNodeModel r : myChildNodes)
                {
                    r.convertNodeToJSON(gen);
                }
            }
            gen.writeEndArray();
        }
        gen.writeEndObject();
    }
    
    
}