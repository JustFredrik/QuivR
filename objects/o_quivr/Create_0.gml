
active_socket = -1;
authenticating = false;
authenticated = false;
active_http_requests = ds_map_create();
user_data = ds_map_create();
local_user_data = ds_map_create();
auth_key = "-1";
auth_user_is_loaded = false;
auth_user_data = __quivr_generate_temp_user_data();
auth_key_expires_in = -1;
last_validated = -1;

// Load locally stored data
if file_exists(working_directory + QUIVR_AUTH_KEY_PATH){
	var _file = file_text_open_read(working_directory + QUIVR_AUTH_KEY_PATH);
	var _auth = file_text_read_string(_file);
	auth_key = base64_decode(_auth);
	authenticated = true;
	__quivr_log("Locally stored OAuth token found!");
	__quivr_validate_auth_token(true);
}

// Load Config
if file_exists(working_directory + QUIVR_CONFIG_PATH){
	var _file = file_text_open_read(working_directory + QUIVR_CONFIG_PATH);
	var _cfg = file_text_read_string(_file);
	config = json_parse(_cfg);
	__quivr_validate_config();
} else {
	config = __quivr_generate_config();
}