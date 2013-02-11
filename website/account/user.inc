<?php

require_once $toppath . 'auth.inc';

$feedback = '';

if (!defined('HIDDEN_HASH_VAR')) {
    trigger_error("ERROR: include config.php first, and make sure it has values in", E_USER_ERROR);
}

if (!function_exists("user_isloggedin"))
{
    unset($LOGGED_IN);

    function user_isloggedin() {
            global $user_name,$id_hash,$LOGGED_IN;

            if (!$user_name) {
                $user_name=mysql_real_escape_string($_COOKIE["user_name"]);
            }
            
            $id_hash=mysql_real_escape_string($_COOKIE["id_hash"]);

            //have we already run the hash checks? 
            //If so, return the pre-set var
            if (isset($LOGGED_IN)) {
                if ($LOGGED_IN) {
                  return $LOGGED_IN;
                }
            }
            if ($user_name && $id_hash) {
                    $hash=md5($user_name.HIDDEN_HASH_VAR);
                #    print "hash $hash idhash $id_hash";
                    if ($hash == $id_hash) {
                            $LOGGED_IN=true;
                            return true;
                    } else {
                            $LOGGED_IN=false;
                            return false;
                    }
            } else {
                    $LOGGED_IN=false;
                    return false;
            }
    }
}

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
	global $user_name,$id_hash;
	if (!$user_name_in) {
		$feedback .=  ' User name missing when setting tokens. ';
		return false;
	}
	$user_name=strtolower($user_name_in);
	$id_hash= md5($user_name.HIDDEN_HASH_VAR);

	setcookie('user_name',$user_name,(time()+2592000),'/','',0);
	setcookie('id_hash',$id_hash,(time()+2592000),'/','',0);
}

function user_confirm($hash,$email) {
	/*
		Call this function on the user confirmation page,
		which they arrive at when the click the link in the
		account confirmation email
	*/

	global $feedback;

	//verify that they didn't tamper with the email address
	$new_hash=md5($email.HIDDEN_HASH_VAR);
	if ($new_hash && ($new_hash==$hash)) {
		//find this record in the db
		$sql="SELECT * FROM pw_dyn_user WHERE confirm_hash='$hash' order by is_confirmed";
		$result=db_query($sql);
        $return_url = db_result($result,0,'confirm_return_url');
		if (!$result || db_numrows($result) < 1) {
			$feedback .= ' Hash not found.  Found: ' . db_numrows($result);
			return false;
		} else {
			//confirm the email and set account to active
			$feedback .= ' New user account  ' . db_result($result,0,'user_name') . ' confirmed - you are now logged in. ';
			user_set_tokens(db_result($result,0,'user_name'));
			$sql="UPDATE pw_dyn_user SET email='$email',is_confirmed='1' WHERE confirm_hash='$hash'";
			$result=db_query($sql);
            $result=db_query("DELETE FROM pw_dyn_newsletter WHERE email='" . $email . "'");
            $result=db_query("INSERT INTO pw_dyn_newsletter (email, confirm, subscribed, token) values('" . $email . "', 1, now(), '".auth_random_token()."')");
	
            audit_log("Confirmed account email " . $email . " valid");
			return $return_url;
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
                        audit_log("Changed password");
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
		$feedback .= ' New passwords must match. ';
		return false;
	}
}

function user_lost_password ($email,$user_name) {
	global $feedback;
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
			$new_pass=strtolower(substr(md5(time().$user_name.HIDDEN_HASH_VAR),1,14));

			//update the database to include the new password
			$sql="UPDATE pw_dyn_user SET password='". md5($new_pass) ."' WHERE user_name='$user_name'";
			$result=db_query($sql);

			//send a simple email with the new password
                        $message = 
                                "Your password has been changed to: $new_pass".
                                "\nYour username is $user_name, email address $email.".
                                "\n\nLogin here: http://www.publicwhip.org.uk/account/settings.php".
                                "\n\nAfter login you can change your password to something memorable.";
			mail ($email,'Public Whip Password Reset',$message,'From: auto@publicwhip.org.uk');
			$feedback .= ' Your new password has been emailed to you. ';
            audit_log("Reset password, new one emailed to user " . $user_name);
			return true;
		}
	} else {
		$feedback .= ' Enter a user name and email address. ';
		return false;
	}
}

function user_change_email ($password1,$new_email,$user_name) {
	global $feedback;
	if (pw_validate_email($new_email)) {
		$hash=md5($new_email.HIDDEN_HASH_VAR);
		//change the confirm hash in the db but not the email - 
		//send out a new confirm email with a new hash
		$user_name=strtolower($user_name);
		$password1=strtolower($password1);
#                print "user $user_name pw $password1 em $new_email";
		$sql="UPDATE pw_dyn_user SET confirm_hash='$hash' WHERE user_name='$user_name' AND password='". md5($password1) ."'";
		$result=db_query($sql);
		if (!$result || db_affected_rows($result) < 1) {
			$feedback .= ' Incorrect user name or password.  ' . db_error();
			return false;
		} else {
			$feedback .= ' Confirmation email sent.  Check your new email address, and follow the link to complete the change.';
			user_send_confirm_email($new_email,$hash,$user_name);
            audit_log("Sent confirm new email " . $new_email);
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
                "\nat most monthly Public Whip newsletter and be able".
                "\nto access extra features on the website.".
                "\n\nYour username is $user, email address $email.".
                "\nIf you would not like to receive the newsletter, you can".
                "\nlog in and stop the newsletter, but still access other".
                "\nfeatures.  You can do this after confirming." .
                "\n\nFor more information on the project visit www.publicwhip.org.uk";
	mail ($email,'Public Whip registration confirmation',$message,'From: auto@publicwhip.org.uk');
}

function user_register($user_name,$password1,$password2,$email,$real_name) {
	global $feedback;
	//all vars present and passwords match?
	if (!$user_name )
        {
		$feedback .=  ' Please fill in your user name.';
		return false;
	}
	else if (!$password1 )
        {
		$feedback .=  ' Please fill in your password.';
		return false;
	}
	else if ($password1 != $password2 )
        {
		$feedback .=  ' Please enter matching passwords.';
		return false;
	}
	else if (!$email)
        {
		$feedback .=  ' Please fill in your email address.';
		return false;
	}
	else if (!pw_validate_email($email) )
        {
		$feedback .=  ' Please fill in a valid email address.';
		return false;
	}
    else {
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
				$hash=md5($email.HIDDEN_HASH_VAR);
				$sql="INSERT INTO pw_dyn_user
                                (user_name,real_name,password,email,remote_addr,confirm_hash,is_confirmed, reg_date, confirm_return_url) ".
					"VALUES ('$user_name','$real_name','".  md5($password1) ."','$email','" . getenv('REMOTE_ADDR') . "','$hash','0',NOW(),'".mysql_real_escape_string($_POST['r'])."')";
				$result=db_query($sql);
				if (!$result) {
					$feedback .= ' Trouble with the database. '.db_error();
					return false;
				} else {
					//send the confirm email
					user_send_confirm_email($email,$hash,$user_name);
					$feedback .= ' You have successfully registered.  <b>Check your email<b> for a confirmation message.  Follow the link in the email to confirm your account.';
                    audit_log("Registered new user " . $user_name . ", real " . $real_name . ", " . $email);
					return true;
				}
			}
		} else {
			$feedback .=  ' Your account name or password are not valid. ';
			return false;
		}
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

function user_getactivepolicy() {
	global $G_USER_RESULT;
	//see if we have already fetched this user from the db, if not, fetch it
	if (!$G_USER_RESULT) {
		$G_USER_RESULT=db_query("SELECT * FROM pw_dyn_user WHERE user_name='" . user_getname() . "'");
	}
	if ($G_USER_RESULT && db_numrows($G_USER_RESULT) > 0) {
		return db_result($G_USER_RESULT,0,'active_policy_id');
	} else {
		return false;
	}
}

function user_getnewsletter() {
	global $G_NEWSL_RESULT;
	//see if we have already fetched this user from the db, if not, fetch it
	if (!$G_NEWSL_RESULT) {
        $G_NEWSL_RESULT=db_query("SELECT * FROM pw_dyn_newsletter WHERE confirm AND email='" . user_getemail() . "'");
	}
	if ($G_NEWSL_RESULT && db_numrows($G_NEWSL_RESULT) > 0) {
        return true;
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
    $result=db_query("DELETE FROM pw_dyn_newsletter WHERE email='" . user_getemail() . "'");
    if ($result && $newsletter)  
        $result=db_query("INSERT INTO pw_dyn_newsletter (email, confirm, subscribed, token) values('" . user_getemail() . "', 1, now(), '".auth_random_token()."')");
	if ($result) {
                $feedback .= " Newsletter setting changed. ";
                audit_log("Changed newsletter to " . $newsletter);
		return true;
	} else {
        $feedback .= " Error writing to database. ". db_error();
		return false;
	}
}
function user_getname() {
	if (user_isloggedin()) {
		return mysql_real_escape_string($GLOBALS['user_name']);
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
		$feedback .= " There cannot be any spaces in the user name. ";
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
	if (preg_match("/^((root)|(bin)|(daemon)|(adm)|(lp)|(sync)|(shutdown)|(halt)|(mail)|(news)"
		. "|(uucp)|(operator)|(games)|(mysql)|(httpd)|(nobody)|(dummy)"
		. "|(www)|(cvs)|(shell)|(ftp)|(irc)|(debian)|(ns)|(download))$/i",$name)) {
		$feedback .= "Name is reserved.";
		return 0;
	}
	if (preg_match("/^(anoncvs_)/i",$name)) {
		$feedback .= "Name is reserved for CVS.";
		return false;
	}

	return true;
}

function pw_validate_email ($address) {
    // using > as delimiter as not in string http://uk2.php.net/manual/en/regexp.reference.delimiters.php
	return (preg_match('>^[-!#$%&\'*+\\./0-9=?A-Z^_`a-z{|}~]+'. '@'. '[-!#$%&\'*+\\/0-9=?A-Z^_`a-z{|}~]+\.' . '[-!#$%&\'*+\\./0-9=?A-Z^_`a-z{|}~]+$>', $address));
}

function login_screen()
{
    global $feedback, $toppath, $onload, $title;

    $onload = "givefocus('user_name')";
    $title = "Login to Public Whip"; 
    pw_header();

    if ($feedback) {
        print "<div class=\"error\"><h2>Login not correct,
        please try again</h2><p>$feedback</div>";
    }

    global $this_place;
    print '
        <P>
        Enter your user name and password and we\'ll set a cookie so we know you\'re logged in.
        <p>Not got a login?  <A HREF="/account/register.php?r='.
            ($_GET['r']?urlencode($_GET['r']):urlencode($this_place)).
        '">Register a new
        account</A>.  You will also receive a free email newsletter.
        <br>Lost your password? <a href="lostpass.php">Reset your password here</a>.
        <P>
        <FORM ACTION="'. $PHP_SELF .'" METHOD="POST" name=pw>
        <B>User name:</B><BR>
        <INPUT TYPE="TEXT" NAME="user_name" id="user_name" VALUE="" SIZE="15" MAXLENGTH="15">
        <P>
        <B>Password:</B><BR>
        <INPUT TYPE="password" NAME="password" VALUE="" SIZE="15" MAXLENGTH="15">
        <P>';
    if ($_GET['r']) {
        print '<INPUT TYPE="hidden" NAME="r" VALUE="'.htmlspecialchars($_GET['r']).'">';
    }
    print '<INPUT TYPE="SUBMIT" NAME="submit" VALUE="Login to Public Whip">
        </FORM>
        <P>';
    pw_footer();
}

function do_login_screen()
{
    if (!user_isloggedin())
    {
        $user_name=mysql_real_escape_string($_POST["user_name"]);
        $password=mysql_real_escape_string($_POST["password"]);
        $submit=mysql_real_escape_string($_POST["submit"]);

        if ($submit) {
            if (user_login($user_name,$password))
            {
                $feedback = "";
                return true;
            }
        }
    }
    return false;
}

function audit_log($text)
{
    $sql = "insert into pw_dyn_auditlog (user_id, event_date, event, remote_addr)
                values ('" . user_getid() . "', NOW(), '" . mysql_real_escape_string($text) . "', '" . getenv('REMOTE_ADDR') . "')";
    $result=db_query($sql);
    if (!$result) 
        print "Error writing to audit log: " . db_error();
}
	
?>
