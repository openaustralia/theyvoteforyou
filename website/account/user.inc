<?php

$feedback = '';

include "quick.inc";

/*

create table pw_dyn_user (
user_id int not null auto_increment primary key,
user_name text,
real_name text,
email text,
password text,
remote_addr text,
confirm_hash text,
is_confirmed int not null default 0,
is_newsletter int not null default 1
);

*/

function user_login($user_name,$password) {
	global $feedback, $LOGGED_IN;

	if (!$user_name || !$password) {
		$feedback .=  ' Please enter your user name and password. ';
		return false;
	} else {
		$user_name=strtolower($user_name);
		$password=strtolower($password);
		$sql="SELECT * FROM pw_dyn_user WHERE user_name='$user_name' AND password='". md5($password) ."'";
		$result=db_query($sql);
		if (!$result || db_numrows($result) < 1){
			$feedback .=  ' User not found or password incorrect. ';
			return false;
		} else {
			if (db_result($result,0,'is_confirmed') == '1') {
				user_set_tokens($user_name);
                                $LOGGED_IN = true;
				$feedback .=  ' You are now logged in.';
				return true;
			} else {
				$feedback .=  ' You haven\'t confirmed your account yet.  Please check your email. ';
				return false;
			}
		}
	}
}

function user_logout() {
        global $LOGGED_IN;
        $LOGGED_IN = false;
	setcookie('user_name','',(time()+2592000),'/','',0);
	setcookie('id_hash','',(time()+2592000),'/','',0);
}

function user_set_tokens($user_name_in) {
	global $hidden_hash_var,$user_name,$id_hash;
	if (!$user_name_in) {
		$feedback .=  ' User name missing when setting tokens. ';
		return false;
	}
	$user_name=strtolower($user_name_in);
	$id_hash= md5($user_name.$hidden_hash_var);

	setcookie('user_name',$user_name,(time()+2592000),'/','',0);
	setcookie('id_hash',$id_hash,(time()+2592000),'/','',0);
}

function user_confirm($hash,$email) {
	/*
		Call this function on the user confirmation page,
		which they arrive at when the click the link in the
		account confirmation email
	*/

	global $feedback,$hidden_hash_var;

	//verify that they didn't tamper with the email address
	$new_hash=md5($email.$hidden_hash_var);
	if ($new_hash && ($new_hash==$hash)) {
		//find this record in the db
		$sql="SELECT * FROM pw_dyn_user WHERE confirm_hash='$hash'";
		$result=db_query($sql);
		if (!$result || db_numrows($result) < 1) {
			$feedback .= ' Hash not found. ';
			return false;
		} else {
			//confirm the email and set account to active
			$feedback .= ' New user account confirmed - you are now logged in. ';
			user_set_tokens(db_result($result,0,'user_name'));
			$sql="UPDATE pw_dyn_user SET email='$email',is_confirmed='1' WHERE confirm_hash='$hash'";
			$result=db_query($sql);
			return true;
		}
	} else {
		$feedback .= ' Hash invalid - update failed. ';
		return false;
	}
}

function user_change_password ($new_password1,$new_password2,$change_user_name,$old_password) {
	global $feedback;
	//new passwords present and match?
	if ($new_password1 && ($new_password1==$new_password2)) {
		//is this password long enough?
		if (account_pwvalid($new_password1)) {
			//all vars are present?
			if ($change_user_name && $old_password) {
				//lower case everything
				$change_user_name=strtolower($change_user_name);
				$old_password=strtolower($old_password);
				$new_password1=strtolower($new_password1);
				$sql="SELECT * FROM pw_dyn_user WHERE user_name='$change_user_name' AND password='". md5($old_password) ."'";
				$result=db_query($sql);
				if (!$result || db_numrows($result) < 1) {
					$feedback .= ' User not found or bad password. '.db_error();
					return false;
				} else {
					$sql="UPDATE pw_dyn_user SET password='". md5($new_password1). "' ".
						"WHERE user_name='$change_user_name' AND password='". md5($old_password). "'";
					$result=db_query($sql);
					if (!$result || db_affected_rows($result) < 1) {
						$feedback .= ' Nothing changed! '.db_error();
						return false;
					} else {
						$feedback .= ' Password changed.';
						return true;
					}
				}
			} else {
				$feedback .= ' You must provide both your user name and old password. ';
				return false;
			}
		} else {
			$feedback .= ' New passwords doesn\'t meet criteria. ';
			return false;
		}
	} else {
		return false;
		$feedback .= ' New passwords must match. ';
	}
}

function user_lost_password ($email,$user_name) {
	global $feedback,$hidden_hash_var;
	if ($email && $user_name) {
		$user_name=strtolower($user_name);
		$sql="SELECT * FROM pw_dyn_user WHERE user_name='$user_name' AND email='$email'";
		$result=db_query($sql);
		if (!$result || db_numrows($result) < 1) {
			//no matching user found
			$feedback .= ' Incorrect user name or email address. ';
			return false;
		} else {
			//create a secure, new password
			$new_pass=strtolower(substr(md5(time().$user_name.$hidden_hash_var),1,14));

			//update the database to include the new password
			$sql="UPDATE pw_dyn_user SET password='". md5($new_pass) ."' WHERE user_name='$user_name'";
			$result=db_query($sql);

			//send a simple email with the new password
			mail ($email,'Public Whip Password Reset','Your password '.
				'has been reset to: '.$new_pass,'From: noreply@publicwhip.org.uk');
			$feedback .= ' Your new password has been emailed to you. ';
			return true;
		}
	} else {
		$feedback .= ' Enter a user name and email address. ';
		return false;
	}
}

function user_change_email ($password1,$new_email,$user_name) {
	global $feedback,$hidden_hash_var;
	if (validate_email($new_email)) {
		$hash=md5($new_email.$hidden_hash_var);
		//change the confirm hash in the db but not the email - 
		//send out a new confirm email with a new hash
		$user_name=strtolower($user_name);
		$password1=strtolower($password1);
		$sql="UPDATE pw_dyn_user SET confirm_hash='$hash' WHERE user_name='$user_name' AND password='". md5($password1) ."'";
		$result=db_query($sql);
		if (!$result || db_affected_rows($result) < 1) {
			$feedback .= ' Incorrect user name or password. ';
			return false;
		} else {
			$feedback .= ' Confirmation sent. ';
			user_send_confirm_email($new_email,$hash,$user_name);
			return true;
		}
	} else {
		$feedback .= ' New email address appears invalid. ';
		return false;
	}
}

function user_send_confirm_email($email,$hash, $user) {
	/*
		Used in the initial registration function
		as well as the change email address function
	*/

	$message = "Thank you for registering with the Public Whip!".
		"\nSimply follow this link to confirm your registration: ".
		"\n\nhttp://www.publicwhip.org.uk/account/confirm.php?hash=$hash&email=". urlencode($email).
		"\n\nOnce you have confirmed, you will in future receive the".
                "\nat most fortnightly Public Whip newsletter.".
                "\n\nYour username is $user, email address $email.".
                "\nIf you would not like to receive the newsletter, you can".
                "\njust delete this email.  For more information about".
                "\nthe project visit www.publicwhip.org.uk.";
	mail ($email,'Public Whip Registration Confirmation',$message,'From: noreply@publicwhip.org.uk');
}

function user_register($user_name,$password1,$password2,$email,$real_name) {
	global $feedback,$hidden_hash_var;
	//all vars present and passwords match?
	if ($user_name && $password1 && $password1==$password2 && $email && validate_email($email)) {
		//password and name are valid?
		if (account_namevalid($user_name) && account_pwvalid($password1)) {
			$user_name=strtolower($user_name);
			$password1=strtolower($password1);

			//does the name exist in the database?
			$sql="SELECT * FROM pw_dyn_user WHERE user_name='$user_name'";
			$result=db_query($sql);
			if ($result && db_numrows($result) > 0) {
				$feedback .=  'Sorry, that user name has already been used.';
				return false;
			} else {
				//create a new hash to insert into the db and the confirmation email
				$hash=md5($email.$hidden_hash_var);
				$sql="INSERT INTO pw_dyn_user (user_name,real_name,password,email,remote_addr,confirm_hash,is_confirmed) ".
					"VALUES ('$user_name','$real_name','". md5($password1) ."','$email','$GLOBALS[REMOTE_ADDR]','$hash','0')";
				$result=db_query($sql);
				if (!$result) {
					$feedback .= ' Trouble with the database. '.db_error();
					return false;
				} else {
					//send the confirm email
					user_send_confirm_email($email,$hash,$user_name);
					$feedback .= ' You have successfully registered.  Check your email for a confirmation message.  Follow the link in the email to confirm your account.';
					return true;
				}
			}
		} else {
			$feedback .=  ' Your account name or password are not valid. ';
			return false;
		}
	} else {
		$feedback .=  ' Please fill in your user name, matching passwords, and provide a valid email address.';
		return false;
	}
}

function user_getid() {
	global $G_USER_RESULT;
	//see if we have already fetched this user from the db, if not, fetch it
	if (!$G_USER_RESULT) {
		$G_USER_RESULT=db_query("SELECT * FROM pw_dyn_user WHERE user_name='" . user_getname() . "'");
	}
	if ($G_USER_RESULT && db_numrows($G_USER_RESULT) > 0) {
		return db_result($G_USER_RESULT,0,'user_id');
	} else {
		return false;
	}
}

function user_getrealname() {
	global $G_USER_RESULT;
	//see if we have already fetched this user from the db, if not, fetch it
	if (!$G_USER_RESULT) {
		$G_USER_RESULT=db_query("SELECT * FROM pw_dyn_user WHERE user_name='" . user_getname() . "'");
	}
	if ($G_USER_RESULT && db_numrows($G_USER_RESULT) > 0) {
		return db_result($G_USER_RESULT,0,'real_name');
	} else {
		return false;
	}
}

function user_getemail() {
	global $G_USER_RESULT;
	//see if we have already fetched this user from the db, if not, fetch it
	if (!$G_USER_RESULT) {
		$G_USER_RESULT=db_query("SELECT * FROM pw_dyn_user WHERE user_name='" . user_getname() . "'");
	}
	if ($G_USER_RESULT && db_numrows($G_USER_RESULT) > 0) {
		return db_result($G_USER_RESULT,0,'email');
	} else {
		return false;
	}
}

function user_getnewsletter() {
	global $G_USER_RESULT;
	//see if we have already fetched this user from the db, if not, fetch it
	if (!$G_USER_RESULT) {
		$G_USER_RESULT=db_query("SELECT * FROM pw_dyn_user WHERE user_name='" . user_getname() . "'");
	}
	if ($G_USER_RESULT && db_numrows($G_USER_RESULT) > 0) {
		if (db_result($G_USER_RESULT,0,'is_newsletter'))
                    return true;
                else
                    return false;
	} else {
		return false;
	}
}

function user_changenewsletter($newsletter) {
        global $feedback;
        if ($newsletter)
            $newsletter = 1;
        else
            $newsletter = 0;
        $result=db_query("UPDATE pw_dyn_user SET is_newsletter='" . $newsletter . "' WHERE user_name='" . user_getname() . "'");
	if ($result) {
                $feedback .= " Newsletter setting changed. ";
		return true;
	} else {
                $feedback .= " Error writing to database. ". db_error();
		return false;
	}
}
function user_getname() {
	if (user_isloggedin()) {
		return $GLOBALS['user_name'];
	} else {
		//look up the user some day when we need it
		return ' Not logged in. ';
	}
}

function account_pwvalid($pw) {
	global $feedback;
	if (strlen($pw) < 6) {
		$feedback .= " Password must be at least 6 characters. ";
		return false;
	}
	return true;
}

function account_namevalid($name) {
	global $feedback;
	// no spaces
	if (strrpos($name,' ') > 0) {
		$feedback .= " There cannot be any spaces in the login name. ";
		return false;
	}

	// must have at least one character
	if (strspn($name,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ") == 0) {
		$feedback .= "There must be at least one character.";
		return false;
	}

	// must contain all legal characters
	if (strspn($name,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
		!= strlen($name)) {
		$feedback .= " Please only use the alphabet, dash and underscore in your username. ";
		return false;
	}

	// min and max length
	if (strlen($name) < 5) {
		$feedback .= " Name is too short. It must be at least 5 characters. ";
		return false;
	}
	if (strlen($name) > 15) {
		$feedback .= "Name is too long. It must be less than 15 characters.";
		return false;
	}

	// illegal names
	if (eregi("^((root)|(bin)|(daemon)|(adm)|(lp)|(sync)|(shutdown)|(halt)|(mail)|(news)"
		. "|(uucp)|(operator)|(games)|(mysql)|(httpd)|(nobody)|(dummy)"
		. "|(www)|(cvs)|(shell)|(ftp)|(irc)|(debian)|(ns)|(download))$",$name)) {
		$feedback .= "Name is reserved.";
		return 0;
	}
	if (eregi("^(anoncvs_)",$name)) {
		$feedback .= "Name is reserved for CVS.";
		return false;
	}

	return true;
}

function validate_email ($address) {
	return (ereg('^[-!#$%&\'*+\\./0-9=?A-Z^_`a-z{|}~]+'. '@'. '[-!#$%&\'*+\\/0-9=?A-Z^_`a-z{|}~]+\.' . '[-!#$%&\'*+\\./0-9=?A-Z^_`a-z{|}~]+$', $address));
}

?>
