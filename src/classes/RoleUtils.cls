public with sharing class RoleUtils {
    
    public static List<UserRole> getSubRolesOneLevel(Id roleId) {
        return [SELECT Id, Name FROM UserRole WHERE ParentRoleId = :roleId ORDER BY Name];
    }
    
    public static Id getRoleIdByUserId(Id userId) {
        return [select UserRoleId from User where Id = :userId].UserRoleId;
    }
    
    // Taken from http://blog.jeffdouglas.com/2011/02/15/find-my-salesforce-users-by-role-hierarchy/    
    public static List<User> getRoleSubordinateUsers(Id userId, Boolean isMultiCurrencyOrg) {
        // get requested user's role
        Id roleId = getRoleIdByUserId(userId);
        // get all of the roles underneath the user
        Set<Id> allSubRoleIds = getAllSubRoleIds(new Set<ID>{roleId});
        // get all of the ids for the users in those roles
        return getForecastUsersByRoleIds(allSubRoleIds, isMultiCurrencyOrg, false);
    }
    
    public static List<User> getForecastUsersByRoleIds(Set<Id> roleIds, Boolean isMultiCurrencyOrg, Boolean allRoles) {
        String query = 'Select Id, Name';
        if (isMultiCurrencyOrg)
            query += ', DefaultCurrencyIsoCode';
        query += ' From User where IsActive = TRUE AND ForecastEnabled = TRUE ';
        if (!allRoles)
            query += ' AND UserRoleId IN :roleIds LIMIT 999';
        
        return (List<User>) Database.query(query);
    }
    
    private static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
        
        Set<ID> currentRoleIds = new Set<ID>();
        
        // get all of the roles underneath the passed roles
        for(UserRole userRole :[select Id from UserRole where ParentRoleId 
                                IN :roleIds AND ParentRoleID != null])
            currentRoleIds.add(userRole.Id);
        
        // go fetch some more roles!
        if(currentRoleIds.size() > 0)
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        
        return currentRoleIds;
        
    }    
}