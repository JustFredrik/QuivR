

function quivr_chat_connect(){
	/* Opens an IRC connection to Twitch */
	
	if not quivr_is_authenticated() or not quivr_auth_user_is_loaded() { return - 1 }
	
	// Create IRC Socket
	try {
		__quivr_irc_create_socket();
		__quivr_irc_connect();
		__quivr_irc_send_auth_handshake();
	
	} catch(_error){
		__quivr_log_error(string(_error.message));
	}

}

function __quivr_irc_create_socket(){
	//Create a TCP socket to allow for connecting to Twitch IRC.
	
	// Check if QuivR is initilialized
	if not instance_exists(o_quivr) { 
		throw("QuivR has not been initialized yet.");
	}
	var q = o_quivr;
	
	
	// Check if Socket already exists
	if (q.active_socket != -1) {
		throw("Already connected to a chat.");
	};
	
	// Create socket
	q.active_socket = network_create_socket(network_socket_tcp);
		
	// Check for socket creation error
	if ( q.active_socket < 0 ) { 
		network_destroy(q.active_socket);
		q.active_socket = -1;
		throw("Unable to create network socket.");
	}
	
	__quivr_log("Socket created! connecting to IRC...");
}
function __quivr_irc_connect() {
	var q = o_quivr;
	
	// Connect to IRC
	var connection = network_connect_raw(q.active_socket, "irc.chat.twitch.tv", QUIVR_IRC_PORT);
	
	// Check for connection errors
	if (connection < 0){
		network_destroy(q.active_socket);
		q.active_socket = -1;
		__quivr_log_error("Failed to connect to Twitch IRC on port " + string(QUIVR_IRC_PORT));
		return -1;
	}
	
	__quivr_log("Succesfully connected to Twitch IRC!");
}
function __quivr_irc_send_auth_handshake() {
	var q = o_quivr;

	var _user = quivr_get_auth_user_data();
	// Send Authenticate/Handshake to the IRC server
	
	for(var _i = 0; _i <= 2; _i++){
		
		if (_i == 0){
			_send_string = ("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands"); // Authenticated User
		}
		else if (_i == 1){
			show_debug_message("PASS oauth:" + string(q.auth_key));
			__quivr_send_message_irc("PASS oauth:" + string(q.auth_key)); // Authenticated User
		}
		else if (_i == 2){
			show_debug_message(_user);
			show_debug_message(_user.login);
			__quivr_send_message_irc("NICK " + string(_user.login)); // Name of Authenticated user
		}
		else {
			 // Chat to Join
		}
	
		// Anon Chat reading
		// NICK justinfan473737
		// PASS anything
	
		// Write data to buffer and send Packet.

		
	}

}
function __quivr_send_message_irc(_message){
	var _send_buff = buffer_create(256, buffer_fixed, 1);
	buffer_seek(_send_buff, buffer_seek_start, 0);
	buffer_write(_send_buff, buffer_string, string(_message) + string(chr(13) + chr(10)));
	network_send_raw(o_quivr.active_socket, _send_buff, buffer_get_size(_send_buff));
	buffer_delete(_send_buff);	
}


function quivr_irc_send_message(_message_string, _streamer_username = -1) {
	if _streamer_username == -1 {
		_streamer_username = quivr_get_auth_user_data().login;
	}
	__quivr_send_message_irc("PRIVMSG #" + _streamer_username + " :" + _message_string);
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
	q.auth_state = string(irandom_range(1000000000,99999999999)); // some lowball protection against CSF
	
	// Open Authentication Page
	url_open("https://id.twitch.tv/oauth2/authorize" + 
	"?response_type=token" + 
	"&client_id=" + string(QUIVR_CLIENT_ID) + 
	"&redirect_uri=http://localhost:8080" + 
	"&scope=chat%3Aedit%20chat%3Aread" + 
	"&state=" + string(q.auth_state));
}


function quivr_fetch_user(_user_id = ""){
	if not quivr_is_authenticated() { return -1 }
	
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


function quivr_clear_user_data(){
	
	// Remove User data
	if directory_exists(QUIVR_USER_PROFILE_PATH){
		directory_destroy(QUIVR_USER_PROFILE_PATH);
	}
	
	// Remove Profile Pictures
	if directory_exists(QUIVR_USER_PROFILE_IMG_PATH){
		directory_destroy(QUIVR_USER_PROFILE_IMG_PATH);
	}
}


function quivr_remove_auth_data(){
	var q = o_quivr;
	o_quivr.authenticating = false;
	o_quivr.authenticated = false;
	o_quivr.auth_key = "-1";
	o_quivr.auth_user_is_loaded = false;
	o_quivr.auth_user_data = __quivr_generate_temp_user_data();
	o_quivr.auth_key_expires_in = -1;
	
	// Remove Auth Key
	if file_exists(working_directory + QUIVR_AUTH_KEY_PATH){
		file_delete(working_directory + QUIVR_AUTH_KEY_PATH);	
	}
}


function quivr_revoke_auth(){
	if not quivr_is_authenticated() { return -1 }
	
	var q = o_quivr;
	var _header = ds_map_create();
	ds_map_add(_header, "Content-Type", "application/x-www-form-urlencoded");
	var _request_id = http_request("https://id.twitch.tv/oauth2/revoke", "POST", _header, "client_id=" + string(QUIVR_CLIENT_ID) + "&token=" + string(q.auth_key));
	ds_map_add(q.active_http_requests, _request_id, { request_type : QUIVR_HTTP_TYPE.revoke });
	ds_map_destroy(_header);
	return _request_id;
	
	quivr_remove_auth_data();
}


function quivr_is_authenticated() {
	return o_quivr.authenticated;
}


#region Config File functions ===============================================
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


#region QuiveR Macros =======================================================
#macro QUIVR_DEBUG_STRING	"QuiveR : "
#macro QUIVR_ERROR_STRING	"QuiveR ERROR: "
#macro QUIVR_VERSION		"0.1"
#macro QUIVR_DATE			"2022-08-19"

enum QUIVR_HTTP_TYPE {
	fetch_user,
	fetch_profile_image,
	validate,
	validate_on_startup,
	revoke,
}
#endregion