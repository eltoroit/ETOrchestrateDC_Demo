// sfdx force:apex:execute -f ./@ELTOROIT/scripts/apex/SetUserRecord.apex

// Find me
User me = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

// change timezone to Toronto
me.TimeZoneSidKey = 'America/Toronto';
// Enable debug mode for the default scratch org user
me.UserPreferencesUserDebugModePref = true;
update me;
