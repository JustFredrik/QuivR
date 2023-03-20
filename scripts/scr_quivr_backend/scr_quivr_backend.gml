

function __quivr_send_auth_webpage(){
	
	// Check if QuivR is initilialized
	if not instance_exists(o_quivr){ 
		__quivr_log_error("QuivR has not been initialized yet.");
		return -1;
	}
	var q = o_quivr;
	
	#region HTML HEAD n'BODY
var _body = @"<html>
	<head>
		<meta name='viewport' content='width=device-width, initial-scale=1'>	
	</head>
	<body onload='loopBack();'>
		<p>All done here, you can close this now! :)</p>
		<script>
			var lo = String(document.location.hash);
			for (let i = 0; i < 3; i++) {
				var resp = new XMLHttpRequest();
				resp.open('POST', 'http://localhost:8080', true);
				resp.setRequestHeader('Content-Type', 'application/json');
				resp.send('{ auth_key : ' + lo + ' }');
			}
		</script>
		<p> </p>
	</body>
</html>
";

var _header_part_one = @"HTTP/1.1 200 OK
Date: Mon, 20 Aug 1337 69:69:69 GMT
Server: GameMaker 2.0
Last-Modified: Wed, 22 Jul 2009 19:15:56 GMT
Content-Length: ";

var _header_part_two = @"Content-Type: text/html
Connection: keep-alive

";

#endregion

	var _buff = buffer_create(8, buffer_grow, 1);
	buffer_seek(_buff, buffer_seek_start, 0);
	buffer_write(_buff, buffer_string, _body);
	var _size = buffer_get_size(_buff);
	
	__quivr_log("Sending AuthFixerWebpage!")
	buffer_seek(_buff, buffer_seek_start, 0);
	buffer_write(_buff, buffer_string, _header_part_one + string(_size) + "\n" + _header_part_two + _body);
	network_send_raw(q.auth_socket, _buff, buffer_get_size(_buff));
	buffer_seek(_buff, buffer_seek_start, 0);
	//show_debug_message(buffer_read(_buff, buffer_string));
	buffer_delete(_buff);
	
	
	
}


function __quivr_log(_string) {
	show_debug_message(QUIVR_DEBUG_STRING + string(_string));
}


function __quivr_log_error(_string){
	show_debug_message(QUIVR_ERROR_STRING + string(_string));	
}


function __quivr_network_async_handler(){
	
	show_debug_message("NETWORK EVENT TRIGGERED");
	
	var q = o_quivr;
	var _id		= ds_map_find_value(async_load, "id");
	var _ip		= ds_map_find_value(async_load, "ip");
	var _port	= ds_map_find_value(async_load, "port");
	var _type	= ds_map_find_value(async_load, "type");
	
	if ( _port == QUIVR_IRC_PORT ) {
		__quivr_network_handle_irc_response();
	} else {
		__quivr_network_handle_api_response()
	}
}


function __quivr_network_handle_irc_response() {
	var q = o_quivr;
	var _id		= ds_map_find_value(async_load, "id");
	var _ip		= ds_map_find_value(async_load, "ip");
	var _port	= ds_map_find_value(async_load, "port");
	var _type	= ds_map_find_value(async_load, "type");
	
	// Handle different Packet Types
	switch(_type){
		case network_type_data:
			
			// Get the Buffer
			var _buff		= ds_map_find_value(async_load, "buffer");
			var _buff_size	= ds_map_find_value(async_load, "size");
			var _string		= "";
			
			buffer_seek(_buff, buffer_seek_start, 0);
			while (buffer_tell(_buff) < _buff_size){
				_string += buffer_read(_buff, buffer_string);
			}
			show_debug_message("IRC MESSAGE RECIEVED!");
			var _user = quivr_get_auth_user_data();
			if string_pos("tmi.twitch.tv 001 "+ _user.login +" :Welcome, GLHF!", _string) != 0 {
				o_quivr.irc_chat_connected = true;
				__quivr_log("Connected to IRC chat for channel: " + _user.login);
			}
			break;
			
		default:
			show_debug_message("SOMETHING TRIGGERED IRC RESPONSE");
	}
}


function __quivr_network_handle_api_response() {
	
	show_debug_message("API EVENT TRIGGERED");
	
	var q = o_quivr;
	var _id		= ds_map_find_value(async_load, "id");
	var _ip		= ds_map_find_value(async_load, "ip");
	var _port	= ds_map_find_value(async_load, "port");
	var _type	= ds_map_find_value(async_load, "type");
	
	
	// Handle different Packet types
	switch(_type){
		
		#region DATA
		case network_type_data:
			
			// Get the Buffer
			var _buff		= ds_map_find_value(async_load, "buffer");
			var _buff_size	= ds_map_find_value(async_load, "size");
			var _string		= "";
			
			buffer_seek(_buff, buffer_seek_start, 0);
			while (buffer_tell(_buff) < _buff_size){
				_string += buffer_read(_buff, buffer_string);
			}

			if (string_pos("POST", _string) != 0) { // Packet contains OAuth token.
				var _auth_index = string_pos("auth_key", _string);
				var _auth_key = string_copy(_string, _auth_index + 25, string_pos("&", _string) - (_auth_index + 25));
				
				// Catch re-transmission
				if (q.auth_key == _auth_key){ return }
				
				// Assign New Auth Token
				q.auth_key = _auth_key;
				var _auth_log_string = QUIVR_OBFUSCATE_TOKEN ? "********************" : string(q.auth_key);
				__quivr_log("Auth Token Recieved! ( " + _auth_log_string + " )");
				q.authenticating = false;
				q.authenticated = true;
				
				// Fetch Authenticated users user data
				__quivr_log("Fetching authenticated user data...")
				quivr_fetch_user();
			}
			
			else if (string_pos("GET", _string) != 0) { // For any sort of GET just respond with the token grabber webpage.
				if (string_pos("/favicon.ico", _string) == 0){
					__quivr_send_auth_webpage();
				}
			}
	
			break;
		#endregion
		
		#region CONNECT, DISCONNECT & DEFAULT
		case network_type_connect:
			__quivr_log("New Connection from: " + string(_ip) + ", on port: " + string(_port) + ".");
			q.auth_socket = ds_map_find_value(async_load, "socket");
			break;
		
	
		case network_type_disconnect:
			__quivr_log("Connection closed from: " + string(_ip) + ", on port: " + string(_port) + ".");
			break;
		
		default:
			__quivr_log_error("Unknown network packet type recieved.");
			break;
		#endregion
	}
}


function __quivr_http_async_handler(){
	// This event handles all Standard Rest API requests. Fetch Userdata validate OAuth etc.
	
	var q = o_quivr;
	
	show_debug_message("HTTP TRIGGERED")
	
	// Check if response belongs to Quivr and is Ready
	var _id = ds_map_find_value(async_load, "id");
	var _req = ds_map_find_value(q.active_http_requests, _id);

	if (not is_struct(_req)){ return 0; } 
	if (ds_map_find_value(async_load, "status") != 0){ return 0; }
	
	// Check for access denied 
	if ((ds_map_find_value(async_load, "http_status")) >= 400){
		if (_req.request_type == QUIVR_HTTP_TYPE.validate){
			__quivr_log("OAuth token is no longer valid / has been revoked.")
			quivr_remove_auth_data();
		} 
		else {
			__quivr_validate_auth_token();	
		}
	}
	
	// Handle the Response
	var _result = ds_map_find_value(async_load, "result");
	
	switch(_req.request_type){
	
	// Response is Json with Userdata =====================================================================================================
	case QUIVR_HTTP_TYPE.fetch_user:

		// Prase Get JSON data
		show_debug_message(_result);
		var _parsed_result = json_parse(_result);
		
		show_debug_message(_parsed_result);
		
		// Check for Invalid Access Token
		if (variable_struct_exists(_parsed_result, "status") && _parsed_result.status == 401) { 
			quivr_remove_auth_data();
		} else  {
			_parsed_result = _parsed_result.data[0];
			_parsed_result.profile_image = spr_quivr_loading;
			ds_map_add(q.local_user_data, _parsed_result.id, _parsed_result);
		
			// Fetch User Profile Picture
			var _image_path = QUIVR_USER_PROFILE_IMG_PATH + @"\" + string(_parsed_result.id) + ".png";
		
		
			if file_exists(_image_path) {  // Image is already stored locally
				_parsed_result.profile_image = sprite_add(_image_path, 1, false, false, QUIVR_PROFILE_IMG_XORIG, QUIVR_PROFILE_IMG_YORIG);
			}
			else {	// Image Needs to be fetched from Twitch
				var _pfp_req = http_get_file(_parsed_result.profile_image_url, _image_path);
				ds_map_add(q.active_http_requests, _pfp_req, { request_type : QUIVR_HTTP_TYPE.fetch_profile_image, user_id: _parsed_result.id });
			}
		
			if (_req.is_auth_user){ // Store in specific var if user is Auth User
				q.auth_user_is_loaded = true;
				q.auth_user_data = _parsed_result;	
				__quivr_log("Authenticated user data loaded!");	 			
			}
		}
		break;

	
	// Response is Profile picture ========================================================================================================
	case QUIVR_HTTP_TYPE.fetch_profile_image:
		
		// Check for Invalid Access Token
		if (variable_struct_exists(_parsed_result, "status") && _parsed_result.status == 401) { 
			quivr_remove_auth_data();
			
		} else  {
			var _user = ds_map_find_value(q.local_user_data, _req.user_id);
			var _result_path = ds_map_find_value(async_load, "result");
			_user.profile_image = sprite_add(_result_path, 1, false, false, QUIVR_PROFILE_IMG_XORIG, QUIVR_PROFILE_IMG_YORIG);
		}
		break;
	
	// Response from Asking to Validate OAuth Token =======================================================================================
	case QUIVR_HTTP_TYPE.validate:
		var _parsed_result = json_parse(_result);
		show_debug_message(_parsed_result);

		// Check for Invalid Access Token
		if (variable_struct_exists(_parsed_result, "status") && _parsed_result.status == 401) { 
			quivr_remove_auth_data();
			
		} else {
			q.auth_key_expires_in = _parsed_result.expires_in;
			q.auth_validation_data = _parsed_result;
			__quivr_log("OAuth is Valid. Expires in: " + string(_parsed_result.expires_in));
			q.authenticated = true;
		}
		break;
	
	// Response from Asking to Validate OAuth Token on Start-Up ===========================================================================
	case QUIVR_HTTP_TYPE.validate_on_startup:
		var _parsed_result = json_parse(_result);
		
		// Check for Invalid Access Token
		if (variable_struct_exists(_parsed_result, "status") && _parsed_result.status == 401) { 
			quivr_remove_auth_data();
			
		} else {
			q.auth_key_expires_in = _parsed_result.expires_in;
			q.auth_validation_data = _parsed_result;
			__quivr_log("OAuth is Valid. Expires in: " + string(_parsed_result.expires_in));
			q.authenticated = true;
		
			// Fetch Authenticated users user data
			__quivr_log("Fetching authenticated user data...");
			quivr_fetch_user();
		}

		break;
		
	// Response is Confirmation that Auth Token has been revoked ==========================================================================
	case QUIVR_HTTP_TYPE.revoke:
		__quivr_log("OAuth token has been revoked!");
		quivr_remove_auth_data();
		break;
		
	// Remove id from active_http_requests
	ds_map_delete(q.active_http_requests, _id);
	}

}


function __quivr_validate_auth_token(_is_startup = false){
	var q = o_quivr;
	q.last_validated = current_time;
	
	var _header = ds_map_create();
	ds_map_add(_header, "Authorization", "Bearer " + q.auth_key);
	var _req = http_request("https://id.twitch.tv/oauth2/validate", "GET", _header, "");
	ds_map_destroy(_header);
	
	if (_is_startup){
		ds_map_add(q.active_http_requests, _req, {request_type : QUIVR_HTTP_TYPE.validate_on_startup});
	} 
	else {
		ds_map_add(q.active_http_requests, _req, {request_type : QUIVR_HTTP_TYPE.validate});
	}
}


function __quivr_generate_temp_user_data(){
	return {
		"id":"",
		"login":"",
		"display_name":"loading...",
		"type":"",
		"broadcaster_type":"",
		"description":"loading...",
		"profile_image_url":"",
		"view_count":"loading...",
		"created_at":"loading...",
		profile_image : QUIVR_LOADING_SPRITE
	};
}
