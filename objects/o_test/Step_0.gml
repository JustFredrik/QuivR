/// @description Insert description here
// You can write your code in this editor


if quivr_is_authenticated() {

	if keyboard_check_pressed(ord("R")){
		quivr_revoke_auth();
	}


	if keyboard_check_pressed(ord("A")){
		quivr_fetch_user();
	}
	
	if keyboard_check_pressed(ord("C")){
		quivr_chat_connect();
	}
	
	if keyboard_check_pressed(ord("V")){
		var _user = quivr_get_auth_user_data();
		__quivr_send_message_irc("JOIN #" + string(_user.login));
	}
	
	if keyboard_check_pressed(ord("H")){
		var _user = quivr_get_auth_user_data();
		__quivr_send_message_irc("PRIVMSG #semiwork :Hey hey! This is sent from inside GameMaker with my wip Twitch API library!");
	}

}

if keyboard_check_pressed(vk_space){
	quivr_auth();	
}



if keyboard_check_pressed(ord("W")){
	quivr_clear_local_data();
}

if keyboard_check_pressed(ord("G")){
	quivr_cfg_set_store_auth_key_locally( !quivr_cfg_get_store_auth_key_locally());
}

