

function quivr_chat_connect(){
	
	// Check if QuivR is initilialized
	if not instance_exists(o_quivr){ 
		__quivr_log_error("QuivR has not been initialized yet.");
		return -1;
	}
	var q = o_quivr;
	
	
	// Check if Socket already exists
	if (q.active_socket != -1){
		__quivr_log_error("Already connected to a chat.");
		return -1;
	}
	
	// Create socket
	q.active_socket = network_create_socket(network_socket_tcp);
		
	// Check for socket creation error
	if (q.active_socket < 0) { 
		network_destroy(q.active_socket);
		q.active_socket = -1;
		__quivr_log_error("Unable to create network socket.");
		return -1;
	}
	
	__quivr_log("Socket created connection to IRC...");
	
	// Connect to IRC
	var connection = network_connect_raw(global.IRC_socket, "irc.twitch.tv", QUIVR_IRC_PORT);
	
	// Check for connection errors
	if (connection < 0){
		network_destroy(q.active_socket);
		q.active_socket = -1;
		__quivr_log_error("Failed to connect to Twitch IRC on port " + string(QUIVR_IRC_PORT));
		return -1;
	}
	
	__quivr_log("Succesfully connected to Twitch IRC!");
	
	// Authenticate/Handshake to the server
	var _send_buff = buffer_create(256, buffer_fixed, 1);
	var _send_string = "";
	for (var _i = 0; i < 3; i++){
		if (_i == 0){
			_send_string = "PASS " + string(q.oauth);
		}
		else if (_i == 1){
			_send_string = "NICK " + string(q.botname);
		}
		else {
			_send_string = "JOIN " + string(q.username);
		}
	
	// Write data to buffer and send Packet.
	buffer_seek(_send_buff, buffer_seek_start, 0);
	buffer_write(_send_buff, buffer_string, string(_send_string) + string(chr(13) + chr(10)));
	network_send_raw(q.active_socket, _send_buff, buffer_get_size(_send_buff));
	}
	
	buffer_delete(_send_buff);
}


function quivr_auth(){
	
	// Check if QuivR is initilialized
	if not instance_exists(o_quivr){ 
		__quivr_log_error("QuivR has not been initialized yet.");
		return -1;
	}
	var q = o_quivr;
	var _localhost = "http://localhost:8080/";
	
	if (q.authenticating){ __quivr_log_error("Already trying to authenticate."); return -1;}
	
	q.auth_server = network_create_server_raw(network_socket_tcp, 8080, 10);
	randomize();
	q.auth_state = string(irandom_range(1000000000,99999999999)); // some protection against CSF
	
	// Open Authentication Page
	url_open("https://id.twitch.tv/oauth2/authorize" + 
	"?response_type=token" + 
	"&client_id=" + string(QUIVR_CLIENT_ID) + 
	"&redirect_uri=http://localhost:8080" + 
	"&scope=channel%3Amanage%3Apolls+channel%3Aread%3Apolls" + 
	"&state=" + string(q.auth_state));
}


function quivr_fetch_user(_user_id = ""){
	
	var q = o_quivr;
	
	var _hash;
	if is_array(_user_id){
		// TODO
		_hash = _user_id; // Temp
	} 
	else {
		_hash = _user_id; // Temp
	}	
	var _header = ds_map_create();
	ds_map_add(_header, "Authorization", "Bearer " + q.auth_key);
	ds_map_add(_header, "Client-Id", string(QUIVR_CLIENT_ID));
	var _request_id = http_request("https://api.twitch.tv/helix/users", "GET", _header, "");
	
	ds_map_add(q.active_http_requests, _request_id, { request_type : QUIVR_HTTP_TYPE.fetch_user , fetch_user : true, is_auth_user : true});
	ds_map_destroy(_header);
	return _request_id;
	
}


function quivr_auth_user_is_loaded(){
	
	// Check if QuivR is initilialized
	if not instance_exists(o_quivr){  __quivr_log_error("QuivR has not been initialized yet."); return false; }
	return o_quivr.auth_user_is_loaded;
}


function quivr_get_auth_user_data(){
	// Check if QuivR is initilialized
	if not instance_exists(o_quivr){  __quivr_log_error("QuivR has not been initialized yet."); return -1; }
	return o_quivr.auth_user_data;
}


function quivr_clear_local_data(){
	
	// Remove User data
	if directory_exists(QUIVR_USER_PROFILE_PATH){
		directory_destroy(QUIVR_USER_PROFILE_PATH);
	}
	
	// Remove Profile Pictures
	if directory_exists(QUIVR_USER_PROFILE_IMG_PATH){
		directory_destroy(QUIVR_USER_PROFILE_IMG_PATH);
	}
	
	// Remove Auth Key
	if file_exists(working_directory + QUIVR_AUTH_KEY_PATH){
		file_delete(working_directory + QUIVR_AUTH_KEY_PATH);	
	}
}


function quivr_remove_auth_data(){
	var q = o_quivr;
	q.authenticating = false;
	q.authenticated = false;
	q.auth_key = "-1";
	q.auth_user_is_loaded = false;
	q.auth_user_data = __quivr_generate_temp_user_data();
	q.auth_key_expires_in = -1;
	quivr_clear_local_data();
}


function quivr_revoke_auth(){
	var q = o_quivr;
	var _header = ds_map_create();
	ds_map_add(_header, "Content-Type", "application/x-www-form-urlencoded");
	var _request_id = http_request("https://id.twitch.tv/oauth2/revoke", "POST", _header, "client_id=" + string(QUIVR_CLIENT_ID) + "&token=" + string(q.auth_key));
	ds_map_add(q.active_http_requests, _request_id, { request_type : QUIVR_HTTP_TYPE.revoke });
	ds_map_destroy(_header);
	return _request_id;
}


#region Config File functions
function quivr_cfg_get_store_auth_key_locally(){
		return o_quivr.config.store_auth_key_locally;
	}
	
function quivr_cfg_set_store_auth_key_locally(_val){
	if (_val == true) or (_val == false){
		o_quivr.config.store_auth_key_locally = _val;
		
		if (_val == false) && file_exists(working_directory + QUIVR_AUTH_KEY_PATH){
			file_delete(working_directory + QUIVR_AUTH_KEY_PATH);
		}
	} else {
		throw("Wrong type in Arguement 1 in quivr_cfg_set_store_auth_key_locally. Expected a BOOL.")
	}
}
#endregion


#region QuiveR Macros
#macro QUIVR_DEBUG_STRING	"QuiveR : "
#macro QUIVR_ERROR_STRING	"QuiveR ERROR: "
#macro QUIVR_VERSION		"0.1"
#macro QUIVR_DATE			"2022-08-19"
#macro QUIVR_IRC_PORT		443

enum QUIVR_HTTP_TYPE {
	fetch_user,
	fetch_profile_image,
	validate,
	validate_on_startup,
	revoke,
}
#endregion