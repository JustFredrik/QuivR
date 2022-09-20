/// @description Insert description here
// You can write your code in this editor

if keyboard_check_pressed(vk_space){
	quivr_auth();	
}

if keyboard_check_pressed(ord("A")){
	quivr_fetch_user();
}

if keyboard_check_pressed(ord("W")){
	quivr_clear_local_data();
}

if keyboard_check_pressed(ord("G")){
	quivr_cfg_set_store_auth_key_locally( !quivr_cfg_get_store_auth_key_locally());
}

if keyboard_check_pressed(ord("R")){
	quivr_revoke_auth();
}
