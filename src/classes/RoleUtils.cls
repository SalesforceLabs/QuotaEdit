public with sharing class RoleUtils {

// Taken from http://blog.jeffdouglas.com/2011/02/15/find-my-salesforce-users-by-role-hierarchy/
 
  public static List<User> getRoleSubordinateUsers(Id userId) {
 
    // get requested user's role
    Id roleId = [select UserRoleId from User where Id = :userId].UserRoleId;
    // get all of the roles underneath the user
    Set<Id> allSubRoleIds = getAllSubRoleIds(new Set<ID>{roleId});
    // get all of the ids for the users in those roles
    return [Select Id, Name From User where ForecastEnabled = TRUE AND UserRoleId IN :allSubRoleIds LIMIT 999]; 
  }
 
  private static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
 
    Set<ID> currentRoleIds = new Set<ID>();
 
    // get all of the roles underneath the passed roles
    for(UserRole userRole :[select Id from UserRole where ParentRoleId 
      IN :roleIds AND ParentRoleID != null])
    currentRoleIds.add(userRole.Id);
 
    // go fetch some more rolls!
    if(currentRoleIds.size() > 0)
      currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
 
    return currentRoleIds;
 
  }
 
}