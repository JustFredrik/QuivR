
// Re-validates the token every 45 min
if (authenticated){
	if ((current_time - last_validated) >= 2700000) { 
		/* in order to be compliant with Twitch API rules it is required for apps 
		 to re-validate tokens every hour. Quivr will do it every 45 minutes to have some margin. */
		__quivr_validate_auth_token();	
	}
}