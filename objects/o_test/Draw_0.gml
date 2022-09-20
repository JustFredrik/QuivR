/// @description Insert description here
// You can write your code in this editor

	var _user = quivr_get_auth_user_data();
	
	draw_text(64+8,32, _user.display_name);
	if quivr_auth_user_is_loaded(){
		draw_sprite_ext(_user.profile_image, current_time / 60, 32, 32, 32/300, 32/300, 0, c_white, 1.0);
	} 
	else {
		draw_sprite_ext(_user.profile_image, current_time / 60, 32, 32, 0.5, 0.5, 0, c_white, 1.0);
	}
