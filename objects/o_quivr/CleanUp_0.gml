
ds_map_destroy(active_http_requests);



var _path;
// Store Auth key locally obscured
if (auth_key != -1){
	_path = working_directory + QUIVR_AUTH_KEY_PATH;
	file_delete(_path);	
	
	if config.store_auth_key_locally {
		var _file = file_text_open_write(_path);
		file_text_write_string(_file, string(base64_encode(auth_key)));
		file_text_close(_file);
	}
}

// Save Config settings
_path = working_directory + QUIVR_CONFIG_PATH;
file_delete(_path);	
var _file = file_text_open_write(_path);
file_text_write_string(_file, json_stringify(config));
file_text_close(_file);