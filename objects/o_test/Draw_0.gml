/// @description Insert description here
// You can write your code in this editor
	
	draw_text(128, 128, quivr_is_authenticated() );
	
	var _user = quivr_get_auth_user_data();

	

	if quivr_auth_user_is_loaded(){
		draw_text(64+8,32, _user.display_name);
		draw_sprite_ext(_user.profile_image, current_time / 60, 32, 32, 32/300, 32/300, 0, c_white, 1.0);
	} 
	else {
		draw_sprite_ext(_user.profile_image, current_time / 60, 32, 32, 0.5, 0.5, 0, c_white, 1.0);
	}
