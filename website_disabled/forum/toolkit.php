<?php

// PHPBB Admin ToolKit, v2.1b - Starfoxtj (starfoxtj@yahoo.com)
// Copyright 2007 - Starfoxtj
// This script is NOT released under the GPL:



/*****************************************************************************************************


By using this script you agree to the following:


1. You may modify any portion of this script for personal/business use. This includes changing the
   look, style, messages, functions, behavior etc. Note that any modifications outside of the standard
   configuration options may negatively affect the security of this script if the modification is not
   written properly and securely.
   Note: If the script has been modified, I ask that you at least retain the toolkit name, and
   my name (Starfoxtj), as a link to: http://starfoxtj.no-ip.com/phpbb/uploadtoolkit on the header
   or footer of every page. You are not required to list this information, but by removing it you may
   be forfeiting your support for this product. (Similar to the phpbb copyright agreement)
2. Ownership of this script remains with Starfoxtj regardless of how this script was acquired.
3. You may NOT sell any portion of this script, even if it is contained within another package
   without prior consent from Starfoxtj.
4. You may NOT hold Starfoxtj liable for any direct or indirect consequences of using this script.
   Many hours have been spent ensuring that this script is as secure as possible. However nothing
   can be 100% guaranteed.
   If a security hole has been found, please contact me immediately at: starfoxtj@yahoo.com


5. You  MAY distribute this script stand alone, or with another package without any prior permission
   at no charge. You may NOT however, distribute this script if any modifications have been made
   without the consent of Starfoxtj. Meaning, only the unmodified original may be freely distributed
   (at no charge).

   I personally recommended you only download this script from:
	http://starfoxtj.no-ip.com/phpbb/toolkit

   If the script was downloaded form another location, it IS possible that it may have been altered.


******************************************************************************************************/


// You may set a password here if you would rather not use the toolkit_config.php

$use_toolkit_config_file = 'yes';			// Change this to 'No' to set the password in the toolkit.php itself like in previous releases
$use_hashed_in_file_passwords = 'no';			// Change this if you want to use hashed admin/mod passwords specified in the toolkit (the toolkit_config.php file will use hashed passwords regardless)
$adminpassword = 'ENTER_ADMIN_PASSWORD_HERE';		// Note: I HIGHLY recommend using a password at least 16 characters long!
$modpassword = 'ENTER_MOD_PASSWORD_HERE';		// Leave blank to disable mod login


// Option 1: Allow Mods to Ban/UnBan Users?
$modban = 'yes'; // 'yes' : 'no'


// Option 2: Allow Mods to Change User Post Count?
$modpost = 'no'; // 'yes' : 'no'


// Option 3: Allow Mods to Change User Ranks?
$modrank = 'yes'; // 'yes' : 'no'


// Option 4: Allow Mods to Delete Users?
$moddelete = 'no'; // 'yes' : 'no'


// Option 5: Update check URLs
// Note: To disable checking for updates for phpbb, set the phpbb URL to 'none'
// Note: To disable checking for updates for this toolkit, set the toolkit URL to 'none'
// The default phpbb url is: http://www.phpbb.com/updatecheck/20x.txt
// The default toolkit url is: http://starfoxtj.no-ip.com/phpBB/toolkit/updatecheck/2.x.txt
$update_url['phpbb'] = 'http://www.phpbb.com/updatecheck/20x.txt';
$update_url['toolkit'] = 'http://starfoxtj.no-ip.com/phpBB/toolkit/updatecheck/2.x.txt';





//  Lets begin the coding!
//
// (CHANGE INFORMATION AFTER THIS LINE WITH CAUTION!)
//
//
//




session_start();

$_SESSION['toolkitversion'] = '2.1b';
$_SESSION['toolkit_title'] = '<b><a href="index.php"><font size="5" color="#000000">PHPBB Admin ToolKit '.$_SESSION['toolkitversion'].'</b></font></a><font size="5"> - <a href="http://starfoxtj.no-ip.com/phpbb/toolkit" target="_blank">Starfoxtj</a></font>';
$_SESSION['toolkit_title_nversion'] = '<b><a href="index.php"><font size="5" color="#000000">PHPBB Admin ToolKit</b></font></a><font size="5"> - <a href="http://starfoxtj.no-ip.com/phpbb/toolkit" target="_blank">Starfoxtj</a></font>';
$_SESSION['copyrightfooter'] = '<br /><center><hr width="90%"><font size="2">PHPBB Admin ToolKit '.$_SESSION['toolkitversion'].' © 2007 - <a href="mailto:starfoxtj@yahoo.com">Starfoxtj</a></font></center>';

$phpbb_root_path = './';

// Set global information and start db access

if( file_exists( 'config.php' ) )

   {

	include( 'config.php' );

	if( $dbms == 'mysql' || $dbms == 'mysql4' )
	
	   { 
	
		$db = @mysql_connect("$dbhost", "$dbuser", "$dbpasswd")
		or die( 'Could not connect to database: '.mysql_error() );
	
		@mysql_select_db($dbname)
		or die( 'Could not select database: '.mysql_error() );
	
	   }

	else

	   {

		die( 'This toolkit is only compatible with MySQL databases.' );

	   }
   }


// Define Some Variables

$index = $_SERVER['PHP_SELF'];
$domain = $_SERVER['SERVER_NAME'];
$full_domain = 'http://'.$domain;

if( file_exists( 'config.php' ) )

   {

	$phpbb_auth_access = $table_prefix."auth_access";
	$phpbb_config = $table_prefix."config";
	$phpbb_banlist = $table_prefix."banlist";
	$phpbb_users = $table_prefix."users";
	$phpbb_ranks = $table_prefix."ranks";
	$phpbb_vote_voters = $table_prefix."vote_voters";
	$phpbb_user_group = $table_prefix."user_group";
	$phpbb_groups = $table_prefix."groups";
	$phpbb_posts = $table_prefix."posts";
	$phpbb_posts_text = $table_prefix."posts_text";
	$phpbb_topics = $table_prefix."topics";
	$phpbb_forums = $table_prefix."forums";
	$phpbb_themes = $table_prefix."themes";
	$phpbb_themes_name = $table_prefix."themes_name";
	$phpbb_sessions = $table_prefix."sessions";
	$phpbb_sessions_keys = $table_prefix."sessions_keys";
	$phpbb_topics_watch = $table_prefix."topics_watch";
	$phpbb_privmsgs = $table_prefix."privmsgs";
	$phpbb_privmsgs_text = $table_prefix."privmsgs_text";

	$phpbb_version_result = mysql_query("SELECT * FROM $phpbb_config WHERE config_name='version'")
	or die( 'MySQL Error: '.mysql_error() );
	$myrow_phpbb_version = mysql_fetch_array($phpbb_version_result);
	$phpbb_version = $myrow_phpbb_version['config_value'];

   }

$script_folder = substr( $index, 1, -(strlen( end( explode( '/', $index ) ) ) + 1 ) );


// Set the errors to only display one of each error

if( isset( $_SESSION['errors']['index'] ) )

   {

	$_SESSION['errors']['index'] = array_unique( $_SESSION['errors']['index'] );

   }

if( isset( $_SESSION['errors']['edituser'] ) )

   {

	$_SESSION['errors']['edituser'] = array_unique( $_SESSION['errors']['edituser'] );

   }

if( isset( $_SESSION['errors']['config'] ) )

   {

	$_SESSION['errors']['config'] = array_unique( $_SESSION['errors']['config'] );

   }



/////////////////////////////////////////
//
//	Check and Create config.php
//

if( !file_exists( 'config.php' ) )

   { //-.2-a 


	if( isset( $_POST['configphp_setup'] ) )

	   { //-.1-a.1 


		if( $_POST['dbhost'] == '' ||
		$_POST['dbuser'] == '' ||
		$_POST['dbpasswd'] == '' || 
		$_POST['dbname'] == '' )

		   {

			$_SESSION['configphp_error'] = '<b>Error:</b> All fields must be filled in.';
			header( "Location: $index" );
			die();

		   }

		@chmod( "../$script_folder", 0777 )
		or die( "Could not CHMOD $script_folder folder to create config.php!<br />
		You can either change the CHMOD settings manually to 777, or create the config.php file by copying the following information
		into notepad and specifying the database settings. Then save it as \"config.php\" and upload it to your $script_folder folder.<br /><br />
		Note: This assumes you are using MySQL4, if you are using MySQL3, replace \"mysql4\" with \"mysql\".<br /><br />

		<table border=\"0\" width=\"400\" cellpadding=\"5\"; style=\"border-top: black 1px solid; border-right: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid\" bgcolor=\"#f5f5f5\">
		 <tr>
		
			<td>
				<b>&lt;?php<br /><br />
				
				// phpBB 2.x auto-generated config file<br />
				// Do not change anything in this file!<br /><br />
				
				\$dbms = 'mysql4';<br /><br />
				
				\$dbhost = '<font color=\"#ff0000\">Your Host</font>';<br />
				\$dbname = '<font color=\"#ff0000\">Your Database Name</font>';<br />
				\$dbuser = '<font color=\"#ff0000\">Your Username</font>';<br />
				\$dbpasswd = '<font color=\"#ff0000\">Your Password</font>';<br /><br />
				
				\$table_prefix = 'phpbb_';<br /><br />
				
				define('PHPBB_INSTALLED', true);<br /><br />
				
				?&gt;</b>
		
			</td>
		
		 </tr>
		</table>" );


		@touch( 'config.php' )
		or die( "Could not create config.php!<br />
		You can either change the CHMOD settings manually to 777, or create the config.php file by copying the following information
		into notepad and specifying the database settings. Then save it as \"config.php\" and upload it to your $script_folder folder.<br /><br />
		Note: This assumes you are using MySQL4, if you are using MySQL3, replace \"mysql4\" with \"mysql\".<br /><br />

		<table border=\"0\" width=\"400\" cellpadding=\"5\"; style=\"border-top: black 1px solid; border-right: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid\" bgcolor=\"#f5f5f5\">
		 <tr>
		
			<td>
				<b>&lt;?php<br /><br />
				
				// phpBB 2.x auto-generated config file<br />
				// Do not change anything in this file!<br /><br />
				
				\$dbms = 'mysql4';<br /><br />
				
				\$dbhost = '<font color=\"#ff0000\">Your Host</font>';<br />
				\$dbname = '<font color=\"#ff0000\">Your Database Name</font>';<br />
				\$dbuser = '<font color=\"#ff0000\">Your Username</font>';<br />
				\$dbpasswd = '<font color=\"#ff0000\">Your Password</font>';<br /><br />
				
				\$table_prefix = 'phpbb_';<br /><br />
				
				define('PHPBB_INSTALLED', true);<br /><br />
				
				?&gt;</b>
		
			</td>
		
		 </tr>
		</table>" );





		$fp = fopen( 'config.php', "w" )
		or die ("The file config.php exists but could not be opened. Check the file permissions." );

		$dbms = $_POST['dbms'];
		$dbhost = $_POST['dbhost'];
		$dbuser = $_POST['dbuser'];
		$dbpasswd = $_POST['dbpasswd'];
		$dbname = $_POST['dbname'];
		$table_prefix = $_POST['table_prefix'];

		fwrite( $fp, "<?php


// phpBB 2.x auto-generated config file
// Do not change anything in this file!

\$dbms = '$dbms';

\$dbhost = '$dbhost';
\$dbname = '$dbname';
\$dbuser = '$dbuser';
\$dbpasswd = '$dbpasswd';

\$table_prefix = '$table_prefix';

define('PHPBB_INSTALLED', true);

?>" );

		fclose( $fp );

		chmod( "../$script_folder", 0755 );

		header( "Location: $index" );
		die();



	   } //-.1-a.1 

	else

	   { //-.1-a.2 

	
		session_destroy();
	
		?>
	
		<html>
		<head>
		<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>
	
		<SCRIPT LANGUAGE="JavaScript">
		function placeFocus() {
		if (document.forms.length > 0) {
		var field = document.forms[0];
		for (i = 1; i < field.length; i++) {
		if ((field.elements[i].name == "dbhost") || (field.elements[i].type == "textarea") || (field.elements[i].type.toString().charAt(0) == "s")) {
		document.forms[0].elements[i].focus();
		break;
			 }
		      }
		   }
		}
		</script>
		
		</head>
	
		<body link="#0000ff" vlink="#0000ff" alink="#0000ff" OnLoad="placeFocus()">
	
		<center>
		<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		<tr><td><div align="center"><?php echo $_SESSION['toolkit_title']; ?></div></td></tr>
		</table><br />
		</center>
	
		<center>
	
		<font size="4">PHPBB Admin ToolKit: Create Config.php file</font>
		<br /><br />

		Config.php file not found! You may create a new one by entering in the information below:<br /><br />

		<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		 <tr>
	
			<td>
	
			<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
		
			<table border="0" cellpadding="5" cellspacing="0">

			 <tr>
		
				<td>
		
				Database Type:
		
				</td>
		
				<td>
		
				<select name="dbms">
				<option value="mysql">MySQL 3.x</option>
				<option value="mysql4" selected>MySQL 4.x</option>
				<option value="postgres">PostgreSQL 7.x</option>
				<option value="mssql">MS SQL Server 7/2000</option>
				<option value="msaccess">MS Access [ ODBC ]</option>
				<option value="mssql-odbc">MS SQL Server [ ODBC ]</option></select>		
				</td>
		
			 </tr>
		
			 <tr>
		
				<td>
		
				Host:
		
				</td>
		
				<td>
		
				<input type="text" name="dbhost" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>

			 <tr>
		
				<td>
		
				Username:
		
				</td>
		
				<td>
		
				<input type="text" name="dbuser" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>
		
			 <tr>
		
				<td>
		
				Password:
		
				</td>
		
				<td>
		
				<input type="password" name="dbpasswd" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>

			 <tr>
		
				<td>
		
				Database:
		
				</td>
		
				<td>
		
				<input type="text" name="dbname" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>

			 <tr>
		
				<td>
		
				Table Prefix:
		
				</td>
		
				<td>
		
				<input type="text" name="table_prefix" value="phpbb_" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>
	
			 <tr>
		
				<td colspan="2" align="center">

				<input type="hidden" name="configphp_setup" value="1" />
		
				<br /><input TYPE="submit" VALUE="Create Config.php">
		
				</td>
		
			 </tr>
		
			</table>
		
			</form>
	
			</td>
	
		 </tr>
		</table>
		</center>
	
	
		<?php
	
		if( isset( $_SESSION['configphp_error'] ) )
	
		   {
	
			?>
	
				<center>
			<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
			 <tr>
	
				<td>
	
			<br /><br /><?php echo $_SESSION['configphp_error']; ?>
	
				</td>
	
			 </tr>
	
			</table>
	
	
			<?php		
	
		   }
	
		?>
	
		</body>
		</html>
	
	
	
		<?php


	   } //-.1-a.2 

	die();


   } //-.2-a 



/////////////////////////////////////////
//
//	Check and set fist time password
//

if( !file_exists( 'toolkit_config.php' ) && $use_toolkit_config_file == 'yes' )

   { //-.1-a 


	if( isset( $_POST['toolkitconfig_setup'] ) )

	   { //-.1-a.1 


		if( !isset( $_POST['admin_password'] ) || !isset( $_POST['admin_password_confirm'] ) )

		   {

			$_SESSION['toolkitconfig_error'] = '<b>Error:</b> Either the admin password was not specified, or the passwords did not match.';
			header( "Location: $index" );
			die();

		   }

		elseif( $_POST['admin_password']  == '' || $_POST['admin_password_confirm'] == '' )

		   {

			$_SESSION['toolkitconfig_error'] = '<b>Error:</b> Either the admin password was not specified, or the passwords did not match.';
			header( "Location: $index" );
			die();

		   }

		elseif( $_POST['admin_password']  != $_POST['admin_password_confirm'] )

		   {

			$_SESSION['toolkitconfig_error'] = '<b>Error:</b> The admin passwords do not match.';
			header( "Location: $index" );
			die();

		   }


		if( $_POST['mod_password'] != $_POST['mod_password_confirm'] )

		   {

			$_SESSION['toolkitconfig_error'] = '<b>Error:</b> The mod passwords do not match.';
			header( "Location: $index" );
			die();

		   }

		@chmod( "../$script_folder", 0777 )
		or die( "Could not CHMOD $script_folder to 777 to create toolkit_config.php!<br />
		1: Extract the toolkit.php file and open it with notepad.<br />
		2: Find \"\$use_toolkit_config_file\" on line 40.<br />
		3: Change the 'yes' to 'no'.<br />
		4: Replace both the admin and mod passwords on lines 41 and 42<br />
		5: Upload toolkit.php to your $script_folder folder." );


		@touch( 'toolkit_config.php' )
		or die( "Could not create toolkit_config.php, access denied!<br />
		Please install this script using method 2:<br /><br />
		1: Extract the toolkit.php file and open it with notepad.<br />
		2: Find \"\$use_toolkit_config_file\" on line 40.<br />
		3: Change the 'yes' to 'no'.<br />
		4: Replace both the admin and mod passwords on lines 41 and 42<br />
		5: Upload toolkit.php to your $script_folder folder." );




		$fp = fopen( 'toolkit_config.php', "w" )
		or die ("The file toolkit_config.php exists but could not be opened. Check the file permissions." );

		$version = $_SESSION['toolkitversion'];
		$adminpassword = md5( md5( $_POST['admin_password'] ) );
		$modpassword = md5( md5( $_POST['mod_password'] ) );

		fwrite( $fp, "<?php

////////////////////////////////////////////////////////////
//
// PHPBB Admin ToolKit v$version auto-generated config file.
//
// You may change the passwords in this file.

// Note: The passwords in this file are hashed for security.
// If you need to change your passwords, you can either use the MD5 Generator included
// near the bottom of the toolkit index.
// Or you can simply delete this toolkit_config.php file and run toolkit.php
// to recreate this file with the new passwords.
//
// NOTE: For security, the passwords for this toolkit have been DOUBLE hashed!
// Meaning, the password was hashed once using the md5() function, then the hash
// was hashed again using the md5() function. The code equivalent is: \$pass = md5( md5( 'password' ) );
// Because the password is double hashed, it should be almost completely uncrackable as
// a brute force/dictionary attack would have to first crack a 32 character password, THEN
// crack the result yielding the original password.
// This way, even if someone got your toolkit.config.php file it would in theory
// take the most powerful home computer over 10 years to break.
//



\$adminpassword = '$adminpassword';
\$modpassword = '$modpassword';

?>" );

		fclose( $fp );

		chmod( "../$script_folder", 0755 );

		header( "Location: $index" );
		die();



	   } //-.1-a.1 

	else

	   { //-.1-a.2 

	
		session_destroy();
	
		?>
	
		<html>
		<head>
		<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>
	
		<SCRIPT LANGUAGE="JavaScript">
		function placeFocus() {
		if (document.forms.length > 0) {
		var field = document.forms[0];
		for (i = 0; i < field.length; i++) {
		if ((field.elements[i].name == "admin_password") || (field.elements[i].type == "textarea") || (field.elements[i].type.toString().charAt(0) == "s")) {
		document.forms[0].elements[i].focus();
		break;
			 }
		      }
		   }
		}
		</script>
		
		</head>
	
		<body link="#0000ff" vlink="#0000ff" alink="#0000ff" OnLoad="placeFocus()">
	
		<center>
		<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		<tr><td><div align="center"><?php echo $_SESSION['toolkit_title']; ?></div></td></tr>
		</table><br />
		</center>
	
		<center>
	
		<font size="4">PHPBB Admin ToolKit: First Time Setup</font><br />
		
		<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		 <tr>
	
			<td>
	
			<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
		
			<table border="0" cellpadding="5" cellspacing="0">
		
			 <tr>
		
				<td>
		
				Specify Admin Password:
		
				</td>
		
				<td>
		
				<input type="password" name="admin_password" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>
		
			 <tr>
		
				<td>
		
				Confirm Admin Password:
		
				</td>
		
				<td>
		
				<input type="password" name="admin_password_confirm" lengh="20" size="20" maxlengh="255">
		
				</td>
		
			 </tr>
	
			 <tr>
		
				<td>
		
				<br />Specify ModPassword:
		
				</td>
		
				<td>
		
				<br /><input type="password" name="mod_password" lengh="20" size="20" maxlengh="255"> (Optional)
		
				</td>
		
			 </tr>
		
			 <tr>
		
				<td>
		
				Confirm Mod Password:
		
				</td>
		
				<td>
		
				<input type="password" name="mod_password_confirm" lengh="20" size="20" maxlengh="255"> (Optional)
		
				</td>
		
			 </tr>
		
			 <tr>
		
				<td colspan="2" align="center">

				<input type="hidden" name="toolkitconfig_setup" value=1 />
		
				<br /><input TYPE="submit" VALUE="   Enter   ">
		
				</td>
		
			 </tr>
		
			</table>
		
			</form>
	
			</td>
	
		 </tr>
		</table>
		</center>
	
	
		<?php
	
		if( isset( $_SESSION['toolkitconfig_error'] ) )
	
		   {
	
			?>
	
				<center>
			<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
			 <tr>
	
				<td>
	
			<br /><br /><?php echo $_SESSION['toolkitconfig_error']; ?>
	
				</td>
	
			 </tr>
	
			</table>
	
	
			<?php		
	
		   }
	
		?>
	
		</body>
		</html>
	
	
	
		<?php


	   } //-.1-a.2 

	die();


   } //-.1-a 

elseif( file_exists( 'toolkit_config.php' ) && $use_toolkit_config_file == 'yes' )

   {

	include( 'toolkit_config.php' );


   }



if( !isset( $_SESSION['user_level'] ) )

   { //-.1

	$_SESSION['user_level'] = "null";

   } //-.1


if( !isset( $_SESSION['AUTH'] ) )

   {

	$_SESSION['AUTH'] = array();

   }


// Safe SQL data function

function safe_sql( $data )

   {

	if ( get_magic_quotes_gpc() )
	
	   {
	
		$data = stripslashes( $data );
	
	   }


	if( phpversion() >= 4.3 )

	   {

		$data = mysql_real_escape_string( $data );

	   }

	else

	   {

		$data = mysql_escape_string( $data );

	   }

	
	$data = str_replace( '&', '&amp;', $data );
	$data = str_replace( '<', '&lt;', $data );
	$data = str_replace( '>', '&gt;', $data );
	
	return $data;

   }

function safe_html( $data )

   {

	$data = trim( $data );
	
	$data = str_replace( '&', '&amp;', $data );
	$data = str_replace( '<', '&lt;', $data );
	$data = str_replace( '>', '&gt;', $data );
	
	return $data;

   }

// Safe descriptions data function

function safe_desc( $data )

   {
	
	$data = str_replace( '&', '&amp;', $data );
	$data = str_replace( '<', '&lt;', $data );
	$data = str_replace( '>', '&gt;', $data );
	
	return $data;

   }

// make_time function

function make_time( $time )

   {

	// Set error value to false as no errors are generated yet

	$error = false;

	// Set vals to proper "type" (int)

	$mm = intval( $time['mm'] );
	$dd = intval( $time['dd'] );
	$yy = intval( $time['yy'] );

	$time_hh = intval( $time['time_hh'] );
	$time_mm = intval( $time['time_mm'] );
	$time_ss = intval( $time['time_ss'] );


	// Pad vals with leading zeros if single digets

	$mm = sprintf( "%02d", $mm );
	$dd = sprintf( "%02d", $dd );
	$yy = sprintf( "%02d", $yy );

	$time_hh = sprintf( "%02d", $time_hh );
	$time_mm = sprintf( "%02d", $time_mm );
	$time_ss = sprintf( "%02d", $time_ss );

	$time_ap = $time['time_ap'];



	// First check if specified date is a correct one

	if( !checkdate( $mm, $dd, $yy ) )

	   {

		$_SESSION['errors']['make_time'][] = 'You have entered an invalid date combination.';
		$error = true;
		return false;

	   }



	// Check if year is after 1970 (because thats when the timestamp starts)

	if( $yy < 1970 )

	   {

		$_SESSION['errors']['make_time'][] = 'Due to the Unix timestamp restriction, the year must not be before 1970.';
		$error = true;
		return false;

	   }



	// Now perform various checks on the time info

	if(

		(
		$time_hh > 12 ||
		$time_hh < 1  ||
		$time_mm > 60 ||
		$time_ss < 0  ||
		$time_ss > 60 ||
		$time_mm < 0
		)

		||

		(

		$time_ap != 'pm' &&
		$time_ap != 'am'

		) )

	   {

		$_SESSION['errors']['make_time'][] = 'You have entered an invalid time.';
		$error = true;
		return false;

	   }


	// Generate timestamp

	if( $time_ap == 'pm' )

	   {

		$time_hh += 12;

	   }

	if( $error == false )

	   {
		$time = mktime( $time_hh, $time_mm, $time_ss, $mm, $dd, $yy );
		return $time;

	   }

}


// Delete user core function
// Only the actual sql queries are here, the checks and options are in the delete_user() function

function delete_user_core( $user_id, $clear_posts = false, $retain_pms = false )

   {

	// Set global variables

	global $index;
	global $phpbb_version;

	global $phpbb_banlist;
	global $phpbb_user_group;
	global $phpbb_users;
	global $phpbb_groups;
	global $phpbb_posts;
	global $phpbb_posts_text;
	global $phpbb_topics;
	global $phpbb_vote_voters;
	global $phpbb_auth_access;
	global $phpbb_sessions;
	global $phpbb_sessions_keys;
	global $phpbb_privmsgs;
	global $phpbb_privmsgs_text;
	global $phpbb_topics_watch;



	// First things first, sanitize the $user_id

	$user_id = safe_sql( $user_id);


	//		
	// Obtain username and level based on user_id
	//

	$sql = "SELECT * FROM $phpbb_users WHERE user_id=$user_id LIMIT 1";

	$result = mysql_query($sql);
	$myrow = mysql_fetch_array($result);

	$username = safe_sql( $myrow['username'] );
	$user_level = safe_sql( $myrow['user_level'] );


	// Obtain first admin account to set as group mod if deleted user is a group mod (step 5)

	$sql = "SELECT * FROM $phpbb_users WHERE user_level=1 ORDER BY user_id ASC LIMIT 1";

	$result = mysql_query($sql);
	$myrow = mysql_fetch_array($result);

	$admin_id= safe_sql( $myrow['user_id'] );

	// Debug info:
	// echo '<pre>';
	// echo gettype( $myrow );
	// die( $admin_id );



	// This actually starts the delete process

	// **************************************************************
	//
	// First sql query is to collect group information about the user
	//
	// **************************************************************

	$sql = "SELECT g.group_id FROM $phpbb_user_group ug, $phpbb_groups g WHERE ug.user_id = $user_id AND g.group_id = ug.group_id AND g.group_single_user = 1";

	$result = mysql_query($sql);
	$row = mysql_fetch_array($result);
	unset( $row[0] ); // Read note directly below about this line:


	// PHPBB's $row = $db->sql_fetchrow($result); line returns an array containg the user id:
	// Array
	// (
    	// 	[group_id] => 123
	// )

	// The mqsql fetch array used in this scrip: $myrow = mysql_fetch_array($result);
	// Returns the following:
	// Array
	// (
    	//	[0] => 123
    	//	[group_id] => 123
	// )

	// Therefore I unset the $row[0] element


	// Debugging info:
	// echo '<pre>';
	// print_r( $row );
	// echo"\n\n$username";
	// die();


	// ***************************************************************************
	//
	// Second sql query sets the poster id to the anonymous account for all posts
	// First query in this section is for the $clear_posts variable
	//
	// ***************************************************************************


	//
	// This check fixes the:
	//	Error deleting user's group from groups table:
	//	Line: 1477
	//	File: /toolkit.php
	//	Query: DELETE FROM `phpbb_groups` WHERE `group_id`=
	//	MySQL Error: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '' at line 1 
	//
	// Error message that was appearing in v2.1a because the returned value of $row was not correct


	// Debug for numeric check
	/* echo '<pre>';
	var_dump( $row );

	$i = is_numeric( '2 3' );
	var_dump( $i );
	die(); */

	if( !is_numeric( $row['group_id'] ) )

	   {

		echo '<font size="4"><b>An incorrect value has been returned for group_id in the \'phpbb_groups\' table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF'].'<br /><b>User ID: </b>'.$user_id.'<br /><b>Username: </b>'.$username.'<br /><b>Details:</b> This value should be a purely numeric integer. The value returned by the database is:<br /><pre>';
		var_dump( $row );
		echo '</pre><br />Please contact Starfoxtj at <a href="http://starfoxtj.no-ip.com">http://starfoxtj.no-ip.com</a> and report this error.';
		echo '<br /><br /><b>Note: </b> The script has halted before any changes to the database were made for this specific user.<br />All other users that were deleted before <b>'.$username.'</b> were properly removed.';
		echo '<br /><br /><b>Full envoirment details:</b><br /><pre>';
		var_dump( get_defined_vars() );
		die();

	   }


	// If clear posts is set to true, replace all posts made by user to "DELETED"

	if( $clear_posts == true )

	   {

		$sql = "SELECT `post_id` FROM `$phpbb_posts` WHERE `poster_id`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
				die( '<font size="4"><b>Error selecting selecting posts to clear:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }
	
	
		// Assings the results of the above query into an array
	
		while($myrow = mysql_fetch_array($result))
	
		   {
	
			$marked_posts[] = $myrow['post_id'];
	
		   }


		// Makes mark an empty array if the user has no PMs
	
		if( !isset( $marked_posts ) )
	
		   {
	
			$marked_posts = array();
	
		   }


		// First check to see if user has any posts, if not skip replacing the posts

 		if( isset( $marked_posts ) && count( $marked_posts ) )

		   {
			
			$marked_posts = implode( ',', $marked_posts );
	
			$sql = "UPDATE `$phpbb_posts_text` SET `post_text`='DELETED' WHERE `post_id` IN ( $marked_posts )";

			// echo '<pre>';
			// echo $sql;
			// echo '<br />';
			// print_r( $marked_posts );
			// die();
	
			if( !$result = mysql_query( $sql ) )
		
			   {
		
					die( '<font size="4"><b>Error setting posts to DELETED:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
		
			   }

		   }



		// Sets the poster id to the anonymous account for all posts and replaces the username with DELETED
	
		$sql = "UPDATE `$phpbb_posts` SET `poster_id`=-1, `post_username`='DELETED' WHERE `poster_id`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
				die( '<font size="4"><b>Error setting poster id to anonymous for deleted user:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }
	   }

	else

	   {


		// Sets the poster id to the anonymous account for all posts, but retains the original username
	
		$sql = "UPDATE `$phpbb_posts` SET `poster_id`=-1, `post_username`='".str_replace( "\\'", "''", addslashes( $username ) )."' WHERE `poster_id`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
				die( '<font size="4"><b>Error setting poster id to anonymous for deleted user:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }

	   }


	// ***************************************************************************
	//
	// Third sql query sets the topic id to the anonymous account for all topics
	//
	// ***************************************************************************

	// If clear posts is set to true, replace all topics made by user to "DELETED"

	if( $clear_posts == true )

	   {

		$sql = "UPDATE `$phpbb_topics` SET `topic_title`='DELETED' WHERE `topic_poster`=$user_id";


		if( !$result = mysql_query( $sql ) )
	
		   {
	
				die( '<font size="4"><b>Error setting topics to DELETED:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }


		// Sets the topic id to the anonymous account for all topics and replaces the username with DELETED

		$sql = "UPDATE `$phpbb_topics` SET `topic_poster`=-1 WHERE `topic_poster`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
				die( '<font size="4"><b>Error setting topic id poster to anonymous for deleted user:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }
	   }

	else

	   {

	
		// Sets the poster id to the anonymous account for all posts, but retains the original username
	
		$sql = "UPDATE `$phpbb_topics` SET `topic_poster`=-1 WHERE `topic_poster`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
				die( '<font size="4"><b>Error setting topic id poster to anonymous for deleted user:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }

	   }


	// ***************************************************************************
	//
	// Fourth sql query sets the voter id to anonymous
	//
	// ***************************************************************************

	$sql = "UPDATE `$phpbb_vote_voters` SET `vote_user_id`=-1 WHERE `vote_user_id`=$user_id";

	if( !$result = mysql_query( $sql ) )

	   {

			die( '<font size="4"><b>Error setting voter ID to anonymous:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Fifth sql query collects the phpbb_groups info and assigns it to the 
	// $group_mods array where the user is a moderator
	//
	// ***************************************************************************

	$sql = "SELECT `group_id` FROM `$phpbb_groups` WHERE `group_moderator`=$user_id";

	if( !$result = mysql_query( $sql ) )

	   {

			die( '<font size="4"><b>Error selecting groups where user is a moderator:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// Assings the results of the above query into an array

	while($myrow = mysql_fetch_array($result))

	   {

		$group_mod[] = $myrow['group_id'];

	   }

	// Debugging info:
	// echo '<pre>';
	// print_r( $group_mod );
	// die();


	// If the user is a moderator for any groups, this query assigns the
	// new mod status to the oldest admin account

	if( isset( $group_mod ) && count( $group_mod ) )

	   {

		//
		// Make SURE to insert a query here to check for the first admin account to associate as the new group moderator
		// after the deleted user is deleted!
		// Done

		// $admin_id = 3; //This is a temp static admin id that will be dymamic in the final release

		$update_mod_id = implode( ',', $group_mod );
		$sql = "UPDATE `$phpbb_groups` SET `group_moderator`=$admin_id WHERE `group_moderator` IN ( $update_mod_id )";

		// Debugging info:
		// echo '<pre>';
		// echo $sql;
		// die();

		if( !$result = mysql_query( $sql ) )

		   {

			die( '<font size="4"><b>Error setting new group moderator to oldest admin:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

		   }

	   }


	// ***************************************************************************
	//
	// Sixth sql query deletes the user from the phpbb_users table
	//
	// ***************************************************************************

	$sql = "DELETE FROM `$phpbb_users` WHERE `user_id`=$user_id";

	if( !$result = mysql_query( $sql ) )

	   {

		die( '<font size="4"><b>Error deleting user from users table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Seventh sql query deletes the user from the phpbb_user_group table
	//
	// ***************************************************************************

	$sql = "DELETE FROM `$phpbb_user_group` WHERE `user_id`=$user_id";

	if( !$result = mysql_query( $sql ) )

	   {

		die( '<font size="4"><b>Error deleting user from user_group table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Eighth sql query moved to the top to check and exit if error
	//
	// ***************************************************************************

	 $sql = "DELETE FROM `$phpbb_groups` WHERE `group_id`=".$row['group_id'];

	if( !$result = mysql_query( $sql ) )

	   {

		die( '<font size="4"><b>Error deleting user\'s group from groups table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Ninth sql query deletes the user from the phpbb_auth_access table
	//
	// ***************************************************************************

	$sql = "DELETE FROM  `$phpbb_auth_access` WHERE `group_id`=".$row['group_id'];

	if( !$result = mysql_query( $sql ) )

	   {

		die( '<font size="4"><b>Error deleting user from auth_access table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Tenth sql query deletes the user from the phpbb topics watch table
	//
	// ***************************************************************************

	$sql = "DELETE FROM `$phpbb_topics_watch` WHERE `user_id`=$user_id";

	if( !$result = mysql_query( $sql ) )

	   {

		die( '<font size="4"><b>Error deleting user from topics_watch table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Eleventh sql query deletes the user from the banlist table
	//
	// ***************************************************************************

	$sql = "DELETE FROM `$phpbb_banlist` WHERE `ban_userid`=$user_id";

	if( !$result = mysql_query( $sql ) )

	   {

		die( '<font size="4"><b>Error deleting user from the banlist table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );

	   }


	// ***************************************************************************
	//
	// Twelfth sql query deletes the user from the sessions table
	//
	// ***************************************************************************

	// This delete section was added in .19, so a check is done before using it incase
	// the admin is running an older version of phpbb

	if( $phpbb_version >= 0.19 )

	   {

		$sql = "DELETE FROM `$phpbb_sessions` WHERE `session_user_id`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
			die( '<font size="4"><b>Error deleting user from the sessions table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }

	   }


	// ***************************************************************************
	//
	// Twelfth sql query deletes the user from the sessions_keys table
	//
	// ***************************************************************************

	// This delete section was added in .19, so a check is done before using it incase
	// the admin is running an older version of phpbb

	if( $phpbb_version >= '.0.19' )

	   {

		// First check if the sesssions keys table exists
		// (Since alot of .19 boards dont have it due to incomplete updates

		$sql_key_check ="SHOW TABLES LIKE '$phpbb_sessions_keys'";

		if( !$result_key_check = mysql_query( $sql_key_check ) )
	
		   {
	
				die( '<font size="4"><b>Error selecting session keys table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }


		// This section actually checks if the table exists, if not it skips
		// deleting the user from this table

		if( mysql_fetch_array($result_key_check) )
		
		   {
		

			$sql = "DELETE FROM `$phpbb_sessions_keys` WHERE `user_id`=$user_id";
		
			if( !$result = mysql_query( $sql ) )
		
			   {
		
				die( '<font size="4"><b>Error deleting user from the sessions_keys table:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
		
			   }

		   }

	   }


	// ***************************************************************************
	//
	// The final sql query collets the to/from PMs with the user's id & deletes them
	//
	// ***************************************************************************

	// If retain_pms is set to true, change PM author to anonymous instead of deleting them

	if( $retain_pms == true )

	   {

		// This query sets the from_user_id to the anonymous account so the PMs dont have to be deleted

		$sql = "UPDATE `$phpbb_privmsgs` SET `privmsgs_from_userid`=-1 WHERE `privmsgs_from_userid`=$user_id";

		if( !$result = mysql_query( $sql ) )
	
		   {
	
			die( '<font size="4"><b>Error setting from PM from_user_id to anonymous:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }


		// This query sets the to_user_id to the anonymous account so the PMs dont have to be deleted

		$sql = "UPDATE `$phpbb_privmsgs` SET `privmsgs_to_userid`=-1 WHERE `privmsgs_to_userid`=$user_id";

	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
			die( '<font size="4"><b>Error setting from PM to_user_id to anonymous:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }

	   }

	else

	   {
	
		$sql = "SELECT `privmsgs_id` FROM `$phpbb_privmsgs` WHERE `privmsgs_from_userid`=$user_id OR `privmsgs_to_userid`=$user_id";
	
		if( !$result = mysql_query( $sql ) )
	
		   {
	
			die( '<font size="4"><b>Error selecting PMs for the user:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
	
		   }
	
	
			// Debugging info:
			// echo "<br />$sql<br />";
	
	
		// This section marks and assigns the resulting PMs into the $marked array
	
		while($myrow = mysql_fetch_array($result))
	
		   {
	
			$marked[] = $myrow['privmsgs_id'];
	
		   }
	
	
		// Makes mark an empty array if the user has no PMs
	
		if( !isset( $marked ) )
	
		   {
	
			$marked = array();
	
		   }
	
		// This section actually goes through the list and deletes the PMs
	
	
		// Debugging info:
		// echo '<pre>';
		// print_r( $marked );
	
		if( count( $marked ) )
	
		   {
	
			$delete_id = implode( ',', $marked );
	
			// Debugging info:
			// echo "<br />$delete_id";
	
			$sql = "DELETE FROM `$phpbb_privmsgs_text` WHERE `privmsgs_text_id` IN ( $delete_id )";
	
			// Debugging info:
			// echo "<br />$sql";
	
			if( !$result = mysql_query( $sql ) )
	
			   {
	
				die( 'Error deleting user PMs:<br />Line: '.__LINE__.'<br />File: '.$_SERVER['PHP_SELF']."<br />Query: $sql<br />MySQL Error: ".msql_error() );
	
			   }
	
	
			$sql = "DELETE FROM `$phpbb_privmsgs` WHERE `privmsgs_id` IN ( $delete_id )";
	
			// Debugging info:
			// echo "<br />$sql";
	
			if( !$result = mysql_query( $sql ) )
	
			   {
	
				die( 'Error deleting user Pms:<br />Line: '.__LINE__.'<br />File: '.$_SERVER['PHP_SELF']."<br />Query: $sql" );
	
			   }

		   }

	   }

	// And thats it! The user should now be fully and properly deleted!

   }


// Delete User function

function delete_user( $user_id, $clear_posts = false, $retain_pms = false, $from = 'index' )

   {

	// Debugging info:
	// var_dump( $user_id );
	// var_dump( $clear_posts );
	// var_dump( $retain_pms );
	// var_dump( $from );


	// Set global variables

	global $index;
	global $phpbb_version;

	global $phpbb_banlist;
	global $phpbb_user_group;
	global $phpbb_users;
	global $phpbb_groups;
	global $phpbb_posts;
	global $phpbb_posts_text;
	global $phpbb_topics;
	global $phpbb_vote_voters;
	global $phpbb_auth_access;
	global $phpbb_sessions;
	global $phpbb_sessions_keys;
	global $phpbb_privmsgs;
	global $phpbb_privmsgs_text;
	global $phpbb_topics_watch;


	// Set redirect URL

	if( $from == 'edit' )

	   {

		$from ="$index?user_id=$user_id";

	   }

	else

	   {

		$from = $index;

	   }


	// First, check if we are dealing with a single user, or an array of users

	if( is_array( $user_id ) )

	   {

		// Create user counter variable

		$user_counter = 0;


		// Loop through the array and perform security checks
		// on each element before actually deleting anything

		foreach( $user_id as $id )

		   { //user_id foreach 

			// First things first, sanitize the $user_id
		
			$user_id = safe_sql( $id );


			//		
			// Obtain username and level based on user_id
			//
		
			$sql = "SELECT * FROM $phpbb_users WHERE user_id=$id LIMIT 1";
		
			$result = mysql_query($sql);
			$myrow = mysql_fetch_array($result);
		
			$username = safe_sql( $myrow['username'] );
			$user_level = safe_sql( $myrow['user_level'] );
		
		
			// Obtain first admin account to set as group mod if deleted user is a group mod (step 5)
		
			$sql = "SELECT * FROM $phpbb_users WHERE user_level=1 ORDER BY user_id ASC LIMIT 1";
		
			$result = mysql_query($sql);
			$myrow = mysql_fetch_array($result);
		
			$admin_id= safe_sql( $myrow['user_id'] );
		
			// Debug info:
			// echo '<pre>';
			// echo gettype( $myrow );
			// die( $admin_id );
		
		
			// Check if admin account exists before deleting, if not return with error
		
			if( !is_array( $myrow ) )
		
			   {
		
				$_SESSION['errors']['edituser'][] = 'Due to the phpbb table requirements, at least one admin must exist in the database before a user can be deleted.<br />Either promote a current user to an admin, or register a new one give it admin status.';
				header( "Location: $from" );
				die();
		
			   }

	
			// Check if attempting to delete the anonymous account
		
			if( $id == -1 )
		
			   {

				$_SESSION['errors']['edituser'][] = 'The anonymous account is required for phpbb to function correctly and cannot be deleted.';
				continue;
		
			   }
		
		
			// Check if attempting to delete an admin account
		
			if( $user_level == 1 )
		
			   {

				// Check to see if delete admin error has occured to prevent duplicate additions of the admin notification
				// This way it will only list the delete error reason, then list only the admin account names on additional admin delete calls

				if( !isset( $admin_delete_error ) )

				   {

					$_SESSION['errors']['edituser'][] = "You cannot delete administrator accounts, they must first be demoted to a user.";
					$admin_delete_error = true;

				   }

				$_SESSION['errors']['edituser'][] = "<b>$username</b> is an administrator and therefore has been skipped.";
				continue;
		
			   }


			// This line calls the delete user core function which actually deletes the user

			delete_user_core( $id, $clear_posts, $retain_pms );

			$user_counter++;


		   } //user_id foreach 


		$_SESSION['errors']['edituser'][] = "$user_counter user(s) deleted successfully.";

	   }

	else

	   {

		// First things first, sanitize the $user_id
	
		$user_id = safe_sql( $user_id );


		//		
		// Obtain username and level based on user_id
		//
	
		$sql = "SELECT * FROM $phpbb_users WHERE user_id=$user_id LIMIT 1";
	
		$result = mysql_query($sql);
		$myrow = mysql_fetch_array($result);
	
		$username = safe_sql( $myrow['username'] );
		$user_level = safe_sql( $myrow['user_level'] );
	
	
		// Obtain first admin account to set as group mod if deleted user is a group mod (step 5)
	
		$sql = "SELECT * FROM $phpbb_users WHERE user_level=1 ORDER BY user_id ASC LIMIT 1";
	
		$result = mysql_query($sql);
		$myrow = mysql_fetch_array($result);
	
		$admin_id= safe_sql( $myrow['user_id'] );
	
		// Debug info:
		// echo '<pre>';
		// echo gettype( $myrow );
		// die( $admin_id );
	
	
		// Check if admin account exists before deleting, if not return with error
	
		if( !is_array( $myrow ) )
	
		   {
	
			$_SESSION['errors']['edituser'][] = 'Due to the phpbb table requirements, at least one admin must exist in the database before a user can be deleted.<br />Either promote a current user to an admin, or register a new one give it admin status.';
			header( "Location: $from" );
			die();
	
		   }


		// Check if attempting to delete the anonymous account
	
		if( $user_id == -1 )
	
		   {

			$_SESSION['errors']['edituser'][] = 'The anonymous account is required for phpbb to function correctly and cannot be deleted.';
			header( "Location: $from" );
			die();
	
		   }
	
	
		// Check if attempting to delete an admin account
	
		if( $user_level == 1 )
	
		   {

			$_SESSION['errors']['edituser'][] = "You cannot delete administrator accounts, they must first be demoted to a user.<br /><b>$username</b> is an administrator and therefore has been skipped.";
			header( "Location: $from" );
			die();
	
		   }


		// This line calls the delete user core function which actually deletes the user

		delete_user_core( $user_id, $clear_posts, $retain_pms );

		$_SESSION['errors']['edituser'][] = "The user <b>$username</b> was deleted successfully.";



	   }
 

	//
	// Original delete quries were here, they have been moved to the delete_user_core() function
	//


	return true;


   }





//////////////////////////////////////////////////////////////////////////////////
//
// checks if this script generated the session, if not clear it and send to login


if( $_SESSION['user_level'] == 'admin' || $_SESSION['user_level'] == 'mod' )

   {

	if( !isset( $_SESSION['status']['auth']['file'] ) || $_SESSION['status']['auth']['file'] != "$full_domain".$_SERVER['PHP_SELF'] )

	   {

		session_destroy();
		header( "Location: $index" );
		die();


	   }


   }


// Check to see if the user has selected logout

if( isset( $_GET['mode'] ) && $_GET['mode'] == "logout" )

   { //1

	session_destroy();
	$index = $_SERVER['PHP_SELF'];
	header( "Location: $index" );

   } //1


// Define Session Password, Begin Login Check & Specify user status


if(isset ( $_POST['usertype'] ) )

   { //1-0-1

		$_SESSION['usertype'] = $_POST['usertype'];

   } //1-0-1


if(  isset( $_POST['password'] ) || isset( $_SESSION['password'] ) )

   { //1-1

	if( isset( $_POST['password'] ) )

	   { //1-1-1

		if( $use_hashed_in_file_passwords == 'yes' || $use_toolkit_config_file == 'yes' )

		   {

			$_SESSION['password'] = md5( md5( $_POST['password'] ) );

		   }

		else

		   {

			$_SESSION['password'] = $_POST['password'];


		   }

	   } //1-1-1


   } //1-1

if( isset( $_SESSION['password'] ) )

   { //2

	//die( $adminpassword );


	if( $_SESSION['usertype'] == "admin" && $_SESSION['password'] === "$adminpassword" && ( $adminpassword != '' && $adminpassword != 'd41d8cd98f00b204e9800998ecf8427e' ) )

		{ //2.1

			$_SESSION['user_level'] = "admin";
			$_SESSION['AUTH'][] = 'PHPBB Admin ToolKit'.$_SESSION['toolkitversion'];
			$_SESSION['status']['auth']['file'] = "$full_domain".$_SERVER['PHP_SELF'];
			$_SESSION['status']['auth']['ip'] = $_SERVER['REMOTE_ADDR'];
			$_SESSION['status']['auth']['user_agent'] = $_SERVER['HTTP_USER_AGENT'];
			unset( $_SESSION['password'] );


		} //2.1


	elseif( $_SESSION['usertype'] == "mod" && $_SESSION['password'] === "$modpassword" && ( $modpassword != '' && $modpassword != 'd41d8cd98f00b204e9800998ecf8427e' ) )

		{ //2.2

			$_SESSION['user_level'] = "mod";
			$_SESSION['AUTH'][] = 'PHPBB Admin ToolKit'.$_SESSION['toolkitversion'];
			$_SESSION['status']['auth']['file'] = "$full_domain".$_SERVER['PHP_SELF'];
			$_SESSION['status']['auth']['ip'] = $_SERVER['REMOTE_ADDR'];
			$_SESSION['status']['auth']['user_agent'] = $_SERVER['HTTP_USER_AGENT'];
			unset( $_SESSION['password'] );

		} //2.2

	elseif(  $_SESSION['password'] == 'ENTER_ADMIN_PASSWORD_HERE' || $modpassword == 'ENTER_MOD_PASSWORD_HERE' )

		{ //2.3

		$_SESSION['loginerror'] = 'The default password is disabled for security purposes.';
		unset( $_SESSION['password'] );

		} //2.3

	else

		{ //2.4

		$_SESSION['loginerror'] = 'Incorrect Password';
		unset( $_SESSION['password'] );

		} //2.4

   } //2


// Checks to make sure the password has been changed

if( $adminpassword == 'ENTER_ADMIN_PASSWORD_HERE' || $modpassword == 'ENTER_MOD_PASSWORD_HERE' )

   { //2-1

	?>

	<center>
	<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
	<tr><td><div align="center"><?php echo $_SESSION['toolkit_title']; ?></div></td></tr>
	</table><br />
	</center>


	<center>
	<font size="3">The PHPBB ToolKit will not function untill <b>both</b> admin and mod passwords have been changed!</font>
	</center>

	<?php

   } //2-1


// Check user status, and if valid, allow entry

elseif( $_SESSION['user_level'] == 'admin' || $_SESSION['user_level'] == 'mod' && in_array( 'PHPBB Admin ToolKit'.$_SESSION['toolkitversion'], $_SESSION['AUTH'] ) )

   { //3

	/* Removed cookie check

	// First check if cookies are enabled

	if( !isset( $_COOKIE['upload_toolkit_enabled'] ) )

	   {


		die( "Your browser must be set to accept cookies from the <b>$domain</b> domain to use the <a href=\"http://starfoxtj.no-ip.com/phpbb/toolkit\" target=\"_blank\">PHPBB Admin ToolKit</a>.<br />Please enable your cookies and try again.

		<br /><br />

		In your browser, goto <b>Tools</b> -> <b>Options</b> -> <b>Privacy</b>.<br />Then either set the cookie permissions to <b>Allow</b> or set the cookie permissions for <b>$domain</b> to <b>Allow</b>.

		<br /> (<b>Note:</b> Depending on the browser, the settings may be in a slightly different location.)" );

	   }

	*/


//
// Perform Session IP and user agent checks
//

	// If the stored IP is not set, logout the user

	if( !isset( $_SESSION['status']['auth']['ip'] ) )

	   {

		?>

		The client IP does not exist and was not set upon login. As a fail safe he script has terminated . Please login again to reinitialize the authentication.

		<br /><br />

		<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Click here to return to the ToolKit login screen.</a>

		<?php

		session_destroy(); 		
		die();

	   }


	// Explode IP octets

	$ip_parts_stored = explode( '.', $_SESSION['status']['auth']['ip'] );
	$ip_parts_new = explode( '.', $_SERVER['REMOTE_ADDR'] );

	if( count( $ip_parts_stored ) != 4 || count( $ip_parts_new ) != 4 )

	   {

		?>

		An unexpected error occurred: The stored or detected IP address (used for authentication) did not contain 4 period delimitated 8-bit octets.<br />
		The stored IP for this session is <b><?php echo $_SESSION['status']['auth']['ip']; ?></b>, the detected IP of you (the visitor) is <b><?php echo $_SERVER['REMOTE_ADDR']; ?></b>.<br />
		Please report this error to either the board admin, or myself (starfoxtj) at <a href="mailto:starfoxtj@yahoo.com">starfoxtj@yahoo.com</a> so we can fix this error.

		<?php

		session_destroy();
		die();

	   }


	if( $ip_parts_stored[3] != $ip_parts_new[3] )

	   {

		?>

		The IP address in use for this session has changed and the script execution has halted as a fail safe to prevent possible session hijacking.<br /><br />

		If this is the first time you have seen this error, please continue by clicking the link below to return to the login screen.<br />
		If you continue to receive this error, it is likley that you are viewing this script through a rotating proxy  which may have changed your IP address.
		The AOL browser is well known for exhibiting this type of behavior; it is recommended you use a use a standard browser (such as <a href="http://getfirefox.com" target="_blank">Mozilla Firefox</a> or Internet Explorer) while using this script to prevent this halt from occurring.

		<br /><br />

		<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Click here to return to the ToolKit login screen.</a>

		<?php

		session_destroy();
		die();


	   }


	//
	// Check user agent, since this should not change during a session
	//


	// If the user agent is not set, or if the user agent is different, logout the user

	if( !isset( $_SESSION['status']['auth']['user_agent'] ) || $_SESSION['status']['auth']['user_agent'] != $_SERVER['HTTP_USER_AGENT'] )

	   {

		?>

		The User Agent value in use for this session has changed and the script execution has halted as a fail safe to prevent possible session hijacking.<br />Please login again to reinitialize the authentication process.

		<br /><br />

		<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Click here to return to the ToolKit login screen.</a>

		<?php

		session_destroy();
		die();

	   }



	//////////////////////////////////////////////////////////////////////////////////
	//
	// checks if this script generated the session, if not clear it and send to login
	

	if( !isset( $_SESSION['status']['auth']['file'] ) || $_SESSION['status']['auth']['file'] != "$full_domain".$_SERVER['PHP_SELF'] )

	   {

		session_destroy();
		header( "Location: $index" );
		die();


	   }




	/////////////////////////////////////////////////////////
	//
	// Check to see if GET mode regen_anon is set
	//
	/////////////////////////////////////////////////////////


	if( isset( $_GET['mode'] ) && $_GET['mode'] == 'regen_anon' )

	   {

		$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id='-1'");
		$myrow = mysql_fetch_array($result);

		if( !isset( $myrow['user_id'] ) )

		   {

			// echo 'User not found';

			mysql_query("INSERT INTO $phpbb_users VALUES ( -1, 0, 'Anonymous', '', 0, 0, 0, 1093148721, 0, 0, '0.00', NULL, '', '', 0, 0, 0, NULL, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, NULL, '', 0, '', '', '', '', '', NULL, '', '', '', '', '', '', '')");
			header( "Location: $index" );

		   }


	   }


	/////////////////////////////////////////////////////////
	//
	// Check to see if POST edit user ID or GET unban is set
	//
	/////////////////////////////////////////////////////////


	// Update user info after changing the settings: USER LEVEL Setting

	if( isset( $_POST['edit_user_id'] ) || isset( $_GET['unban'] ) || isset( $_GET['unban_banlist'] ) || isset( $_GET['banspecificid'] ) )

	   { //3.1

		///////////////////////////////////////////////
		// Begin check if admin and add extra settings
		///////////////////////////////////////////////

		if( isset( $_POST['edit_user_id'] ) )

		   { //3.1--1

			//
			// Verify new passwords match
			//

			if( isset( $_POST['edituser_newpass'] ) || isset( $_POST['edituser_newpassconf'] ) && $_SESSION['user_level'] == 'admin' )

			   {//3.1--1.1

				if( $_POST['edituser_newpass'] != '' || $_POST['edituser_newpassconf'] != '' )

				   {

					if( $_POST['edituser_newpass'] !== $_POST['edituser_newpassconf'] )

					   {


						$user_id = $_POST['edit_user_id'];
						$_SESSION['errors']['edituser'][] = 'The passwords you entered did not match.';
						header( "Location: $index?user_id=$user_id ");
						exit();

					   }

				   }

			   } //3.1--1.1


			//
			// Check to update joindate
			//


			if( isset( $_POST['update_time'] )  && $_SESSION['user_level'] == 'admin' )

			   { // Mark:_ Edituser operations: Update Joindate


				// Set User ID

				$user_id = safe_sql( $_POST['edit_user_id'] );

				// Create array to pass to make_time with date info

				$time['mm'] = $_POST['join_mm'];
				$time['dd'] = $_POST['join_dd'];
				$time['yy'] = $_POST['join_yy'];

				$time['time_hh'] = $_POST['join_time_hh'];
				$time['time_mm'] = $_POST['join_time_mm'];
				$time['time_ss'] = $_POST['join_time_ss'];

				$time['time_ap'] = $_POST['join_time_ap'];



				// Obtain timestamp from make_time, send back to edit user with error if returns false

				if( !$time = make_time( $time ) )

				   {

					foreach( $_SESSION['errors']['make_time'] as $error )

					   {

						$_SESSION['errors']['edituser'][] = $error;

					   }

					unset( $_SESSION['errors']['make_time'] );

					header( "Location: $index?user_id=$user_id ");
					die();

				   }



				// Generate SQL query

				$sql = "UPDATE `$phpbb_users` SET `user_regdate`=$time WHERE `user_id`=$user_id";

				if( !$result = mysql_query( $sql ) )
			
				   {
			
						die( '<font size="4"><b>Error updating user\'s join date:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
			
				   }





			   } // Mark:_ Edituser operations: Update Joindate


			//
			// Check to delete user
			//


				if( isset($_POST['delete_user'])  && $_POST['delete_user'] != '' && ( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $moddelete == 'yes' ) ) )

				   { //3.1---1


					// Set user_id
	
					$user_id = $_POST['edit_user_id'];
	
					// Check to make sure the delete confirmation was typed correctly
		
					if( $_POST['delete_user'] != 'delete' )
		
					   {
		
						$_SESSION['errors']['edituser'][] = 'The word "delete" was not typed correctly.<br />The user has NOT been deleted.';
						header( "Location: $index?user_id=$user_id" );
						exit();
		
					   }
		

					// Set default delete options

					$clear_posts = false;
					$retain_pms = false;


					// Set delete options for the delete_user function

					if( isset( $_POST['clear_posts'] ) )

					   {

						$clear_posts = true;

					   }

					if( isset( $_POST['retain_pms'] ) )

					   {

						$retain_pms = true;

					   }
		
		
					delete_user( $user_id, $clear_posts, $retain_pms, 'edit' ) ||
					die( 'Error calling the delete_user() function on line: '.__LINE__.'<br />This is not supposed to happen. Please contact starfoxtj.' );
		
		
					header( "Location: $index" );
					die();


				   } //3.1---1

				else

				//
				// Begin inserting additional inputs into database
				//

				   { //3.1---2

					$edituser_username = safe_sql( $_POST['edituser_username'] );
					$edituser_email = safe_sql( $_POST['edituser_email'] );
					$edituser_website = safe_sql( $_POST['edituser_website'] );
					$edituser_location = safe_sql( $_POST['edituser_location'] );
					$edituser_occupation = safe_sql( $_POST['edituser_occupation'] );
					$edituser_intrests = safe_sql( $_POST['edituser_intrests'] );
					$edituser_signature = safe_sql( $_POST['edituser_signature'] );
					$edituser_avatar = safe_sql( $_POST['edituser_avatar'] );
					$edituser_active = safe_sql( $_POST['edituser_active'] );
					$edituser_allow_pm = safe_sql( $_POST['edituser_allow_pm'] );
					$edituser_allowavatar = safe_sql( $_POST['edituser_allowavatar'] );
					$edituser_user_allow_viewonline = safe_sql( $_POST['user_allow_viewonline'] );
					$user_rank = safe_sql( $_POST['user_rank'] );
	
					$edit_user_id = $_POST['edit_user_id'];


					if( $_POST['user_avatar_type'] == '0' || $_POST['edituser_avatar'] == '' )

					   {

						$edituser_avatar_type = 0;
						$edituser_avatar = '';

					   }

					else

					   {

						$edituser_avatar_type = $_POST['user_avatar_type'];


					   }


					if( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $modrank == 'yes' ) )

					   {

						$mod_allow_rank_change = "user_rank='$user_rank',";

					   }

					else

					   {

						$mod_allow_rank_change = '';

					   }

	
					mysql_query("UPDATE $phpbb_users SET

					username='$edituser_username',
					user_email='$edituser_email',
					user_website='$edituser_website',
					user_from='$edituser_location',
					user_occ='$edituser_occupation',
					user_interests='$edituser_intrests',
					user_sig='$edituser_signature',
					user_avatar='$edituser_avatar',
					$mod_allow_rank_change 
					user_avatar_type='$edituser_avatar_type',
					user_active='$edituser_active',
					user_allowavatar='$edituser_allowavatar',
					user_allow_viewonline='$edituser_user_allow_viewonline',
					user_allow_pm='$edituser_allow_pm'

					WHERE user_id=$edit_user_id");


					//
					//  Check if dropkey is set
					//

					if( isset( $_POST['edituser_dropkey'] ) && $_POST['edituser_dropkey'] == 'yes' )

					   {

						mysql_query("UPDATE $phpbb_users SET user_actkey='' WHERE user_id=$edit_user_id");

					   }

					if( isset( $_POST['edituser_newhash'] ) && $_POST['edituser_newhash'] != '' && $_SESSION['user_level'] == 'admin'  )
	
					   {

						$passhash = safe_sql( $_POST['edituser_newhash'] );

						mysql_query("UPDATE $phpbb_users SET user_password='$passhash' WHERE user_id=$edit_user_id");

					   }
	
					elseif( isset( $_POST['edituser_newpass'] ) && $_POST['edituser_newpass'] != '' && $_SESSION['user_level'] == 'admin'  )
	
					   {
	
						if( $_POST['edituser_newpass'] === $_POST['edituser_newpassconf'] )
	
						   {

							$newpass = $_POST['edituser_newpass'];
	
							// Hash a new password
							$newpasshash = md5( $newpass );
	
							mysql_query("UPDATE $phpbb_users SET user_password='$newpasshash' WHERE user_id=$edit_user_id");
	
						   }
	
					   }

				   } //3.1---2

		   } //3.1--1

		// Disallow changing of user level to all but admin


		if( isset( $_POST['edit_user_id'] ) )

		   { //3.1-1

			if( $_SESSION['user_level'] == "admin" )

			   { //3.1.1

				$edit_user_id = $_POST['edit_user_id'];

				if( isset( $_POST['user_level'] ) && $_POST['user_level'] == "user" )

				   { //3.1.1.1

					$user_level = 0;

				   } //3.1.1.1

				elseif( isset( $_POST['user_level'] ) && $_POST['user_level'] == "admin" )

				   { //3.1.1.2

					$user_level = 1;

				   } //3.1.1.2

				if( isset( $user_level) && ( $user_level == 0 || $user_level == 1 ) )

				   { //3.1.1.3

				$edituser_posts = $_POST['edituser_posts'];
				mysql_query("UPDATE $phpbb_users SET user_level='$user_level', user_posts='$edituser_posts' WHERE user_id=$edit_user_id");

				   } //3.1.1.3

				else

				   { //3.1.1.4

				$edituser_posts = $_POST['edituser_posts'];
				mysql_query("UPDATE $phpbb_users SET user_posts='$edituser_posts' WHERE user_id=$edit_user_id");

				   } //3.1.1.4

			   } //3.1.1

		   } //3.1-1

		if( isset( $_POST['edit_user_id'] ) )

		   { //3.1-2

			if( $_SESSION['user_level'] == "admin" || $modpost == 'yes' )

			   { // 3.1.2

				$edit_user_id = $_POST['edit_user_id'];
				$edituser_posts = $_POST['edituser_posts'];

				mysql_query("UPDATE $phpbb_users SET user_posts='$edituser_posts' WHERE user_id=$edit_user_id");

			   } // 3.1.2


		   } //3.1-2

	   } //3.1


	/////////////////////////////////////////////////
	// Begin check and act on banning/unbanning users
	/////////////////////////////////////////////////


	if( isset( $_POST['banspecificuser'] ) )

	   { //3.2-1-0

		$username = $_POST['banspecificuser'];

		$result = mysql_query("SELECT * FROM $phpbb_users WHERE username='$username'");
		$myrow = mysql_fetch_array($result);

		$user_id = $myrow['user_id'];

		if( !isset( $user_id) )

		   {

			$_SESSION['banlist_error'] = 'The specified user does not exist.';
			header( "Location: $index?mode=banlist" );

		   }

		$result = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid='$user_id'");
		$myrow = mysql_fetch_array($result);
		
		mysql_query("INSERT INTO $phpbb_banlist (ban_userid) VALUES ('$user_id')");
		mysql_query("UPDATE $phpbb_sessions SET session_logged_in=0 WHERE session_user_id=$user_id");
		header( "Location: $index?mode=banlist" );

	   } //3.2-1-0


	if( isset( $_POST['banspecificemail'] ) )

	   { //3.2-1-1

		$email = $_POST['banspecificemail'];
		
		mysql_query("INSERT INTO $phpbb_banlist ( ban_email) VALUES ('$email')");
		header( "Location: $index?mode=banlist#email" );

	   } //3.2-1-1


	if( isset( $_POST['editban'] ) || isset( $_GET['unban'] ) || isset( $_GET['unban_banlist'] ) )

	   { //3.2--1

		if( isset( $_POST['editban'] ) )

		   { //3.2-1

			$edit_user_id = $_POST['edit_user_id'];

		   } //3.2-1

		$allowban = 'no';

		if( $_SESSION['user_level'] == "admin" )

		   { //3.2.1

			$allowban = 'yes';

		   } //3.2.1


		elseif( $_SESSION['user_level'] == "mod" && $modban == 'yes' )

		   { //3.2.2

			$allowban = 'yes';

		   } //3.2.2

		if( $allowban == 'yes' )

		   { //3.2.4

			if( isset( $_POST['editban'] ) && $_POST['editban'] == "yes" )

			   { //3.2.4.1


				if( $edit_user_id == -1 )

				   { //3.2.4.1-1

					$_SESSION['errors']['index'][] = 'The Anonymous user account is <b>required</b><br />for PHPBB to function and cannot be banned.';

				   } //3.2.4.1-1


				else

				   { //3.2.4.1-2

					mysql_query("INSERT INTO $phpbb_banlist (ban_userid) VALUES ('$edit_user_id')");
					mysql_query("UPDATE $phpbb_sessions SET session_logged_in=0 WHERE session_user_id=$edit_user_id");

				   } //3.2.4.1-2


			   } //3.2.4.1

			if( ( isset( $_POST['editban'] ) && $_POST['editban'] == "no" ) || isset( $_GET['unban']) )

			   { //3.2.4.2

				if( isset( $_GET['unban'] ) )

				   { //3.2.4.2.1

					$edit_user_id = $_GET['unban'];

				   } //3.2.4.2.1


				mysql_query("DELETE FROM $phpbb_banlist WHERE ban_userid=$edit_user_id");

			   } //3.2.4.2


			if( isset( $_GET['unban_banlist'] ) )

			   {

				$ban_id = $_GET['unban_banlist'];

				mysql_query("DELETE FROM $phpbb_banlist WHERE ban_id=$ban_id");
				header( "Location: $index?mode=banlist#ip" );

			   }

		   } //3.2.4

		elseif( $allowban == 'no' )

		   { //3.2.5

			$_SESSION['errors']['index'][] = 'You do <b>not</b> have Permission to Ban/Unban Users.';

		   } //3.2.5

	}//3.2--1

	/////////////////////////////////////////////////////////
	//
	// Check to see if Anon account exists
	//
	/////////////////////////////////////////////////////////


	$user_id = -1;

	$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id='$user_id'");
	$myrow = mysql_fetch_array($result);

	if( !isset( $myrow['user_id'] ) )

	   {

		$anonymous_exist = 'Notice: The Anonymous account does not exist!<br />Click <a href="?mode=regen_anon">here</a> to recreate it.';


		// The following if statement first checks to see if the anon error is already in the array
		// Only if it is not, will it add it.
		// This prevents adding the anon error twice

		if( isset( $_SESSION['errors']['index'] ) )

		   {

			if( !in_array( $anonymous_exist, $_SESSION['errors']['index'] ) )

			   {

				$_SESSION['errors']['index'][] = $anonymous_exist;

			   }


		   }

		else


		   {

			$_SESSION['errors']['index'][] = $anonymous_exist;

		   }


	   }


	////////////////////////////////////////////////
	//
	// Check to see if board config has been edited
	//
	////////////////////////////////////////////////

	
	if( isset( $_POST['edit_board_config'] ) && $_SESSION['user_level'] == 'admin' )

	   {

		$server_name = safe_sql( $_POST['server_name'] );
		$server_port = safe_sql( $_POST['server_port'] );
		$script_path = safe_sql( $_POST['script_path'] );
		$sitename = safe_sql( $_POST['sitename'] );
		$site_desc = safe_sql( $_POST['site_desc'] );
		$board_disable = safe_sql( $_POST['board_disable'] );
		$require_activation = safe_sql( $_POST['require_activation'] );
		$board_email_form = safe_sql( $_POST['board_email_form'] );
		$gzip_compress = safe_sql( $_POST['gzip_compress'] );
		$prune_enable = safe_sql( $_POST['prune_enable'] );

		$cookie_domain = safe_sql( $_POST['cookie_domain'] );
		$cookie_name = safe_sql( $_POST['cookie_name'] );
		$cookie_path = safe_sql( $_POST['cookie_path'] );
		$cookie_secure = safe_sql( $_POST['cookie_secure'] );
		$session_length = safe_sql( $_POST['session_length'] );

		$board_email = safe_sql( $_POST['board_email'] );
		$board_email_sig = safe_sql( $_POST['board_email_sig'] );
		$smtp_delivery = safe_sql( $_POST['smtp_delivery'] );
		$smtp_host = safe_sql( $_POST['smtp_host'] );
		$smtp_username = safe_sql( $_POST['smtp_username'] );
		$smtp_password = safe_sql( $_POST['smtp_password'] );

		$default_style = safe_sql( $_POST['default_style'] );
		$override_user_style = safe_sql( $_POST['override_user_style'] );


		mysql_query("UPDATE $phpbb_config SET config_value='$server_name' WHERE config_name='server_name'");
		mysql_query("UPDATE $phpbb_config SET config_value='$server_port' WHERE config_name='server_port'");
		mysql_query("UPDATE $phpbb_config SET config_value='$script_path' WHERE config_name='script_path'");
		mysql_query("UPDATE $phpbb_config SET config_value='$sitename' WHERE config_name='sitename'");
		mysql_query("UPDATE $phpbb_config SET config_value='$site_desc' WHERE config_name='site_desc'");
		mysql_query("UPDATE $phpbb_config SET config_value='$board_disable' WHERE config_name='board_disable'");
		mysql_query("UPDATE $phpbb_config SET config_value='$require_activation' WHERE config_name='require_activation'");
		mysql_query("UPDATE $phpbb_config SET config_value='$board_email_form' WHERE config_name='board_email_form'");
		mysql_query("UPDATE $phpbb_config SET config_value='$gzip_compress' WHERE config_name='gzip_compress'");
		mysql_query("UPDATE $phpbb_config SET config_value='$prune_enable' WHERE config_name='prune_enable'");

		mysql_query("UPDATE $phpbb_config SET config_value='$cookie_domain' WHERE config_name='cookie_domain'");
		mysql_query("UPDATE $phpbb_config SET config_value='$cookie_name' WHERE config_name='cookie_name'");
		mysql_query("UPDATE $phpbb_config SET config_value='$cookie_path' WHERE config_name='cookie_path'");
		mysql_query("UPDATE $phpbb_config SET config_value='$cookie_secure' WHERE config_name='cookie_secure'");
		mysql_query("UPDATE $phpbb_config SET config_value='$session_length' WHERE config_name='session_length'");

		mysql_query("UPDATE $phpbb_config SET config_value='$board_email' WHERE config_name='board_email'");
		mysql_query("UPDATE $phpbb_config SET config_value='$board_email_sig' WHERE config_name='board_email_sig'");
		mysql_query("UPDATE $phpbb_config SET config_value='$smtp_delivery' WHERE config_name='smtp_delivery'");
		mysql_query("UPDATE $phpbb_config SET config_value='$smtp_host' WHERE config_name='smtp_host'");
		mysql_query("UPDATE $phpbb_config SET config_value='$smtp_username' WHERE config_name='smtp_username'");
		mysql_query("UPDATE $phpbb_config SET config_value='$smtp_password' WHERE config_name='smtp_password'");

		mysql_query("UPDATE $phpbb_config SET config_value='$default_style' WHERE config_name='default_style'");
		mysql_query("UPDATE $phpbb_config SET config_value='$override_user_style' WHERE config_name='override_user_style'");


		if( isset( $_POST['reset_subsilver'] ) && $_POST['reset_subsilver'] == 1 )

		   {

			$reset_subsilver_id = $_POST['reset_subsilver_id'];



			mysql_query("DELETE FROM phpbb_themes WHERE themes_id='$reset_subsilver_id' LIMIT 1") or die( 'Could not delete phpbb_themes on subsilver reset!');
			mysql_query("DELETE FROM phpbb_themes_name WHERE themes_id='$reset_subsilver_id' LIMIT 1") or die( 'Could not delete phpbb_themes on subsilver reset!');

			mysql_query("INSERT INTO $phpbb_themes (themes_id, template_name, style_name, head_stylesheet, body_background, body_bgcolor, body_text, body_link, body_vlink, body_alink, body_hlink, tr_color1, tr_color2, tr_color3, tr_class1, tr_class2, tr_class3, th_color1, th_color2, th_color3, th_class1, th_class2, th_class3, td_color1, td_color2, td_color3, td_class1, td_class2, td_class3, fontface1, fontface2, fontface3, fontsize1, fontsize2, fontsize3, fontcolor1, fontcolor2, fontcolor3, span_class1, span_class2, span_class3) VALUES ('$reset_subsilver_id', 'subSilver', 'subSilver', 'subSilver.css', '', 'E5E5E5', '000000', '006699', '5493B4', '', 'DD6900', 'EFEFEF', 'DEE3E7', 'D1D7DC', '', '', '', '98AAB1', '006699', 'FFFFFF', 'cellpic1.gif', 'cellpic3.gif', 'cellpic2.jpg', 'FAFAFA', 'FFFFFF', '', 'row1', 'row2', '', 'Verdana, Arial, Helvetica, sans-serif', 'Trebuchet MS', 'Courier, \'Courier New\', sans-serif', 10, 11, 12, '444444', '006600', 'FFA34F', '', '', '')") or die( 'Could not update phpbb_themes on subsilver reset!');
			mysql_query("INSERT INTO $phpbb_themes_name (themes_id, tr_color1_name, tr_color2_name, tr_color3_name, tr_class1_name, tr_class2_name, tr_class3_name, th_color1_name, th_color2_name, th_color3_name, th_class1_name, th_class2_name, th_class3_name, td_color1_name, td_color2_name, td_color3_name, td_class1_name, td_class2_name, td_class3_name, fontface1_name, fontface2_name, fontface3_name, fontsize1_name, fontsize2_name, fontsize3_name, fontcolor1_name, fontcolor2_name, fontcolor3_name, span_class1_name, span_class2_name, span_class3_name) VALUES ('$reset_subsilver_id', 'The lightest row colour', 'The medium row color', 'The darkest row colour', '', '', '', 'Border round the whole page', 'Outer table border', 'Inner table border', 'Silver gradient picture', 'Blue gradient picture', 'Fade-out gradient on index', 'Background for quote boxes', 'All white areas', '', 'Background for topic posts', '2nd background for topic posts', '', 'Main fonts', 'Additional topic title font', 'Form fonts', 'Smallest font size', 'Medium font size', 'Normal font size (post body etc)', 'Quote & copyright text', 'Code text colour', 'Main table header text colour', '', '', '')") or die( 'Could not phpbb_themes_name on subsilver reset!');


		   }



		if( isset( $_POST['update_time'] ) )

		   {

			// Create array to pass to make_time with date info

			$time['mm'] = $_POST['join_mm'];
			$time['dd'] = $_POST['join_dd'];
			$time['yy'] = $_POST['join_yy'];

			$time['time_hh'] = $_POST['join_time_hh'];
			$time['time_mm'] = $_POST['join_time_mm'];
			$time['time_ss'] = $_POST['join_time_ss'];

			$time['time_ap'] = $_POST['join_time_ap'];



			// Obtain timestamp from make_time, send back to edit user with error if returns false

			if( !$time = make_time( $time ) )

			   {

				foreach( $_SESSION['errors']['make_time'] as $error )

				   {

					$_SESSION['errors']['config'][] = $error;

				   }

				unset( $_SESSION['errors']['make_time'] );

				header( "Location: $index?mode=config ");
				die();

			   }


			// Generate SQL query

			$sql = "UPDATE `$phpbb_config` SET `config_value`=$time WHERE `config_name`='board_startdate'";

			if( !$result = mysql_query( $sql ) )
		
			   {
		
					die( '<font size="4"><b>Error updating board\'s start date:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
		
			   }

		   }


		// $_SESSION['errors']['index'][] = 'Board config updated';

		header( "Location: $index" );
		die();

	   }


	/////////////////////////////////////////////////////////
	//
	// Check to see if POST editspecific user has information
	//
	/////////////////////////////////////////////////////////




	if( isset( $_POST['editspecificuser'] ) )

	   { //3.1-1

		$_SESSION['start'] = 0;

		$username = str_replace( '*', '%', $_POST['editspecificuser'] );


		$result = mysql_query("SELECT * FROM $phpbb_users WHERE username='$username'");
		$myrow = mysql_fetch_array($result);
		
		$index = $_SERVER['PHP_SELF'];
		$user_id = $myrow['user_id'];

		if( !isset( $myrow['user_id'] ) )

		   {

			if( $username == '' )

			   {
				$_SESSION['search'] = '';

				header( "Location: $index" );

			   }

			else

			   {

				header( "Location: $index?search=$username ");

			   }

		   }

		elseif( isset( $_SESSION['search_by'] ) && $_SESSION['search_by'] == 'skipping direct edit and going to search only' )

		   {

	 		header( "Location: $index?user_id=$user_id ");

		   }

		else

		   {

			$_SESSION['search'] = $username;
			header( "Location: $index" );

		   }

	   } //3.1-1

	/////////////////////////////////////////////////////////
	//
	// Check to see if GET=phpinfo is set
	//
	/////////////////////////////////////////////////////////

	elseif( isset($_GET['mode'] ) && $_GET['mode'] == 'phpinfo' && $_SESSION['user_level'] == 'admin' )

	   { //3.1-1a 

		phpinfo();

	   } //3.1-1a 


	/////////////////////////////////////////////////////////
	//
	// Check to see if GET=id is set to show edit user screen
	//
	/////////////////////////////////////////////////////////

	elseif( isset( $_GET['user_id'] ) || isset( $_GET['resync'] )  )

	   { //3.2

			if( isset( $_GET['resync'] ) )

			   {

				$user_id = $_GET['resync'];

				$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
				$myrow = mysql_fetch_array($result);

				$user_post_count_result = mysql_query("SELECT * FROM $phpbb_posts WHERE poster_id=$user_id");
				$user_post_count = mysql_num_rows($user_post_count_result);

			   }

			else

			   {

				$user_id = $_GET['user_id'];

				$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
				$myrow = mysql_fetch_array($result);

			   }



			if( !isset( $myrow['user_id'] ) )

			   {

				$_SESSION['errors']['index'][] = "The specified user does not exist.";

				$index = $_SERVER['PHP_SELF'];
				header( "Location: $index ");

			   }

		///////////////////////////////////////////////
		///
		/// Checks if a mod is trying to edit an admin


			if( $_SESSION['user_level'] == 'mod' && $myrow['user_level'] == 1 )

			   {

				$_SESSION['errors']['index'][] = 'You do not have permission to edit admin accounts.';
				header( "Location: $index" );

			   }

			$bantable = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid=$user_id");

			$banstat = 'no';

			$banrow = mysql_fetch_array($bantable);

			if( isset( $banrow['ban_userid'] ) )

			   { //3.2.1

				$banstat = 'yes';

			   } //3.2.1

			$_SESSION['edit_user_avatar_type'] = $myrow['user_avatar_type'];

			$avatar_set = true;



			if( $myrow['user_avatar_type'] == 0 )

			   {

				$avatar_path = '';
				$avatar_set = false;

			   }

			elseif( $myrow['user_avatar_type'] == 1 )

			   {

				$avatar_result = mysql_query("SELECT * FROM $phpbb_config WHERE config_name='avatar_path'");
				$myrowavatar = mysql_fetch_array($avatar_result);
				$avatar_path = $myrowavatar['config_value'].'/';

			   }

			elseif( $myrow['user_avatar_type'] == 2 )

			   {

				$avatar_path = '';

			   }

			elseif( $myrow['user_avatar_type'] == 3 )

			   {
				
				$avatar_result = mysql_query("SELECT * FROM $phpbb_config WHERE config_name='avatar_gallery_path'");
				$myrowavatar = mysql_fetch_array($avatar_result);
				$avatar_path = $myrowavatar['config_value'].'/';

			   }

			?>

			<html>
			<head>
			<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>
			</head>

			<body link="#0000ff" vlink="#0000ff" alink="#0000ff">

			<center>
			<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
			<tr><td><div align="center"><?php echo $_SESSION['toolkit_title']; ?></div></td></tr>
			</table><br />

			<?php

			// Begin error reporting section
	
			if( isset( $_SESSION['errors']['edituser'] ) )
	
			   {
				foreach( $_SESSION['errors']['edituser'] as $error )
	
				   {

					echo $error;
					echo "<br />\n";
	
				   }
	
				unset( $_SESSION['errors']['edituser'] );
	
			   }
	
			// End error reporting section

			?>

			</center>

			<center>
			<table border="0" width="60%" bgcolor="ffffff" cellpadding="0">

			<tr><td colspan="2" align="right"><a href="<?php echo $_SERVER['PHP_SELF']; ?>">Cancel</a></td></tr>
			<tr><td><font size="5"><b>Edit User: #<?php echo $myrow['user_id']; ?></b> - <?php echo $myrow['username']; ?></font></td><td align="right">Logged in as: <b><?php echo $_SESSION['user_level']; ?></b>

			</td></tr>
			</table>

			<table width="60%" style="border:1px solid black;" bgcolor="#000000" cellspacing="1" cellpadding="0">
			 <tr>

				<td bgcolor="#e5e5e5">

			<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
			<input type="hidden" name="edit_user_id" value="<?php echo $myrow['user_id']; ?>">



				<table border="0" cellpadding="" cellspacing="10">
				 <tr>

				<td>Username:</td>
				<td><input type="text" name="edituser_username" value="<?php echo $myrow['username']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"<?php if( $_SESSION['user_level'] != "admin" ) { echo ' readonly'; } ?>></td>

				 </tr>

				 <tr>

				<td>Email:</td>
				<td><input type="text" name="edituser_email" value="<?php echo $myrow['user_email']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"<?php if( $_SESSION['user_level'] != "admin" ) { echo ' readonly'; } ?>></td>

				 </tr>

				 <tr>

				<td>Post Count:</td>
				<td><input type="text" name="edituser_posts" value="<?php echo $myrow['user_posts']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="7" length="7" maxlength="20"<?php if( $_SESSION['user_level'] != "admin" ) { if( $_SESSION['user_level'] != "admin" && $modpost == 'no' ) { echo ' readonly'; } } ?>> <?php

				if( isset( $_GET['resync'] ) )

				   {

					if( $myrow['user_posts'] != $user_post_count )

					   {

						$user_post_count = "<font color=\"#ff0000\"><b>$user_post_count</b></font>";				

					   }

					else

					   {

						$user_post_count = $user_post_count;

					   }


					echo '( <a href="?resync='.$myrow['user_id'].'">Resync</a>: Actual Post Count: '.$user_post_count.' )';


				   }

				else

				   {

					echo '( <a href="?resync='.$myrow['user_id'].'">Resync</a> )';


				   }



				?></td>

				 </tr>

				 <tr>

				<td>User Level:</td>
				<td><?php

			// Disallow User Level to be Editable Unless viewed by Admin

			if( $_SESSION['user_level'] == "admin" )

			   { //3.2.2

				if( $myrow['user_level'] == 1 )

				   { //3.2.2.1

				echo '<select name="user_level">';
				echo '<option value="admin" selected>Admin';
				echo '<OPTION value="user">User';
				echo '</select>';

				   } //3.2.2.1

				elseif( $myrow['user_level'] == 0 )

				   { //3.2.3.1

				echo '<select name="user_level">';
				echo '<option value="admin">Admin';
				echo '<OPTION value="user" selected>User';
				echo '</select>';

				   } //3.2.4.1

				elseif( $myrow['user_level'] == 2 )

				   { //3.2.5.1

				echo '<b>Moderator</b> - Change N/A';

				   } //3.2.5.1

			   } //3.2.2

			else

			   { //3.2.3


				if( $myrow['user_level'] == 0 )

				   { //3.2.3.1
	
					$user_level = 'User';

				   } // 3.2.3.1

				if( $myrow['user_level'] == 1 )

				   { //3.2.3.2

					$user_level = 'Admin';

				   } // 3.2.3.2

				if( $myrow['user_level'] == 2 )

				   { //3.2.3.3

					$user_level = 'Mod';

				   } // 3.2.3.3

				echo '<b>'.$user_level.'</b>';

			   } //3.2.3

				?></td>
	

				 </tr>

				 <tr>

				<td>User is Banned:</td>
				<td><?php

				if( $_SESSION['user_level'] == 'admin' || $modban == 'yes' )

				   { //3.2.6.1

					if( $banstat == "no" )

					   { //3.2.6.1.1

						echo '<input type="radio" name="editban" value="yes">Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="editban" value="no" checked="checked">No';

					   } //3.2.6.1.1

					elseif( $banstat == "yes" )

					   { //3.2.6.1.2

						echo '<input type="radio" name="editban" value="yes"  checked="checked">Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="editban" value="no">No';

					   } //3.2.6.1.2

						else

					   { //3.2.6.1.3

	
						echo '(<b>Problem:</b> This message should not be listed. Please contact <a href="http://www.geocities.com/starfoxtj" target="_blank">starfoxtj@yahoo.com</a>';

					   } //3.2.6.1.3

				   } //3.2.6.1

				else

				   { //3.2.6.2

					if($banstat == "yes")

					   { //3.2.6.2.1

						$listbanstat = "Yes";

					   } //3.2.6.2.1

					elseif($banstat == "no")

					   { //3.2.6.2.2
	
						$listbanstat = "No";

					   } //3.2.6.2.2

					else

					   { //3.2.6.2.3

						echo "You should not be seeing this messege, please contact <a href=\"http://starfoxtj.no-ip.com/phpbb/toolkit\">starfoxtj</a>";

					   } //3.2.6.2.3

					echo "<b>$listbanstat</b>";

				   } //3.2.6.2

				?></td>

				 </tr>

				 <tr>

					<td>

					&nbsp;

					</td>

					<td>

					<a href="search.php?search_author=<?php echo $myrow['username']; ?>" target="_blank">Display User Posts</a> - <a href="privmsg.php?mode=post&u=<?php echo $myrow['user_id']; ?>" target="_blank">PM User</a>

					</td>

				 </tr>

				</table>

				<?php

				if( 0 == 0 )

				   { //3.2.6.3

					?>


						</td>

					 </tr>


					 <tr bgcolor="#f5f5f5">
						<td>

					<table border="0" cellpadding="" cellspacing="10">

					 <tr>

					<td colspan="2"><font size="2">(Extra Settings)</font><br /></td>

					 </tr>

					<?php 

					if( $_SESSION['user_level'] == 'admin' )

					   {

						?>

						 <tr>
	
						<td><br />Password Hash:</td>
						<td><br /><?php echo $myrow['user_password']; ?></td>
	
						 </tr>

						 <tr>
	
						<td>New hash:</td>
						<td><input type="text" name="edituser_newhash" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>
	
						 </tr>

						 <tr>
	
						<td><br />New Password:</td>
						<td><br /><input type="password" name="edituser_newpass" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>
	
						 </tr>
	
						 <tr>
	
						<td>Confirm Password:</td>
						<td><input type="password" name="edituser_newpassconf" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>
	
						 </tr>
	
						</table>
	
						<br /><center><hr width="90%"></center><br />


						<?php

						//
						// Date Section
						//

						$date_joined = $myrow['user_regdate'];
						$date_joined_ap = date( "a", $date_joined );

						$date_lastvisit = $myrow['user_lastvisit'];

						?>


					<table border="0" cellpadding="" cellspacing="10">

					 <tr>



						<td>Date Joined:</td>

						<td>
						<input type="text" name="join_mm" value="<?php echo date( "m", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
						<input type="text" name="join_dd" value="<?php echo date( "d", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
						<input type="text" name="join_yy" value="<?php echo date( "Y", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="3" maxlength="4" />
						(mm/dd/yyyy)<br />

						</td>

					 </tr>

					 <tr>

						<td>&nbsp;</td>

						<td>
						<input type="text" name="join_time_hh" value="<?php echo date( "h", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" />h :
						<input type="text" name="join_time_mm" value="<?php echo date( "i", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />m
						<input type="text" name="join_time_ss" value="<?php echo date( "s", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />s
						<select name="join_time_ap">
						<option value="am"<?php if( $date_joined_ap == 'am' ) { echo ' selected'; } ?>>AM</option>
						<option value="pm"<?php if( $date_joined_ap == 'pm' ) { echo ' selected'; } ?>>PM</option>
						</select>
						</td>
	

					 </tr>

					 <tr>

						<td>

						&nbsp;

						</td>

						<td>

						<input type="checkbox" name="update_time" />Check to enabled join date change.

						</td>

					 </tr>

					 <tr>

						<td>&nbsp;</td>

					 </tr>

					 <tr>



						<td>Last Visit:</td>

						<td>
						<?php if( $myrow['user_lastvisit'] == 0 ) { echo '-'; } else { echo date( "F jS Y, h:ia", $date_lastvisit ); } ?>
						</td>

					 </tr>

					</table>
	
						<br /><center><hr width="90%"></center><br />

						<?php

					   }

					?>

					<table border="0" cellpadding="" cellspacing="10">

					 <tr>

					<td>WebSite:</td>
					<td><input type="text" name="edituser_website" value="<?php echo $myrow['user_website']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>

					 </tr>

					 <tr>

					<td>Location:</td>
					<td><input type="text" name="edituser_location" value="<?php echo $myrow['user_from']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>

					 </tr>

					 <tr>

					<td>Occupation:</td>
					<td><input type="text" name="edituser_occupation" value="<?php echo $myrow['user_occ']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>

					 </tr>

					 <tr>

					<td>Interests:</td>
					<td><input type="text" name="edituser_intrests" value="<?php echo $myrow['user_interests']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>

					 </tr>

					 <tr>

					<td colspan="2">Signature:<br /><textarea class="post" name="edituser_signature" rows="6" cols="45"><?php echo $myrow['user_sig']; ?></textarea></td>

					 </tr>
					</table>

					<br /><center><hr width="90%"></center><br />

					<table border="0" cellpadding="" cellspacing="10">
					 <tr>

					<td valign="top"><?php if( $avatar_set == true ) { echo '<a href="'.$avatar_path.''.$myrow['user_avatar'].'" target="_blank">User Avatar:</a>'; } else { echo 'Remote Avatar:'; } ?></td><td><input type="text" name="edituser_avatar" value="<?php echo $myrow['user_avatar']; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="47" length="255" maxlength="255"></td>

					 </tr>

					 <tr>

					<td>&nbsp;</td>
					<td><input type="radio" name="user_avatar_type" value="2"<?php if( $myrow['user_avatar_type'] == 2 ) { echo ' checked'; } ?> />Remote&nbsp;&nbsp;&nbsp;<input type="radio" name="user_avatar_type" value="3"<?php if( $myrow['user_avatar_type'] == 3 ) { echo ' checked'; } ?> />Gallery&nbsp;&nbsp;&nbsp;<input type="radio" name="user_avatar_type" value="1"<?php if( $myrow['user_avatar_type'] == 1 ) { echo ' checked'; } ?> />Uploaded&nbsp;&nbsp;&nbsp;<input type="radio"  name="user_avatar_type" value="0"<?php if( $myrow['user_avatar_type'] == 0 ) { echo ' checked'; } ?> />None</td>

					 </tr>
					</table>

					<br /><center><hr width="90%"></center><br />

					<table border="0" cellpadding="" cellspacing="10">


					<?php

					if( $_SESSION['user_level'] == 'admin' || $modrank == 'yes' )

					    { //3.2.6.3.1 

						?>

						 <tr>
	
						<td>
							Rank:
	
						</td>
	
	
							<td><select name="user_rank">
		
							<option value="0">No special rank assigned</option>
		
							<?php
		
							// Begin Rank Listings
		
							$rankresult = mysql_query("SELECT * FROM $phpbb_ranks ORDER BY rank_id ASC");
		
							while( $rankmyrow = mysql_fetch_array($rankresult) )
		
							   {
		
								if( $rankmyrow['rank_special'] == 1 )
		
								   {
		
									if( $myrow['user_rank'] == $rankmyrow['rank_id'] )
			
									   {
			
										$isrank = ' selected="selected"';
			
									   }
			
									else
			
									   {
			
										$isrank = '';
			
									   }
			
								  	echo '<option value="'.$rankmyrow['rank_id'].'"'.$isrank.'>'.$rankmyrow['rank_title'].'</option>';
		
								   }
		
							   }
		
							?>
	
							</select>
		
							</td>
	
						</tr>


					 <tr>

					<td colspan="2"><hr width="100%"></td>

					 </tr>

						<?php

					    } //3.2.6.3.1 

					?>

					 <tr>

					<td>Is Active?:</td><td><input type="radio" name="edituser_active" value="1"<?php if( $myrow['user_active'] == 1 ){ echo ' checked="checked"'; }?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="edituser_active" value="0"<?php if( $myrow['user_active'] == 0 ){ echo ' checked="checked"'; }?>>No&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Drop Activaton Key: <input type="checkbox" name="edituser_dropkey" value="yes" /></td>

					 </tr>

					 <tr>

					<td colspan="2"><hr width="100%"></td>

					 </tr>

					 <tr>

					<td>Enable PM?:</td><td><input type="radio" name="edituser_allow_pm" value="1"<?php if( $myrow['user_allow_pm'] == 1 ){ echo ' checked="checked"'; }?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="edituser_allow_pm" value="0"<?php if( $myrow['user_allow_pm'] == 0 ){ echo ' checked="checked"'; }?>>No</td>

					 </tr>

					 <tr>

					<td colspan="2"><hr width="100%"></td>

					 </tr>

					 <tr>

					<td>Use Avatar?:</td><td><input type="radio" name="edituser_allowavatar" value="1"<?php if( $myrow['user_allowavatar'] == 1 ){ echo ' checked="checked"'; }?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="edituser_allowavatar" value="0"<?php if( $myrow['user_allowavatar'] == 0 ){ echo ' checked="checked"'; }?>>No</td>

					 <tr>

					<td colspan="2"><hr width="100%"></td>

					 </tr>

					 <tr>

					<td>Hidden?:</td><td><input type="radio" name="user_allow_viewonline" value="0"<?php if( $myrow['user_allow_viewonline'] == 0 ){ echo ' checked="checked"'; }?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="user_allow_viewonline" value="1"<?php if( $myrow['user_allow_viewonline'] == 1 ){ echo ' checked="checked"'; }?>>No</td>

					 </tr>

					<td colspan="2"><hr width="100%"></td>

					 </tr>

					<?php

					if( $_SESSION['user_level'] == 'admin' || $moddelete == 'yes' )

					    { //3.2.6.3.2 

						?>

						 <tr>
	
						<td>Delete User:</td><td><input type="text" name="delete_user" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="7" length="6" maxlength="6"> (Type delete)</font></td>
	
						 </tr>

						 <tr>

						<td valign="top">Options: </td>

						<td>

						<input type="checkbox" name="clear_posts" value="yes" />Clear Posts (Great for Spammers)<br />
						<input type="checkbox" name="retain_pms" value="yes" />Retain PMs<br />


						</td>

						 </tr>


						<?php

					    } //3.2.6.3.2 

					?>
						
					</table>

					<?php

				   } //3.2.6.3

				?>

			<br /><center><input TYPE="submit" VALUE="   Update   "></center><br />
			</form>

				</td>
			 </tr>
			</table>

			<table border="0" width="60%" bgcolor="ffffff">
			<tr><td><a href="<?php echo $_SERVER['PHP_SELF']; ?>">Cancel</a></td></tr>
			</table>

			<?php echo $_SESSION['copyrightfooter']; ?>

			</center>

			</body>
			</html>

			<?php


	   } //3.2

	/////////////////////////////////////
	//
	// Check to see if mode=mysql is set
	//
	/////////////////////////////////////


	elseif( isset($_GET['mode'] ) && $_GET['mode'] == 'mysql' && $_SESSION['user_level'] == 'admin' )

	   { //3.2-1-1

		echo 'Would normaly list the MySQL Qurey.<br /><a href="'.$_SERVER['PHP_SELF'].'">Back</a>';

	   } //3.2-1-1

	/////////////////////////////////////////////
	//
	// Check to see if mode=,scan is set
	//
	/////////////////////////////////////////////


	elseif( isset($_GET['mode'] ) && $_GET['mode'] == 'security_scan' )

	   { //3.2-2-security_scan 

		if( $_SESSION['user_level'] == 'admin' )

		   { //3.2-2-1
		
		/////////////////////////////////////////////////////////////////////////////////////////
		//
		// Tables for the security check
		//
		/////////////////////////////////////////////////////////////////////////////////////////



			//
			// Check if query string is set to sanitize a description
			//



			if( isset( $_GET['sanitize'] ) )

			   {


				// check if santize is for site
				if( $_GET['sanitize'] == 'site_desc' )

				   {

					$desc_id = safe_sql( $_GET['sanitize'] );
					$result = mysql_query("SELECT * FROM $phpbb_config WHERE config_name='site_desc' LIMIT 1");
					$myrow = mysql_fetch_array($result);
	
	
					// Sanitize forum_desc
					$desc = safe_sql( $myrow['config_value'] );
	
	
	
					mysql_query("UPDATE $phpbb_config SET config_value='$desc' WHERE config_name='site_desc' LIMIT 1");

				   }

				else // Sanitize is for forum

				   {
		
	
					$desc_id = safe_sql( $_GET['sanitize'] );
					$result = mysql_query("SELECT * FROM $phpbb_forums WHERE forum_id='$desc_id' ORDER BY forum_name ASC LIMIT 1");
					$myrow = mysql_fetch_array($result);
	
	
					// Check if forum exists
					if( !is_numeric( $myrow['forum_id'] ) )
	
					   {
	
						die( 'Script Halted. Forum_ID does not exist or is in an incorrect format' );
	
	
					   }
	
	
					// Sanitize forum_desc
					$desc = safe_sql( $myrow['forum_desc'] );
	
	
	
					mysql_query("UPDATE $phpbb_forums SET forum_desc='$desc' WHERE forum_id=$desc_id LIMIT 1");

				   }


				// Redirect back to security scan
				header( "Location: ?mode=security_scan#site_descriptions" );
				die();
					
			   }
	



			?>
	
			<html>
			<head>
			<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>
			</head>
	
			<body link="#0000ff" vlink="#0000ff" alink="#0000ff">
	
			<?php
	
	
			echo '<center>';
			echo '<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">';
			echo '<tr><td colspan="2">'.$_SESSION['toolkit_title'],'</div></td></tr>';
			echo '<tr><td>Logged in as: <b>'.$_SESSION['user_level'].'</b></td><td align="right"><a href="'.$_SERVER['PHP_SELF'].'">Back</a></td></tr></table>';

			?>

			<br />

			<table width="60%" style="border:1px solid black;" bgcolor="#000000" cellspacing="1" cellpadding="0">
		
			 <tr>
			
				<td bgcolor="f5f5f5">

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td>

					<a name="general"><font size="4"><b>What is the security scan?</b></font>

					</td>

		
				 </tr>

				</table>
		
				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>

					This security scan tool is designed to quickly summarize and display all important security related information in one page. It will check if your <b>phpbb installation is up-to-date</b> and (if permitted in the settings) if the <b>Admin ToolKit is up-to-date</b>. It will list all <b>administrator accounts</b> and <b>moderator accounts</b>, allowing you to <b>easily spot imposters</b>.
					<br /><br />
				
					It will also scan all <b>forum descriptions</b> showing you the actual text it contains, and will <b>highlight any potentially harmful information</b>. The vast majority of defacements resulting from hacked boards are <b>stored in the forums descriptions; using javascript, iframes and the like</b>. You can then quickly check and remove any harmful information stored in these areas.

					<br /><br />

					Jump To:
					<ul>
					<li><a href="#updates">Update Checks</a></li>
					<li><a href="#user_accounts">User Accounts</a></li>
					<li><a href="#descriptions">Descriptions</a></li>
						<ul>
						<li><a href="#site_descriptions">Site Description</a></li>
						<li><a href="#forum_descriptions">Forum Descriptions</a></li>
						</ul>
					</ul>

					</td>

				 </tr>

				</table>
	
				</td>

			 </tr>

			</table>

			<br /><br /><br /><br />


			<?php

			//
			// Seperator table
			//

			?>

			<table width="95%" style="border:1px solid black;" bgcolor="#000000" cellspacing="1" cellpadding="0">
		
			 <tr>
			
				<td bgcolor="f5f5f5">

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td>

					<a name="updates"><font size="4"><b>Section #1: Update Checks</b></font>

					</td>

		
				 </tr>

				</table>
		
				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>

					This section is used to quickly check if your installation of phpbb and the toolkit are up to date.
					<br /><br />

					The phpbb update check is done by reading the version information in the phpbb_config table in your database. It then reads a text file on phpbb.com which lists the latest version. Then it compares the two values to determine your version status.
					The default phpbb update file is located at: <a href="http://www.phpbb.com/updatecheck/20x.txt" target="_blank">http://www.phpbb.com/updatecheck/20x.txt</a>

					<br /><br />
					The toolkit update check is done almost exactly the same way, the only difference, is that the installed version information is stored in the toolkit.php file itself. The toolkit reads the text file 2.x.txt from my website which lists the latest version. Then it compares the two values to determine your version status.
					The default toolkit update file is located at: <a href="http://starfoxtj.no-ip.com/phpbb/toolkit/updatecheck/2.x.txt" target="_blank">http://starfoxtj.no-ip.com/phpbb/toolkit/updatecheck/2.x.txt</a>

					</td>

				 </tr>

				</table>
	
				</td>

			 </tr>

			</table>


			<?php

			///////////////////////
			//
			// Table for updatechecks
			//
			///////////////////////

			?>
	
			<center>
			<table>
			<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		
	
			 <tr>
	
				<td>
	
	
				<center>
				<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		
				<tr><td width="20%">
				&nbsp;
				</td>
				
				<td align="center" nowrap>
				&nbsp;
				</td>
		
				<td align="right" width="10%">
				<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>
				</td>
				</tr>
				</table>
		
				<center><table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
			
		
				 <tr>
		
					<td bgcolor="#d5d5d5" width="20" cellpadding="5">
		
					<div align="center"><b>Product:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="15%" cellpadding="5">
		
					<div align="center"><b>Installed Version:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="15%" cellpadding="5">
		
					<div align="center"><b>Latest Version:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="50%" cellpadding="5">
		
					<div align="center"><b>Details:</b></div>
		
					</td>
		
				 </tr>
		
				<?php

				//
				// PHPBB Version Check
				//


				// Get PHPBB version from the database
				$result = mysql_query("SELECT * FROM $phpbb_config WHERE config_name='version' LIMIT 1");
				$myrow = mysql_fetch_array($result);
				$version['current'] = '2'.$myrow['config_value'];


				// See if check is permitted
				if( $update_url['phpbb'] == 'none' )


				   {
						$version['color'] = 'FFEA00';
						$version['new'] = 'Disabled';
						$version['details'] = '<b>PHPBB Update Check Disabled:</b><br />The PHPBB update check has been disabled in the toolkit.php file. Please goto <a href="http://www.phpbb.com/downloads.php" target="_blank">http://www.phpbb.com</a> and check to see if you have the latest version..<br />If you want to enable the phpbb update check, please do so by changing the $update_url[\'phpbb\'] value to the update URL.';


				   }

				else

				   {
	
	
					//Check phpbb latest version online
					$version['new'] = ( $info = trim( @file_get_contents( $update_url['phpbb'] ) ) ) ? $info : 'Unknown';
					$version['new'] = str_replace( "\n", '.', $version['new'] );
	
	
					// Set warn color and check current vs latest version
					switch( $version['new'] ) 
	
					   {
	
						case 'Unknown':
	
							$version['color'] = 'FFEA00';
							$version['details'] = '<b>Error Reading update file:</b><br />Either your server disables "allow_url_fopen" in the php.ini file, or the update server is offline. Please goto <a href="http://www.phpbb.com/downloads.php" target="_blank">http://www.phpbb.com</a> and check to see if you have the latest version.';
							break;
	
	
						case $version['current']:
	
							$version['color'] = '45BF10';
							$version['details'] = 'Your PHPBB installation is up to date.';
							break;
	
						case $version['current'] != $version['new']:
	
							$version['color'] = 'ff0000';
							$version['details'] = '<b>Your PHPBB installation is outdated:</b><br />You are at risk of possible <b>exploits, sql injections, defacements, hijacks and other attacks!</b><br />It is <b>highly</b> recommended that you goto <a href="http://www.phpbb.com/downloads.php" target="_blank">http://www.phpbb.com</a> and update to the latest version as soon as possible.';
							break;
	
						default:
	
							$version['color'] = '45BF10';
							$version['details'] = '<b>Script Error:</b><br />The version check did not resolve to either unknown, current or non-current. This is not supposed to happen.<br />Please send an email to <a href="mailto:starfoxtj@yahoo.com">starfoxtj@yahoo.com</a> about this error.';
	
					   }

				  }



				?>
	
				<tr>
	
				<td bgcolor="#c5c5c5"><a href="http://www.phpbb.com" target="blank">PHPBB</a> (The Forum)</td>
				<td bgcolor="#e5e5e5" align="center"><b><?php echo $version['current']; ?></b></td>
				<td bgcolor="#<?php echo $version['color']; ?>" align="center"><b><?php echo $version['new']; ?></b></td>
				<td bgcolor="#e5e5e5"><?php echo $version['details']; ?></td>
	
				</tr>

				<?php

				//
				// ToolKit Version Check
				//


				// Set ToolKit version from variable
				$version['current'] = $_SESSION['toolkitversion'];


				// See if check is permitted
				if( $update_url['toolkit'] == 'none' )


				   {
						$version['color'] = 'FFEA00';
						$version['new'] = 'Disabled';
						$version['details'] = '<b>ToolKit Update Check Disabled:</b><br />The toolkit update check has been disabled in the toolkit.php file. Please goto <a href="http://starfoxtj.no-ip.com/phpbb/toolkit" target="_blank">http://starfoxtj.no-ip.com/phpbb/toolkit</a> and check to see if you have the latest version.<br />If you want to enable the toolkit update check, please do so by changing the $update_url[\'toolkit\'] value to the update URL.';


				   }

				else

				   {
	
	
					//Check phpbb latest version online
					$version['new'] = ( $info = trim( @file_get_contents( $update_url['toolkit'] ) ) ) ? $info : 'Unknown';
	
	
					// Set warn color and check current vs latest version
					switch( $version['new'] ) 
	
					   {
	
						case 'Unknown':
	
							$version['color'] = 'FFEA00';
							$version['details'] = '<b>Error Reading update file:</b><br />Either your server disables "allow_url_fopen" in the php.ini file, or the update server is offline. Please goto <a href="http://starfoxtj.no-ip.com/phpbb/toolkit" target="_blank">http://starfoxtj.no-ip.com/phpbb/toolkit</a> and check to see if you have the latest version.';
							break;
	
	
						case $version['current']:
	
							$version['color'] = '45BF10';
							$version['details'] = 'Your ToolKit installation is up to date.';
							break;
	
						case $version['current'] != $version['new']:
	
							$version['color'] = 'ff0000';
							$version['details'] = '<b>Your ToolKit installation is outdated:</b><br />It is recommended that you goto <a href="http://starfoxtj.no-ip.com/phpbb/toolkit" target="_blank">http://starfoxtj.no-ip.com/phpbb/toolkit</a> and download the latest version of this toolkit. Most updates include just feature additions, but some may include security fixes. You <i>may</i> be at risk for security exploits if you dont update. (Update changes are listed on my website)';
							break;

	
						default:
	
							$version['color'] = '45BF10';
							$version['details'] = '<b>Script Error:</b><br />The version check did not resolve to either unknown, current or non-current. This is not supposed to happen.<br />Please send an email to <a href="mailto:starfoxtj@yahoo.com">starfoxtj@yahoo.com</a> about this error.';
	
					   }

				   }



				?>


				<tr>
	
				<td bgcolor="#c5c5c5"><a href="http://starfoxtj.no-ip.com/phpbb/toolkit" target="blank">PHPBB Admin ToolKit</a></td>
				<td bgcolor="#e5e5e5" align="center"><b><?php echo $version['current']; ?></b></td>
				<td bgcolor="#<?php echo $version['color']; ?>" align="center"><b><?php echo $version['new']; ?></b></td>
				<td bgcolor="#e5e5e5"><?php echo $version['details']; ?></td>
	
				</tr>
	
				<?php

		
				echo "</table></center>";
	
				?>

				</td>

			 </tr>
	
			</table>

			</center>

			<?php

			///////////////////////
			//
			// Table for updatechecks
			//
			///////////////////////

			?>

			<?php

			//
			// Seperator table
			//

			?>

			<br /><br /><br /><br />



			<?php

			//
			// Seperator table
			//

			?>

			<table width="95%" style="border:1px solid black;" bgcolor="#000000" cellspacing="1" cellpadding="0">
		
			 <tr>
			
				<td bgcolor="f5f5f5">

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td>

					<a name="user_accounts"><font size="4"><b>Section #2: User Accounts</b></font>

					</td>

		
				 </tr>

				</table>
		
				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>

					This is the section concerning user account security. Many hackers promote backdoor accounts to administrators so they can return later and have full access to your board.

					<br /><br />Listed below are <b>all</b> the administrators and moderators. Look through the list and make sure that no unknown accounts exist. If you see an account that should not be there, click its name to demote or ban that user.

					</td>

				 </tr>

				</table>
	
				</td>

			 </tr>

			</table>


			<?php

			//
			// Seperator table
			//

			?>


			<?php

			///////////////////////
			//
			// Table for admins
			//
			///////////////////////

			?>
	
			<center>
			<table>
			<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		
	
			 <tr>
	
				<td>
	
	
				<center>
				<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		
				<tr><td width="20%">
				<a name="administrators"><b>Board Administrators:</b></a>
				</td>
				
				<td align="center" nowrap>
				&nbsp;
				</td>
		
				<td align="right" width="10%">
				<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>
				</td>
				</tr>
		
				</table>
		
				<center><table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
			
		
				 <tr>
	
					<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
		
					<div align="center"><b>ID:</a></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="20%" cellpadding="5">
		
					<div align="center"><b>Username:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="20%" cellpadding="5">
		
					<div align="center"><b>Email:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="8%" cellpadding="5">
		
					<div align="center"><b>Posts:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="8%" cellpadding="5">
		
					<div align="center"><b>Level:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="7%" cellpadding="5">
		
					<div align="center"><b>Active:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="7%" cellpadding="5">
		
					<div align="center"><b>Joined:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="7%" cellpadding="5">
		
					<div align="center"><b>Visit:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
		
					<div align="center"><b>Ban:</b></div>
		
					</td>
		
				 </tr>
		
				<?php
	
				$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_level=1 ORDER BY username ASC");
	
				while( $myrow = mysql_fetch_array($result) )
		
				   { //3.10
		
					if( $myrow['user_level'] == 0 )
		
					   { //3.10.1
		
						$userlevel = "User";
		
					   } //3.10.1
		
					elseif( $myrow['user_level'] == 1 )
		
					   { //3.10.2
		
						$userlevel = "Admin";
		
					   } //3.10.2
		
					elseif( $myrow['user_level'] == 2 )
		
					   { //3.10.3
		
						$userlevel = "Mod";
		
					   } //3.10.3
		
		
					if( $myrow['user_active'] == 1 )
		
					   { //3.10.3-1
		
						$useractive = "Yes";
		
					   } //3.10.3-1
		
					else
		
					   { //3.10.3-2
		
						$useractive = "No";
		
					   } //3.10.3-2
	
	
			
					$user_id = $myrow['user_id'];
					$bantable = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid=$user_id");
	
		
					$banstat = '-';
					$banrow = mysql_fetch_array($bantable);
	
		
					if( isset( $banrow['ban_userid'] ) )
		
					   { //3.10.4
		
						$banstat = '<b>Banned</b>';
		
					   } //3.10.4
	
		
					$useremail = $myrow['user_email'];
					$useremailshort = $useremail;
		
					if ( strlen( $useremail ) > 17 )
		
					   {  //3.10.6.2
		
						$emaildots = "";
		
					   }  //3.10.6.2
		
					else
		
					   {  //3.10.6.2
		
						$emaildots = "";
		
					   }  //3.10.6.2
		
					?>
		
					<tr>
		
					<td bgcolor="#c5c5c5"><div align="left"><?php echo $myrow['user_id']; ?></div></td>
					<td bgcolor="#e5e5e5"><div align="left"><a href="?user_id=<?php echo $myrow['user_id']; ?>" target="_blank"><?php echo $myrow['username']; ?></a></div></td>
					<td bgcolor="#c5C5c5" nowrap><div align="left"><a href="mailto:<?php echo $useremail; ?>"><?php if( $myrow['user_id'] == -1 ) { echo '<center>-</center>'; } else { ?>&nbsp;<?php echo $useremailshort; echo $emaildots; } ?></a></div></td>
					<td bgcolor="#e5e5e5"><div align="right"><?php echo $myrow['user_posts']; ?></div></td>
					<td bgcolor="#c5C5c5"><div align="right"><?php echo $userlevel; ?></div></td>
					<td bgcolor="#e5e5E5"><div align="center"><?php echo $useractive; ?></div></td>
					<td bgcolor="#c5C5c5" nowrap><div align="center" style="font-family: Verdana; font-size: 9px;"><?php echo date( "m/d/Y", $myrow['user_regdate'] ); ?></div></td>
					<td bgcolor="#e5e5E5" align="center" nowrap><?php if( $myrow['user_lastvisit'] == 0 ) { echo '-'; } else { echo '<div style="font-family: Verdana; font-size: 9px;">'.date( "m/d/Y", $myrow['user_lastvisit'] ).'</div>'; } ?></td>
					<td bgcolor="#c5C5c5"><div align="center"><?php echo $banstat; ?></div></td>
		
					</tr>
		
					<?php
		
					   } //3.10
		
				echo "</table></center>";
	
				?>

				</td>

			 </tr>
	
			</table>

			<?php

			///////////////////////
			//
			// Table for admins
			//
			///////////////////////

			?>

			<br />

			<?php

			///////////////////////
			//
			// Table for mods
			//
			///////////////////////

			?>
	
			<center>
			<table>
			<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		
	
			 <tr>
	
				<td>
	
	
				<center>
				<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		
				<tr><td width="20%">
				<a name="moderators"><b>Board Moderators:</b></a>
				</td>
				
				<td align="center" nowrap>
				&nbsp;
				</td>
		
				<td align="right" width="10%">
				<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>
				</td>
				</tr>
		
				</table>
		
				<center><table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
			
		
				 <tr>
		
					<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
		
					<div align="center"><b>ID:</a></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="20%" cellpadding="5">
		
					<div align="center"><b>Username:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="20%" cellpadding="5">
		
					<div align="center"><b>Email:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="8%" cellpadding="5">
		
					<div align="center"><b>Posts:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="8%" cellpadding="5">
		
					<div align="center"><b>Level:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="7%" cellpadding="5">
		
					<div align="center"><b>Active:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="7%" cellpadding="5">
		
					<div align="center"><b>Joined:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="7%" cellpadding="5">
		
					<div align="center"><b>Visit:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
		
					<div align="center"><b>Ban:</b></div>
		
					</td>
		
				 </tr>
		
				<?php
	
				$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_level=2 ORDER BY username ASC");
	
				while( $myrow = mysql_fetch_array($result) )
		
				   { //3.10
		
					if( $myrow['user_level'] == 0 )
		
					   { //3.10.1
		
						$userlevel = "User";
		
					   } //3.10.1
		
					elseif( $myrow['user_level'] == 1 )
		
					   { //3.10.2
		
						$userlevel = "Admin";
		
					   } //3.10.2
		
					elseif( $myrow['user_level'] == 2 )
		
					   { //3.10.3
		
						$userlevel = "Mod";
		
					   } //3.10.3
		
		
					if( $myrow['user_active'] == 1 )
		
					   { //3.10.3-1
		
						$useractive = "Yes";
		
					   } //3.10.3-1
		
					else
		
					   { //3.10.3-2
		
						$useractive = "No";
		
					   } //3.10.3-2
	
	
			
					$user_id = $myrow['user_id'];
					$bantable = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid=$user_id");
	
		
					$banstat = '-';
					$banrow = mysql_fetch_array($bantable);
	
		
					if( isset( $banrow['ban_userid'] ) )
		
					   { //3.10.4
		
						$banstat = '<b>Banned</b>';
		
					   } //3.10.4
	
		
					$useremail = $myrow['user_email'];
					$useremailshort = $useremail;
		
					if ( strlen( $useremail ) > 17 )
		
					   {  //3.10.6.2
		
						$emaildots = "";
		
					   }  //3.10.6.2
		
					else
		
					   {  //3.10.6.2
		
						$emaildots = "";
		
					   }  //3.10.6.2
		
					?>
		
					<tr>
		
					<td bgcolor="#c5c5c5"><div align="left"><?php echo $myrow['user_id']; ?></div></td>
					<td bgcolor="#e5e5e5"><div align="left"><a href="?user_id=<?php echo $myrow['user_id']; ?>" target="_blank"><?php echo $myrow['username']; ?></a></div></td>
					<td bgcolor="#c5C5c5" nowrap><div align="left"><a href="mailto:<?php echo $useremail; ?>"><?php if( $myrow['user_id'] == -1 ) { echo '<center>-</center>'; } else { ?>&nbsp;<?php echo $useremailshort; echo $emaildots; } ?></a></div></td>
					<td bgcolor="#e5e5e5"><div align="right"><?php echo $myrow['user_posts']; ?></div></td>
					<td bgcolor="#c5C5c5"><div align="right"><?php echo $userlevel; ?></div></td>
					<td bgcolor="#e5e5E5"><div align="center"><?php echo $useractive; ?></div></td>
					<td bgcolor="#c5C5c5" nowrap><div align="center" style="font-family: Verdana; font-size: 9px;"><?php echo date( "m/d/Y", $myrow['user_regdate'] ); ?></div></td>
					<td bgcolor="#e5e5E5" align="center" nowrap><?php if( $myrow['user_lastvisit'] == 0 ) { echo '-'; } else { echo '<div style="font-family: Verdana; font-size: 9px;">'.date( "m/d/Y", $myrow['user_lastvisit'] ).'</div>'; } ?></td>
					<td bgcolor="#c5C5c5"><div align="center"><?php echo $banstat; ?></div></td>
		
					</tr>
		
					<?php
		
					   } //3.10
		
				echo "</table></center>";
	
				?>

				</td>

			 </tr>
	
			</table>

			<?php

			///////////////////////
			//
			// Table for mods
			//
			///////////////////////

			?>

			<br /><br /><br /><br />


			<?php

			//
			// Seperator table
			//

			?>

			<table width="95%" style="border:1px solid black;" bgcolor="#000000" cellspacing="1" cellpadding="0">
		
			 <tr>
			
				<td bgcolor="f5f5f5">

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td>

					<a name="descriptions"><font size="4"><b>Section #3: Descriptions</b></font></a>

					</td>

		
				 </tr>

				</table>
		
				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>

					The majority of hackers who gain access to your board add malicious information into your forum or site descriptions. The most common are the javascript, and iframe tags. By adding these to your descriptions, they can embed "hacked by" messages, songs, music and page redirects.
					<br />
					 Most of the harmful tags cannot be seen by viewing the forum index.

					<br /><br />
					This section scans all forum descriptions showing you the actual text, including the added information.
					<br />
					This scrip will scan for the following tags: <b>&lt;, &gt;, &lt;script, &lt;javascript, script&gt;, &lt;iframe, &lt;frame, iframe&gt;, frame&gt;, &lt;embed, embed&gt;</b>

					<br /><br />
					The first two characters, are considered a minor risk. The rest, are considered major risks. (Explained below).

					<br /><br />
					On most hacked forums where the hacker added an iframe or javascript into a description, the board administrator is unable to view the forum, or even enter the admin panel to remove it. With this tool, if any harmful or malicious tags are detected in the forum description, you have the option to <b>Sanitize</b> it. Sanitation converts the characters that make the tags harmful, into safe, non-harmful equivalents.

					<br /><br />
					The two special characters that allow the script and javascript tags to be harmful, are the left and right arrows. The left and right arrows, when surrounding a body of text, are invisible when viewed through a browser. When this script sanitized a description, it converts the left and right arrows, into harmless "html entities". An html entity is a code value that is used to represent the left and right arrows (among other special characters). The left and right arrow characters can be "printed" on the screen using the html entities: <b>&amp;lt;</b> for the left arrow, and <b>&amp;gt;</b> for the right arrow.
					<br />
					By converting the left and right arrows to their represented code, they are displayed in the browser as harmless arrows. Since they are no longer actual arrows, but the code equivalent, they no longer pose a threat to your forum. You can then login to your admin panel like normal, and remove the extra code.

					<br /><br />
					If a description contains the left, and or right arrow <b>&lt; &gt;</b>, it will be highlighted in <b>yellow</b>.
					Yellow indicates that these characters, <i>may</i> possibly be used in a harmful way. This is not always the case though; just because the description contains the left or right arrow, does not mean it is insecure or harmful. Many administrators use them by choice on their website, for line breaks <b>&lt;br /&gt;</b>, images <b>&lt;img&gt;</b> and font modifications <b>&lt;font&gt;</b>. I would suggest double checking these descriptions to ensure they contain <b>only</b> what you wrote.

					<br /><br />
					If a description contains any of the other tags, such as the famous <b>iframe</b>, <b>javascript</b> or <b>embed</b> tags, it will be highlighted in <font color="#ff0000"><b>red</b></font>.
					Red indicates that these descriptions almost certainly contain harmful information. Hardly any administrators use these tags in their forum descriptions, but hackers almost <i>always</i> do. Read through the descriptions highlighted in red, and unless you intentionally intended to add that code, sanitize it.
					</td>

				 </tr>

				</table>
	
				</td>

			 </tr>

			</table>

			<?php

			//
			// Seperator table
			//

			?>

			<?php

			///////////////////////
			//
			// Table for sitedesc
			//
			///////////////////////

			?>
	
			<center>
			<table>
			<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		
	
			 <tr>
	
				<td>
	
	
				<center>
				<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		
				<tr><td width="20%">
				<a name="site_descriptions"><b>Site Description:</b></a>
				</td>
				
				<td align="center" nowrap>
				&nbsp;
				</td>
		
				<td align="right" width="10%">
				<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>
				</td>
				</tr>
		
				</table>
		
				<center><table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
			
		
				 <tr>

					<td bgcolor="#d5d5d5" width="40%" cellpadding="5">
		
					<div align="center"><b>Description:</b></div>
		
					</td>

					<td bgcolor="#d5d5d5" width="35%" cellpadding="5">
		
					<div align="center"><b>Details:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
		
					<div align="center"><b>Options:</b></div>
		
					</td>
		
				 </tr>
		
				<?php

				//
				// Begin forum description check
				//


				// Specify description badwords
				$desc['badwords']['minor'][] = '<';
				$desc['badwords']['minor'][] = '>';

				$desc['badwords']['major'][] = '<javascript';
				$desc['badwords']['major'][] = 'script>';
				$desc['badwords']['major'][] = '<iframe';
				$desc['badwords']['major'][] = '<frame';
				$desc['badwords']['major'][] = 'iframe>';
				$desc['badwords']['major'][] = 'frame>';
				$desc['badwords']['major'][] = '<embed';
				$desc['badwords']['major'][] = 'embed>';


				// Get forum names and descriptions
				$result = mysql_query("SELECT * FROM $phpbb_config WHERE config_name='site_desc' LIMIT 1");


				$myrow = mysql_fetch_array($result);

				// Assign orig desc to variable
				$desc['orig'] = $myrow['config_value'];


				// Define default variables marking descriptiosn as safe.
				// The if statements will change them if it finds a match
				$desc['status'] = 'green';
				$desc['row_color'] = '45BF10';
				$desc['details'] = 'No malicious information detected.';
				$desc['new'] = safe_desc( $desc['orig'] );


				// Interate through each minor badword
				foreach( $desc['badwords']['minor'] as $word )

				   {

					if( stristr( $desc['orig'], $word ) )

					   {

						$desc['status'] = 'yellow';
						$desc['row_color'] = 'FFEA00';
						$desc['details'] = '<b>Potentially harmful information detected:</b><br />The left <b>&lt;</b> and/or right <b>&gt;</b> arrow characters have been detected in this description. Many administrators use these for legitimate purposes and it should most likely be left alone.';
						$desc['new'] = ''.safe_desc( $desc['orig'] ).'';

					   }

				   }


				// Interate through each major badword
				foreach( $desc['badwords']['major'] as $word )

				   {

					if( stristr( $desc['orig'], $word ) )

					   {

						$desc['status'] = 'red';
						$desc['row_color'] = 'C30000';//C30000';
						$desc['details'] = '<b>Malicious infomration detected:</b><br />One or more of the <b>javascript</b>, <b>iframe</b> or <b>embed</b> tags have been detected in this description. Unless you intentionally added this information yourself, this description should be <b>sanitized</b>.';
						$desc['new'] = '<b>'.safe_desc( $desc['orig'] ).'</b>';

					   }

				   }


				?>
	
				<tr>

				<td bgcolor="#<?php echo $desc['row_color']; ?>" align="left" valign="top"><font face="arial" size="2"><?php echo $desc['new']; ?></font></td>
				<td bgcolor="#c5c5c5" align="left" valign="top"><font face="arial" size="2"><?php echo $desc['details']; ?></font></td>
				<td bgcolor="#e5e5e5" align="center"><?php if( $desc['status'] == 'green' ) { echo '-'; } else { echo '<a href="?mode=security_scan&sanitize=site_desc">Sanitize</a>'; } ?></td>
	
				</tr>
	
				<?php

		
				echo "</table></center>";
	
				?>

				</td>

			 </tr>
	
			</table>

			</center>

			<?php

			///////////////////////
			//
			// Table for site desc
			//
			///////////////////////

			?>

			<?php

			///////////////////////
			//
			// Table for forum desc
			//
			///////////////////////

			?>
	
			<center>
			<table>
			<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		
	
			 <tr>
	
				<td>
	
	
				<center>
				<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		
				<tr><td width="20%">
				<a name="forum_descriptions"><b>Forum Descriptions:</b></a>
				</td>
				
				<td align="center" nowrap>
				&nbsp;
				</td>
		
				<td align="right" width="10%">
				<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>
				</td>
				</tr>
		
				</table>
		
				<center><table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
			
		
				 <tr>
		
					<td bgcolor="#d5d5d5" width="15" cellpadding="5">
		
					<div align="center"><b>Forum:</b></div>
		
					</td>
		
		
					<td bgcolor="#d5d5d5" width="40%" cellpadding="5">
		
					<div align="center"><b>Description:</b></div>
		
					</td>

					<td bgcolor="#d5d5d5" width="35%" cellpadding="5">
		
					<div align="center"><b>Details:</b></div>
		
					</td>
		
					<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
		
					<div align="center"><b>Options:</b></div>
		
					</td>
		
				 </tr>
		
				<?php

				//
				// Begin forum description check
				//


				// Get forum names and descriptions
				$result = mysql_query("SELECT * FROM $phpbb_forums ORDER BY forum_name ASC");


				while( $myrow = mysql_fetch_array($result) )

				   {

					// Assign orig desc to variable
					$desc['orig'] = $myrow['forum_desc'];


					// Define default variables marking descriptiosn as safe.
					// The if statements will change them if it finds a match
					$desc['status'] = 'green';
					$desc['row_color'] = '45BF10';
					$desc['details'] = 'No malicious information detected.';
					$desc['new'] = safe_desc( $desc['orig'] );


					// Interate through each minor badword
					foreach( $desc['badwords']['minor'] as $word )

					   {

						if( stristr( $desc['orig'], $word ) )
	
						   {
	
							$desc['status'] = 'yellow';
							$desc['row_color'] = 'FFEA00';
							$desc['details'] = '<b>Potentially harmful information detected:</b><br />The left <b>&lt;</b> and/or right <b>&gt;</b> arrow characters have been detected in this description. Many administrators use these for legitimate purposes and it should most likely be left alone.';
							$desc['new'] = ''.safe_desc( $desc['orig'] ).'';
	
						   }

					   }


					// Interate through each major badword
					foreach( $desc['badwords']['major'] as $word )

					   {

						if( stristr( $desc['orig'], $word ) )
	
						   {

							$desc['status'] = 'red';
							$desc['row_color'] = 'C30000';//C30000';
							$desc['details'] = '<b>Malicious infomration detected:</b><br />One or more of the <b>javascript</b>, <b>iframe</b> or <b>embed</b> tags have been detected in this description. Unless you intentionally added this information yourself, this description should be <b>sanitized</b>.';
							$desc['new'] = '<b>'.safe_desc( $desc['orig'] ).'</b>';
	
						   }

					   }


					?>
		
					<tr>
		
					<td bgcolor="#c5c5c5"><b><?php echo $myrow['forum_name']; ?></b></td>
					<td bgcolor="#<?php echo $desc['row_color']; ?>" align="left" valign="top"><font face="arial" size="2"><?php echo $desc['new']; ?></font></td>
					<td bgcolor="#c5c5c5" align="left" valign="top"><font face="arial" size="2"><?php echo $desc['details']; ?></font></td>
					<td bgcolor="#e5e5e5" align="center"><?php if( $desc['status'] == 'green' ) { echo '-'; } else { echo '<a href="?mode=security_scan&sanitize='.$myrow['forum_id'].'">Sanitize</a>'; } ?></td>
		
					</tr>
		
					<?php

				   }

		
				echo "</table></center>";

				?>

				</td>

			 </tr>
	
			</table>

			</center>

			<?php

			///////////////////////
			//
			// Table for forum desc
			//
			///////////////////////

			?>

	
	
			<?php

			echo $_SESSION['copyrightfooter'];

		   } //3.2-2-1

		else

		   { //3.2-2-2

			header( "Location: $index ");

		   } //3.2-2-2
	
	   } //3.2-2-secutiy_check 


	/////////////////////////////////////
	//
	// Check to see if mode=config is set
	//
	/////////////////////////////////////


	elseif( isset($_GET['mode'] ) && $_GET['mode'] == 'config' && $_SESSION['user_level'] == 'admin' )

	   { //3.2-1

		// echo 'Would normaly list the Board config page.<br /><a href="'.$_SERVER['PHP_SELF'].'">Back</a>';

		// Orig info from forum: $result = mysql_query("SELECT config_name AS name, config_value AS val FROM $phpbb_config");
		//
		// while ( $myrow = mysql_fetch_assoc($result) )
		// {
		// $name = $myrow['name'];
		// $val = $myrow['val'];
		// $cfg[$name] = $val;
		// 


		///////////////////////////////
		//
		// Begin Grabbing phpbb config


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='server_name' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_server_name = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='server_port' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_server_port = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='script_path' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_script_path = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='sitename' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_sitename = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='site_desc' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_site_desc = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='board_disable' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_board_disable = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='require_activation' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_require_activation = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='board_email_form' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_board_email_form = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='gzip_compress' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_gzip_compress = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='prune_enable' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_prune_enable = $myrow['config_value'];


		// Begin cookie info


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='cookie_domain' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_cookie_domain = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='cookie_name' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_cookie_name = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='cookie_path' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_cookie_path = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='cookie_secure' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_cookie_secure = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='session_length' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_session_length = $myrow['config_value'];


		// Begin Email Info


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='board_email' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_board_email = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='board_email_sig' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_board_email_sig = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='smtp_delivery' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_smtp_delivery = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='smtp_host' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_smtp_host = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='smtp_username' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_smtp_username = $myrow['config_value'];


		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='smtp_password' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_smtp_password = $myrow['config_value'];

		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='default_style' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_default_style = $myrow['config_value'];

		$result = mysql_query("SELECT * FROM $phpbb_config WHERE  config_name='override_user_style' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$config_override_user_style = $myrow['config_value'];

		$result = mysql_query("SELECT * FROM $phpbb_config WHERE `config_name`='board_startdate' LIMIT 1");
		$myrow = mysql_fetch_array($result);

		$board_startdate = $myrow['config_value'];




		////////////////////////////////////////
		//
		// Begin checks on auto detect settings


		if( isset( $_GET['detect'] ) && $_GET['detect'] == 'general' )

		   {

			// Server Name

		   	$detect_server_name = $HTTP_SERVER_VARS['SERVER_NAME'];

			if ( substr( $detect_server_name, 0, 4 ) == 'www.' )

			   {

				$detect_server_name = substr( $detect_server_name, 4 );

			   }

			else

			   {

				$detect_server_name = $detect_server_name;
			   }


			// Server Port

		   	$detect_server_port = $HTTP_SERVER_VARS['SERVER_PORT'];


			$tmp1_self = $_SERVER['PHP_SELF'];
			$tmp2_self = end(explode('/', $tmp1_self));
			$tmp2_self_size = strlen( $tmp2_self );

			// Script Path

			$detect_script_path = substr( $tmp1_self, 0, -$tmp2_self_size );


			// echo "$tmp1_self<br />$tmp2_self<br />$tmp2_self_size<br />$detect_script_path";

		   }


		if( isset( $_GET['detect'] ) && $_GET['detect'] == 'cookie' )

		   {

			// Cookie Domain

		   	$detect_cookie_domain = $HTTP_SERVER_VARS['SERVER_NAME'];

			if ( substr( $detect_cookie_domain, 0, 4 ) == 'www.' )

			   {

				$detect_cookie_domain = substr( $detect_cookie_domain, 4 );

			   }

			else

			   {

				$detect_cookie_domain = $detect_cookie_domain;
			   }

		   }


		?>

		<html>
		<head>
		<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>
		</head>
	
		<body link="#0000ff" vlink="#0000ff" alink="#0000ff">
	
		<center>
		<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		<tr><td><div align="center"><?php echo $_SESSION['toolkit_title']; ?></div></td></tr>
		</table><br />

		<?php

		// Begin error reporting section

		if( isset( $_SESSION['errors']['config'] ) )

		   {
			foreach( $_SESSION['errors']['config'] as $error )

			   {

				echo $error;
				echo "<br />\n";

			   }

			unset( $_SESSION['errors']['config'] );

			echo "<br />";

		   }

		// End error reporting section
	


		// The Board Config section is currently disabled in this release.<br />
		// Please wait untill beta 4 for a working version.<br /><br />

		?>
	
		</center>
	
		<center>
		<table border="0" width="60%" bgcolor="ffffff" cellpadding="0">
		<tr><td><font size="5"><b>Board Configuration:</a></font></td><td align="right"><a href="<?php echo $_SERVER['PHP_SELF']; ?>">Cancel</a>
	
		</td></tr>
		</table>
	
		<table width="60%" style="border:1px solid black;" bgcolor="#000000" cellspacing="1" cellpadding="0">
		 <tr>
	
			<td bgcolor="f5f5f5">
	
			<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
			<input type="hidden" name="edit_board_config" value="224">

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td><center><a name="general"><font size="4"><b>General Board Settings:</b></font></a></center></td>
		
				 </tr>

				</table>
	
				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>Domain Name:</td>
					<td><input type="text" name="server_name" value="<?php echo $config_server_name; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>
					<td nowrap><?php

					if( isset( $detect_server_name ) )

					   {

						if( $config_server_name != $detect_server_name )

						   {

							echo "<font color=\"#ff0000\"><b>$detect_server_name</b></font>";

						   }

						else

						   {

							echo $detect_server_name;

						   }

					   }

					else

					   {

						?>( <a href="?mode=config&detect=general">Auto Detect</a> )<?php

					   }

					?></td>
			
					 </tr>
		
					 <tr>
			
					<td>Port:</td>
					<td><input type="text" name="server_port" value="<?php echo $config_server_port; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="3" >
					<td><?php

					if( isset( $detect_server_port ) )

					   {

						if( $config_server_port != $detect_server_port )

						   {

							echo "<font color=\"#ff0000\"><b>$detect_server_port</b></font>";

						   }

						else

						   {

							echo $detect_server_port;

						   }

					   }

					else

					   {

						?>( <a href="?mode=config&detect=general">Auto Detect</a> )<?php

					   }

					?></td>
					 </tr>
			
					 <tr>
			
					<td>Script Path:</td>
					<td><input type="text" name="script_path" value="<?php echo $config_script_path; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255">
					<td><?php

					if( isset( $detect_script_path ) )

					   {

						if( $config_script_path != $detect_script_path )

						   {

							echo "<font color=\"#ff0000\"><b>$detect_script_path</b></font>";

						   }

						else

						   {

							echo $detect_script_path;

						   }

					   }

					else

					   {

						?>( <a href="?mode=config&detect=general">Auto Detect</a> )<?php

					   }

					?></td>			
					 </tr>
		
					 <tr>
			
					<td>Site Name:</td>
					<td><input type="text" name="sitename" value="<?php echo $config_sitename; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>
			
					 </tr>
	
					 <tr>
			
					<td>Site Description:</td>
					<td><input type="text" name="site_desc" value="<?php echo $config_site_desc; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" length="255" maxlength="255"></td>
			
					 </tr>
	
					 <tr>
			
					<td>Disable Board:</td>
					<td><input type="radio" name="board_disable" value="1"<?php if( $config_board_disable == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="board_disable" value="0"<?php if( $config_board_disable == 0 ) { echo ' checked'; } ?>>No</td>
		
				 	 </tr>

					 <tr>
			
					<td>Account Activation:</td>
					<td><input type="radio" name="require_activation" value="0"<?php if( $config_require_activation == 0 ) { echo ' checked'; } ?>>None&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="require_activation" value="1"<?php if( $config_require_activation == 1 ) { echo ' checked'; } ?>>User&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="require_activation" value="2"<?php if( $config_require_activation == 2 ) { echo ' checked'; } ?>>Admin</td>
		
				 	 </tr>

					 <tr>
			
					<td>Email via Board:</td>
					<td><input type="radio" name="board_email_form" value="1"<?php if( $config_board_email_form == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="board_email_form" value="0"<?php if( $config_board_email_form == 0 ) { echo ' checked'; } ?>>No</td>
		
				 	 </tr>

					 <tr>
			
					<td>Enable GZip:</td>
					<td><input type="radio" name="gzip_compress" value="1"<?php if( $config_gzip_compress == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="gzip_compress" value="0"<?php if( $config_gzip_compress == 0 ) { echo ' checked'; } ?>>No</td>
		
				 	 </tr>

					 <tr>
			
					<td>Enable Pruning:</td>
					<td><input type="radio" name="prune_enable" value="1"<?php if( $config_prune_enable == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="prune_enable" value="0"<?php if( $config_prune_enable == 0 ) { echo ' checked'; } ?>>No</td>
		
				 	 </tr>


					 <tr>

					<td>Default Style:</td>

					<td>

					<select name="default_style">
	
					<?php

					// Begin Style Listings

					$themeresult = mysql_query("SELECT * FROM $phpbb_themes ORDER BY themes_id ASC");

					while( $thememyrow = mysql_fetch_array($themeresult) )

					   {

							
						?><option value="<?php echo $thememyrow['themes_id']; ?>"<?php if( $config_default_style == $thememyrow['themes_id'] ) { echo ' selected'; } ?>><?php echo $thememyrow['template_name'].' ('.$thememyrow['themes_id'].')'; ?></option><?php

					   }

					?>

					</select>

					</td>

					 </tr>

					 <tr>

					<td>Override Style:</td>
					<td><input type="radio" name="override_user_style" value="1"<?php if( $config_override_user_style == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="override_user_style" value="0"<?php if( $config_override_user_style == 0 ) { echo ' checked'; } ?>>No</td>

					 </tr>

					 <tr>

					<td><a name="reset_subsilver" title="Use this option to reset all the CSS settings for the SubSilver template."><i>Reset SubSilver:</i></a></td>
					<td><input type="radio" name="reset_subsilver" value="1">Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="reset_subsilver" value="0" checked>No&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SubSilver ID: <input type="text" name="reset_subsilver_id" value="1" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" /></td>

					 </tr>

					<?php

					//
					// Date Section
					//

					$date_joined = $board_startdate;
					$date_joined_ap = date( "a", $date_joined );

					?>

					 <tr>



						<td>Start Date:

						<td>
						<input type="text" name="join_mm" value="<?php echo date( "m", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
						<input type="text" name="join_dd" value="<?php echo date( "d", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
						<input type="text" name="join_yy" value="<?php echo date( "Y", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="3" maxlength="4" />
						(mm/dd/yyyy)<br />

						</td>

					 </tr>

					 <tr>

						<td>&nbsp;</td>

						<td>
						<input type="text" name="join_time_hh" value="<?php echo date( "h", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" />h :
						<input type="text" name="join_time_mm" value="<?php echo date( "i", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />m
						<input type="text" name="join_time_ss" value="<?php echo date( "s", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />s
						<select name="join_time_ap">
						<option value="am"<?php if( $date_joined_ap == 'am' ) { echo ' selected'; } ?>>AM</option>
						<option value="pm"<?php if( $date_joined_ap == 'pm' ) { echo ' selected'; } ?>>PM</option>
						</select>
						</td>

					 </tr>

					 <tr>

						<td>

						&nbsp;

						</td>

						<td>

						<input type="checkbox" name="update_time" />Check to enabled date change

						</td>

					 </tr>

	
				</table>

				</td>

				 </tr>


	

			 <tr bgcolor="#f5f5f5">

				<td>

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td><center><font size="4"><b>Cookie Settings:</b></font></center></td>
		
				 </tr>

				</table>

				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>Cookie Domain:</td>
					<td><input type="text" name="cookie_domain" value="<?php echo $config_cookie_domain; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="15" maxlength="255"></td>
					<td><?php

					if( isset( $detect_cookie_domain ) )

					   {

						if( $config_cookie_domain != $detect_cookie_domain )

						   {

							echo "<font color=\"#ff0000\"><b>$detect_cookie_domain</b></font>";

						   }

						else

						   {

							echo $detectcookie_domain;

						   }

					   }

					else

					   {

						?>( <a href="?mode=config&detect=cookie">Auto Detect</a> )<?php

					   }

					?></td>				
					 </tr>
		
					 <tr>
		
					<td>Cookie Name:</td>
					<td><input type="text" name="cookie_name" value="<?php echo $config_cookie_name; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="15" maxlength="255"></td>
					<td><?php

					if( isset( $detect_cookie_domain ) )

					   {

						if( $config_cookie_name != 'phpbb2mysql' )

						   {

							echo "<font color=\"#ff0000\"><b>phpbb2mysql</b></font>";

						   }

						else

						   {

							echo 'phpbb2mysql';

						   }

					   }

					else

					   {

						?>( <a href="?mode=config&detect=cookie">Auto Detect</a> )<?php

					   }

					?></td>				
					 </tr>
		
			
					 <tr>
			
					<td>Cookie Path:</td>
					<td><input type="text" name="cookie_path" value="<?php echo $config_cookie_path; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="15" maxlength="255"></td>		
					 </tr>
	
					 <tr>
			
					<td>Cookie Secure:</td>
					<td><input type="radio" name="cookie_secure" value="1"<?php if( $config_cookie_secure == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="cookie_secure" value="0"<?php if( $config_cookie_secure == 0 ) { echo ' checked'; } ?>>No</td>
		
				 	 </tr>

					 <tr>
			
					<td>Session length:</td>
					<td><input type="text" name="session_length" value="<?php echo $config_session_length; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="4" maxlength="15"></td>
		
				 	 </tr>
	
				</table>

				</td>

				 </tr>


	

			 <tr bgcolor="#f5f5f5">

				<td>

				<table border="0" bgcolor="#e5e5e5" cellpadding="5" width="100%">

				  <tr>
	
					<td><center><font size="4"><b>Email Settings:</b></font></center></td>
		
				 </tr>

				</table>

				<table border="0" cellpadding="" cellspacing="10">

				 <tr>
		
					<td>Admin Email:</td>
					<td><input type="text" name="board_email" value="<?php echo $config_board_email; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" maxlength="255"></td>
			
					 </tr>

					 <tr>
			
					<td valign="top">Email Signiture:</td>
					<td><textarea rows="3" cols="26" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" name="board_email_sig"><?php echo $config_board_email_sig; ?></textarea></td>
			
					 </tr>

					 <tr>
			
					<td>Use SMTP Server:</td>
					<td><input type="radio" name="smtp_delivery" value="1"<?php if( $config_smtp_delivery == 1 ) { echo ' checked'; } ?>>Yes&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="smtp_delivery" value="0"<?php if( $config_smtp_delivery == 0 ) { echo ' checked'; } ?>>No</td>
		
				 	 </tr>
			
					 <tr>
			
					<td>SMTP Address:</td>
					<td><input type="text" name="smtp_host" value="<?php echo $config_smtp_host; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" maxlength="255"></td>
			
					 </tr>
			
					 <tr>
			
					<td>SMTP Username:</td>
					<td><input type="text" name="smtp_username" value="<?php echo $config_smtp_username; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" maxlength="255"></td>
			
					 </tr>

					 <tr>
			
					<td>SMTP Password:</td>
					<td><input type="password" name="smtp_password" value="<?php echo $config_smtp_password; ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="35" maxlength="255"></td>
			
					 </tr>
	
				</table>
		
			<br /><center><input TYPE="submit" VALUE="   Update   "></center><br />
			</form>
	
			</td>
		 </tr>
		</table>
	
		<table border="0" width="60%" bgcolor="ffffff">
		<tr><td><a href="<?php echo $_SERVER['PHP_SELF']; ?>">Cancel</a></td></tr>
		</table>

		<?php echo $_SESSION['copyrightfooter']; ?>

		</center>
	
		</body>
		</html>

		<?php


	   } //3.2-1


	/////////////////////////////////////
	//
	// Check to see if mode=banlist is set
	//
	/////////////////////////////////////


	elseif( isset($_GET['mode'] ) && $_GET['mode'] == 'banlist' )

	   { //3.2-2

		if( $_SESSION['user_level'] == 'admin' || $modban == 'yes' )

		   { //3.2-2-1

			// echo '<center><b>This banlist is ONLY listed here to demonstrate what it will look like.<br />The banlist in this version of the toolkit is non-functional and I do not recommend making any changes.<br /><br />';
	
			$list = "username";
			$order = "ASC";
	
			if( isset( $_GET['list'] ) && $_GET['list'] == "user_id" )
	
			   { //3.3-3
	
				$list = "user_id";
	
			   } //3.3-3
	
			elseif( isset( $_GET['list'] ) && $_GET['list'] == "posts" )
	
			   { //3.3-4
	
				$list = "user_posts";
	
			   } //3.3-4
	
			elseif( isset( $_GET['list'] ) && $_GET['list'] == "level" )
	
			   { //3.3-5
	
				$list = "user_level";
	
			   } //3.3-5
	
			elseif( isset( $_GET['list'] ) && $_GET['list'] == "active" )
	
			   { //3.3-5
	
				$list = "user_active";
	
			   } //3.3-5
	
			elseif( isset( $_GET['list'] ) && $_GET['list'] == "email" )
	
			   { //3.3-5
	
				$list = "user_email";
	
			   } //3.3-5
	
		
			$order = "ASC";
	
			if( isset( $_GET['order'] ) && $_GET['order'] == "DESC" )
	
			   { //3.3-6
	
			$order = "DESC";
	
			   } //3.3-6
	
	
			if( $order == "ASC" )
	
			   { //3.3-7
	
				$order = "DESC";
	
			   } //3.3-7
	
			else
	
			   { //3.3-8
	
				$order = "ASC";
	
			   } //3.3-8
	
	
			if( !isset($_GET['order'] ) && !isset($_GET['list'] ) )
	
			   {
	
				$list = "username";
				$order = "ASC";
	
	 		   }
	
	
	
		/////////////////////////////////////////////////////////////////////////////////////////
		//
		// This actually lists the users for the ban list
		//
		/////////////////////////////////////////////////////////////////////////////////////////
	
	
	
			$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY $list $order");
	
			//
			// Remove Resubmit message
			//
	
			?>
	
			<html>
			<head>
			<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>
			</head>
	
			<body link="#0000ff" vlink="#0000ff" alink="#0000ff">
	
			<?php
	
	
			echo '<center>';
			echo '<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">';
			echo '<tr><td>'.$_SESSION['toolkit_title'],'</div></td></tr>';
			echo '<tr><td>Logged in as: <b>'.$_SESSION['user_level'].'</b></td></tr></table>';
	
			if( isset( $_SESSION['banlist_error'] ) )
	
			   { //3.7-1.1
	
				echo "<br />\n";
				echo $_SESSION['banlist_error'];
				unset( $_SESSION['banlist_error'] );
	
			   } //3.7-1.1
	
			echo '</center><br />';
	
			$showadmin = "<a href=\"?show=admin\">Show only Administrators</a>";
	
			if( isset( $_GET['show'] ) && $_GET['show'] == "admin" )
	
			   { //3.8
	 
				$showadmin = "<a href=\"?show=all\">Show all Users</a>";
	
			   } //3.8
	
			$showban = "<a href=\"?show=ban\">Show only banned Users</a>";
	
			if( isset( $_GET['show'] ) && $_GET['show'] == "ban" )
	
			   { //3.9
	   
				$showban = "<a href=\"?show=all\">Show all Users</a>";
	
			   } //3.9
	
	
			$showinactive = "<a href=\"?show=inactive\">Show only Inactive Users</a>";
	
			if( isset( $_GET['show'] ) && $_GET['show'] == "inactive" )
	
			   { //3.8
	 
				$showinactive = "<a href=\"?show=all\">Show all Users</a>";
	
			   } //3.8
	
			?>
	
			<center>
			<table>
			<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		
	
			 <tr>
	
				<td>
	
	
			<center>
			<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
	
			<tr><td width="20%">
			<b>Banned Users:</b>
			</td>
			
			<td align="center" nowrap>
			<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
			<input type="text" name="banspecificuser" value=" Enter Username Here" onFocus="if(this.value==' Enter Username Here')this.value='';" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="25" length="25" maxlength="50">&nbsp;&nbsp;<input type="submit" value=" Ban User ">
			</form>
			</td>
	
			<td align="right" width="10%">
			<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>
			</td>
			</tr>
	
			</table>
	
			<center><table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
		
	
			 <tr>
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center"><b>ID:</b></div>
	
				</td>
	
	
				<td bgcolor="#d5d5d5" width="28%" cellpadding="5">
	
				<div align="center"><<b>Username:</b></div>
	
				</td>
	
				<td bgcolor="#d5d5d5" width="22%" cellpadding="5">
	
				<div align="center"><b>Email:</b></div>
	
				</td>
	
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center"><b>Posts:</b></div>
	
				</td>
	
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center"><b>Level:</b></div>
	
				</td>
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center"><b>Active:</b></div>
	
				</td>
	
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center">Ban:</div>
	
				</td>
	
			 </tr>
	
			<?php
	
			while( $myrow = mysql_fetch_array($result) )
	
			   { //3.10
	
				if( $myrow['user_level'] == 0 )
	
				   { //3.10.1
	
					$userlevel = "User";
	
				   } //3.10.1
	
				elseif( $myrow['user_level'] == 1 )
	
				   { //3.10.2
	
					$userlevel = "Admin";
	
				   } //3.10.2
	
				elseif( $myrow['user_level'] == 2 )
	
				   { //3.10.3
	
					$userlevel = "Mod";
	
				   } //3.10.3
	
	
				if( $myrow['user_active'] == 1 )
	
				   { //3.10.3-1
	
					$useractive = "Yes";
	
				   } //3.10.3-1
	
				else
	
				   { //3.10.3-2
	
					$useractive = "No";
	
				   } //3.10.3-2
		
				$user_id = $myrow['user_id'];
				$bantable = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid=$user_id");
	
				$banstat = '-';
				$banrow = mysql_fetch_array($bantable);
	
				if( isset( $banrow['ban_userid'] ) )
	
				   { //3.10.4
	
					$banstat = 'Banned';
					
					if( $_SESSION['user_level'] == "admin" )
	
					   { //3.10.4.1
	
						if( isset( $_GET['show'] ) )
	
						   { //3.10.4.1.1
	
							$banstat = '<a href="'.$_SERVER['PHP_SELF'].'?show='.$_GET['show'].'&mode=banlist&unban='.$myrow['user_id'].'">UnBan</a>';
	
						   } //3.10.4.1.1
	
					else
	
						   { //3.10.4.1.2
	
							$banstat = '<a href="'.$_SERVER['PHP_SELF'].'?mode=banlist&unban='.$myrow['user_id'].'">UnBan</a>';
	
						   } //3.10.4.1.2
	
					   } //3.10.4.1
	
					if( $_SESSION['user_level'] == "mod" && $modban == 'yes' )
	
					   { //3.10.4.2
	
						$banstat = '<a href="'.$_SERVER['PHP_SELF'].'?unban='.$myrow['user_id'].'&mode=banlist">UnBan</a>';
	
					   } //3.10.4.2
	
				   } //3.10.4
	
				if( $banstat == "-" )
	
				   { //3.10.6.1
	
					continue;
	
				   } //3.10.6.1
	
	
				if( isset( $_GET['show'] ) && $_GET['show'] == "admin" )
	
				   { //3.10.5
	
					if( $myrow['user_level'] != 1 )
	
					   { //3.10.5.1
	
						continue;
	
					   } //3.10.5.1
	
				   } //3.10.5
	
	
				if( isset( $_GET['show'] ) && $_GET['show'] == "inactive" )
	
				   { //3.10.6-1
	
					if( $myrow['user_active'] == 1 )
	
					   { //3.10.6-1.1
	
						continue;
	
					   } //3.10.6-1.1
	
	
				   } //3.10.6-1
	
				$useremail = $myrow['user_email'];
				$useremailshort = $useremail;
	
				if ( strlen( $useremail ) > 17 )
	
				   {  //3.10.6.2
	
					$emaildots = "";
	
				   }  //3.10.6.2
	
				else
	
				   {  //3.10.6.2
	
					$emaildots = "";
	
				   }  //3.10.6.2
	
				?>
	
				<tr>
	
				<td bgcolor="#c5c5c5"><div align="left"><?php echo $myrow['user_id']; ?></div></td>
				<td bgcolor="#e5e5e5"><div align="left"><a href="?user_id=<?php echo $myrow['user_id']; ?>"><?php echo $myrow['username']; ?></a></div></td>
				<td bgcolor="#c5C5c5" nowrap><div align="left"><a href="mailto:<?php echo $useremail; ?>"><?php if( $myrow['user_id'] == -1 ) { echo '<center>-</center>'; } else { ?>&nbsp;<?php echo $useremailshort; echo $emaildots; } ?></a></div></td>
				<td bgcolor="#e5e5e5"><div align="right"><?php echo $myrow['user_posts']; ?></div></td>
				<td bgcolor="#c5C5c5"><div align="right"><?php echo $userlevel; ?></div></td>
				<td bgcolor="#e5e5E5"><div align="center"><?php echo $useractive; ?></div></td>
				<td bgcolor="#c5C5c5"><div align="center"><?php echo $banstat; ?></div></td>
	
				</tr>
	
				<?php
	
				   } //3.10
	
			echo "</table></center>";

	
			$result = mysql_query("SELECT * FROM $phpbb_banlist ORDER BY ban_email ASC");
	
			?>
	
			<br /><br />
			<center>
			<table width="100%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
	
			<tr><td width="20%">
			<b>Banned Emails:</b>
			</td>
			
			<td align="center" nowrap>
			<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
			<input type="text" name="banspecificemail" value=" Enter Email Address Here" onFocus="if(this.value==' Enter Email Address Here')this.value='';" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="25" length="25" maxlength="50">&nbsp;&nbsp;<input type="submit" value=" Ban Email ">
			</form>		
			</td>
	
			<td width="10%">
			<div align="right">&nbsp;</div>
			</td>
			</tr>
	
			</table>
	
			<table width="100%" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
		
	
			 <tr>
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center"><font color="#000000"><b>Ban_Id:</b></font></div>
	
				</td>
	
	
				<td bgcolor="#d5d5d5" width="80%" cellpadding="5">
	
				<div align="center"><font color="#000000"><b>Ban_Email:</b></font></div>
	
				</td>
	
				<td bgcolor="#d5d5d5" width="10%" cellpadding="5">
	
				<div align="center"><font color="#000000"><b>Unban:</b></font></div>
	
				</td>
	
	
	
			 </tr>
	
			<?php
	
			while( $myrow = mysql_fetch_array($result) )
	
			   { // 3.10-1-1
	
	
				if( isset( $myrow['ban_email'] ) )
	
				   { // 3.10-1-1.1
	
					?>
	
					 <tr>
	
					<td bgcolor="#e5e5E5"><div align="center"><?php echo $myrow['ban_id']; ?></div></td>
					<td bgcolor="#c5C5c5"><div align="center"><?php echo $myrow['ban_email']; ?></div></td>
					<td bgcolor="#e5e5E5"><div align="center"><a href="<?php echo $_SERVER['PHP_SELF']; ?>?unban_banlist=<?php echo $myrow['ban_id']; ?>">Unban</a></div></td>
	
					 </tr>
	
	
	
					<?php
	
				   } // 3.10-1-1.1
	
			   } // 3.10-1-1
	
			?>
	
			</table>

			<table width="100%" border="0" cellpadding="3" cellspacing="1">

			 <tr>

				<td align="right">

				<a href="<?php echo $_SERVER['PHP_SELF']; ?>">Back</a>

				</td>

			 </tr>

			</table>

			<?php echo $_SESSION['copyrightfooter']; ?>
	
			</table>
	
			</center>
	
	
			<?php

		   } //3.2-2-1

		else

		   { //3.2-2-2

			header( "Location: $index ");

		   } //3.2-2-2
	
	   } //3.2-2

	elseif( isset( $_POST['massuseraction'] ) )

	   { //3.2-2a 

		if( !isset( $_POST['user'] ) && !isset( $_POST['export_all'] )  )

		   {

			$_SESSION['errors']['index'][] = 'You must select at least one user.';
			header( "Location: $index" );
			exit();


		   }


		if( !isset( $_POST['export_selected'] ) && !isset( $_POST['export_all'] ) && !isset( $_POST['delete_users'] ) &&  $_POST['massuseraction'] != '---')
	
		   { //3.2-2a.1 
	
	
	
			//////////////////////////////////////
			//
			// Begin banning multiple users
	
	
			if( $_POST['massuseraction'] == 'ban' && ( $_SESSION['user_level'] == 'admin' || $modban == 'yes' ) )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
					if( $user_id == -1 )
		
					   {
		
						continue;
		
					   }
		
					mysql_query("INSERT INTO $phpbb_banlist (ban_userid) VALUES ('$user_id')");
					mysql_query("UPDATE $phpbb_sessions SET session_logged_in=0 WHERE session_user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
			//////////////////////////////////////
			//
			// Begin unbanning multiple users
	
	
			elseif( $_POST['massuseraction'] == 'unban' && ( $_SESSION['user_level'] == 'admin' || $modban == 'yes' ) )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
					$result = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid='$user_id'");
					$myrow = mysql_fetch_array($result);
	
					if( isset( $myrow['ban_userid'] ) )
	
					   {
	
						// echo 'User found';
	
						mysql_query("DELETE FROM $phpbb_banlist WHERE ban_userid=$user_id");
						header( "Location: $index" );
	
					   }
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
			//////////////////////////////////////
			//
			// Begin activating multiple users
	
	
			elseif( $_POST['massuseraction'] == 'activate' )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
		
					if( $user_id == -1 )
		
					   {
		
						continue;
		
					   }
	
					mysql_query("UPDATE $phpbb_users SET user_active='1' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
			//////////////////////////////////////
			//
			// Begin Post Count Resync
	
	
			elseif( $_POST['massuseraction'] == 'resync' && ( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $modpost == 'yes' ) ) )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
		
					$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
					$myrow = mysql_fetch_array($result);
	
					$user_post_count_result = mysql_query("SELECT * FROM $phpbb_posts WHERE poster_id=$user_id");
					$user_post_count = mysql_num_rows($user_post_count_result);
					mysql_query("UPDATE $phpbb_users SET user_posts='$user_post_count' WHERE user_id=$user_id");
	
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
			//////////////////////////////////////
			//
			// Begin deactivating multiple users
	
	
			elseif( $_POST['massuseraction'] == 'deactivate' )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
	
					mysql_query("UPDATE $phpbb_users SET user_active='0' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
			//////////////////////////////////////
			//
			// Begin deactivating and drop key on multiple users
	
	
			elseif( $_POST['massuseraction'] == 'deactivate_and_drop' )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
	
					mysql_query("UPDATE $phpbb_users SET user_active='0' WHERE user_id=$user_id");
					mysql_query("UPDATE $phpbb_users SET user_actkey='' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
			//////////////////////////////////////
			//
			// Begin clearing signiture
	
	
			elseif( $_POST['massuseraction'] == 'clear_sig' )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
	
					mysql_query("UPDATE $phpbb_users SET user_sig='' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
	
			//////////////////////////////////////
			//
			// Begin clearing website
	
	
			elseif( $_POST['massuseraction'] == 'clear_website' )
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
	
					mysql_query("UPDATE $phpbb_users SET user_website='' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
	
	
	
	
			//////////////////////////////////////
			//
			// Begin promoting multiple users to admin
	
	
			elseif( $_POST['massuseraction'] == 'admin' && $_SESSION['user_level'] == 'admin' )
	
			   {
	
				if( !isset( $_POST['confirm'] ) || $_POST['confirm'] != 'yes' )
	
				   {
	
					$_SESSION['errors']['index'][] = 'You must confirm before promoting multiple users to admin.';
					header( "Location: $index" );
					die();
	
	
				   }
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
					$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id='$user_id'");
					$myrow = mysql_fetch_array($result);
		
					if( $user_id == -1 || $myrow['user_level'] == 2 )
		
					   {
		
						continue;
		
					   }
	
					mysql_query("UPDATE $phpbb_users SET user_level='1' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	



	
			//////////////////////////////////////
			//
			// Begin demoting multiple users to user
	
	
			elseif( $_POST['massuseraction'] == 'user'  && $_SESSION['user_level'] == 'admin')
	
			   {
	
				foreach( $_POST['user'] as $user_id )
		
				   {
	
					$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id='$user_id'");
					$myrow = mysql_fetch_array($result);
		
					if( $user_id == -1 || $myrow['user_level'] == 2 )
		
					   {
	
						continue;
	
					   }
	
	
					mysql_query("UPDATE $phpbb_users SET user_level='0' WHERE user_id=$user_id");
					header( "Location: $index" );
	
		
				   }
	
				header( "Location: $index" );
				exit();
	
			   }
	
			else
	
			   {
	
				header( "Location: $index" );
				exit();
	
			   }

		   } //3.2-2a.1 

		elseif( ( isset( $_POST['delete_users'] ) || $_POST['delete_confirm'] != '' ) && ( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $moddelete == 'yes' ) ) )

		   { //3.2-2a.1-2 


			//////////////////////////////////////
			//
			// Begin deleting multiple users


			// Check to make sure the delete confirmation was typed correctly

			if( $_POST['delete_confirm'] != 'delete' )

			   {

				$_SESSION['errors']['edituser'][] = 'The word "delete" was not typed correctly.<br />The user(s) have NOT been deleted.';
				header( "Location: $index ");
				exit();

			   }


			// Set default delete options

			$clear_posts = false;
			$retain_pms = false;


			// Set delete options for the delete_user function

			if( isset( $_POST['clear_posts'] ) )

			   {

				$clear_posts = true;

			   }

			if( isset( $_POST['retain_pms'] ) )

			   {

				$retain_pms = true;

			   }


			delete_user( $_POST['user'], $clear_posts, $retain_pms, 'index' ) ||
			die( 'Error calling the delete_user() function on line: '.__LINE__.'<br />This is not supposed to happen. Please contact starfoxtj.' );


			header( "Location: $index" );
			die();

		   } //3.2-2a.1-2 


		elseif( isset( $_POST['change_date'] ) && $_SESSION['user_level'] == 'admin' )

		   { //3.2-2a.1-3 


			if( !isset( $_POST['confirm_date'] ) )

			   {

				$_SESSION['errors']['edituser'][] = 'You must confirm when changing the join date for multiple users.';
				header( "Location: $index ");
				exit();

			   }


			foreach( $_POST['user'] as $user_id )
	
			   {

	
				//////////////////////////////////////
				//
				// Begin date change on multiple users
	
	
				// Set User ID


				// Create array to pass to make_time with date info

				$time['mm'] = $_POST['join_mm'];
				$time['dd'] = $_POST['join_dd'];
				$time['yy'] = $_POST['join_yy'];

				$time['time_hh'] = $_POST['join_time_hh'];
				$time['time_mm'] = $_POST['join_time_mm'];
				$time['time_ss'] = $_POST['join_time_ss'];

				$time['time_ap'] = $_POST['join_time_ap'];




				// Obtain timestamp from make_time, send back to edit user with error if returns false

				if( $timestamp = make_time( $time ) )

				   {
	
	
					// Generate SQL query
	
					$sql = "UPDATE `$phpbb_users` SET `user_regdate`=$timestamp WHERE `user_id`=$user_id";
	
	
					if( !$result = mysql_query( $sql ) )
				
					   {
				
							die( '<font size="4"><b>Error updating user\'s join date:</b></font><br /><b>Line:</b> '.__LINE__.'<br /><b>File:</b> '.$_SERVER['PHP_SELF']."<br /><b>Query:</b> $sql<br /><b>MySQL Error:</b> ".mysql_error() );
				
					   }

				   }

				else

				   {


					foreach( $_SESSION['errors']['make_time'] as $error )

					   {

						$_SESSION['errors']['index'][] = $error;

					   }

					unset( $_SESSION['errors']['make_time'] );

				   }
	


			   }

			header( "Location: $index" );
			die();

		   } //3.2-2a.1-3 


		/////////////////////////////////////
		//
		// Begin Exporting Users
		//

		elseif( isset( $_POST['export_selected'] ) || isset( $_POST['export_all'] ) && $_SESSION['user_level'] == 'admin' )

		   { //3.2-2a.2 


		      // We'll be outputting a CSV
		      header('Content-type: application/octetstream');
		      header('Content-type: application/octet-stream');
		      //did the above to make sure that all browsers see it as such. (yes, IE needs diffrent ones)
		      header("Content-Disposition: attachment; filename=AddressBook.csv");


			if( $_POST['export_type'] == 'email_only' )

			   { //3.2-2a.2.1 

				if( isset( $_POST['export_all'] ) )

				   {

					$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY user_email ASC");

					while($myrow = mysql_fetch_array($result))

					   {

						$user_id = $myrow['user_id'];

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }

	
						echo $myrow['user_email']."\n";

					   }



				   }

				else


				   {
	
					foreach( $_POST['user'] as $user_id )
			
					   {

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	
						$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
						$myrow = mysql_fetch_array($result);
	
						echo $myrow['user_email']."\n";

			   		   }

				   }

			   } //3.2-2a.2.1 

			elseif( $_POST['export_type'] == 'gmail_csv' )

			   { //3.2-2a.2.2 

				echo "Name,Email\n";

				if( isset( $_POST['export_all'] ) )

				   {

					$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY username ASC");

					while($myrow = mysql_fetch_array($result))

					   {

						$user_id = $myrow['user_id'];

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	

	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo $username.','.$myrow['user_email']."\n";

					   }



				   }

				else


				   {
	
					foreach( $_POST['user'] as $user_id )
			
					   {

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	
						$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
						$myrow = mysql_fetch_array($result);
	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo $username.','.$myrow['user_email']."\n";

			   		   }

				   }

			   } //3.2-2a.2.2 

			elseif( $_POST['export_type'] == 'hotmail_csv' )

			   { //3.2-2a.2.3 

				echo "First Name,Last Name,E-mail Address\n";

				if( isset( $_POST['export_all'] ) )

				   {

					$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY username ASC");

					while($myrow = mysql_fetch_array($result))

					   {

						$user_id = $myrow['user_id'];

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	

	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo $username.',,'.$myrow['user_email']."\n";

					   }



				   }

				else


				   {
	
					foreach( $_POST['user'] as $user_id )
			
					   {

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	
						$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
						$myrow = mysql_fetch_array($result);
	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo $username.',,'.$myrow['user_email']."\n";

			   		   }

				   }

			   } //3.2-2a.2.3 


			elseif( $_POST['export_type'] == 'yahoo_csv' )

			   { //3.2-2a.2.4 

				echo "First,Email\n";

				if( isset( $_POST['export_all'] ) )

				   {

					$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY username ASC");

					while($myrow = mysql_fetch_array($result))

					   {

						$user_id = $myrow['user_id'];

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	

	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo $username.','.$myrow['user_email']."\n";

					   }



				   }

				else


				   {
	
					foreach( $_POST['user'] as $user_id )
			
					   {

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	
						$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
						$myrow = mysql_fetch_array($result);
	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo $username.','.$myrow['user_email']."\n";

			   		   }

				   }

			   } //3.2-2a.2.4 


			elseif( $_POST['export_type'] == 'outlook_csv' )

			   { //3.2-2a.2.5 

				echo '"Title","First Name","Middle Name","Last Name","Suffix","Company","Department","Job Title","Business Street","Business Street 2","Business Street 3","Business City","Business State","Business Postal Code","Business Country","Home Street","Home Street 2","Home Street 3","Home City","Home State","Home Postal Code","Home Country","Other Street","Other Street 2","Other Street 3","Other City","Other State","Other Postal Code","Other Country","Assistant\'s Phone","Business Fax","Business Phone","Business Phone 2","Callback","Car Phone","Company Main Phone","Home Fax","Home Phone","Home Phone 2","ISDN","Mobile Phone","Other Fax","Other Phone","Pager","Primary Phone","Radio Phone","TTY/TDD Phone","Telex","Account","Anniversary","Assistant\'s Name","Billing Information","Birthday","Categories","Children","E-mail Address","E-mail Display Name","E-mail 2 Address","E-mail 2 Display Name","E-mail 3 Address","E-mail 3 Display Name","Gender","Government ID Number","Hobby","Initials","Keywords","Language","Location","Mileage","Notes","Office Location","Organizational ID Number","PO Box","Private","Profession","Referred By","Spouse","User 1","User 2","User 3","User 4","Web Page"'."\n";



				if( isset( $_POST['export_all'] ) )

				   {

					$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY username ASC");

					while($myrow = mysql_fetch_array($result))

					   {

						$user_id = $myrow['user_id'];

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	

	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo '"","'.$username.'","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","Unfiled","","'.$myrow['user_email'].'","","","","","","","","","","","","","","","","","","","","","","","","","",""'.''."\n";

					   }



				   }

				else


				   {
	
					foreach( $_POST['user'] as $user_id )
			
					   {

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	
						$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
						$myrow = mysql_fetch_array($result);
	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo '"","'.$username.'","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","Unfiled","","'.$myrow['user_email'].'","","","","","","","","","","","","","","","","","","","","","","","","","",""'.''."\n";

			   		   }

				   }

			   } //3.2-2a.2.5 

			elseif( $_POST['export_type'] == '1&1_newsletter_csv' )

			   { //3.2-2a.2.6 

				echo '"Company","Title","First name","Last name","Address","Address (additional info)","Country","State","Zip code","City","Phone","Fax","Cell phone","E-mail","Sales tax","Customer number","Customer group","Discount level","Additional information 1","Additional information 2","Additional information 3","Additional information 4","Additional information 5"'."\n";


				if( isset( $_POST['export_all'] ) )

				   {

					$result = mysql_query("SELECT * FROM $phpbb_users ORDER BY username ASC");

					while($myrow = mysql_fetch_array($result))

					   {

						$user_id = $myrow['user_id'];

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	

	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo '"","","'.$username.'","'.$username.'","","","","","","","","","","'.$myrow['user_email'].'","","'.$myrow['user_id'].'","","","","","","",""'."\n";

					   }



				   }

				else


				   {
	
					foreach( $_POST['user'] as $user_id )
			
					   {

						if( $user_id == -1 )
			
						   {
			
							continue;
			
						   }
	
						$result = mysql_query("SELECT * FROM $phpbb_users WHERE user_id=$user_id");
						$myrow = mysql_fetch_array($result);
	
						$username = $myrow['username'];
	
						$username = str_replace( "&amp;", "&", $username );
						$username = str_replace( "&lt;", "<", $username );
						$username = str_replace( "&gt;", ">", $username );
	
						echo '"","","'.$username.'","'.$username.'","","","","","","","","","","'.$myrow['user_email'].'","","'.$myrow['user_id'].'","","","","","","",""'."\n";

			   		   }
				   }

			   } //3.2-2a.2.6 



		   } //3.2-2a.2 

		else

		   { //3.2-2a.3 

			header( "Location: $index" );
			exit();

		   } //3.2-2a.3 



	   } //3.2-2a 



	////////////////////////////////////////////////////////////////
	//
	// Check to see how to list the users, and define list variables
	//
	////////////////////////////////////////////////////////////////


	else

	   { //3.3


		//
		// Begin Set session info if not already set
		//

		if( !isset( $_SESSION['show'] ) )
		
		   {
		
			$_SESSION['show'] = "all";
		
		   }

		if( !isset( $_SESSION['show_ban'] ) )
		
		   {
		
			$_SESSION['show_ban'] = false;
		
		   }
		
		if( !isset( $_SESSION['list'] ) )
		
		   {
		
			$_SESSION['list'] = 'username';
		
		   }
		
		if( !isset( $_SESSION['order'] ) )
		
		   {
		
			$_SESSION['order'] = "ASC";
		
		   }
		
		if( !isset( $_SESSION['fullemail'] ) )
		
		   {
		
			$_SESSION['fullemail'] = "full";
		
		   }

		if( !isset( $_SESSION['search'] ) )
		
		   {
		
			$_SESSION['search'] = '';
		
		   }

		//
		// Begin Set session info if is set via get
		//

		if( isset( $_GET['list'] ) && isset( $_GET['order'] ) )

		   {

			$_SESSION['list'] = $_GET['list'];
			$_SESSION['order'] = $_GET['order'];

		   }

		if( isset( $_GET['search'] ) )

		   {

			$_SESSION['search'] = $_GET['search'];

		   }

		if( isset( $_POST['search_by'] ) )

		   {

			$_SESSION['search_by'] = $_POST['search_by'];
			$_SESSION['fullemail'] = 'full';

		   }

		//
		// Begin Set session info if is set via post
		//


		if( isset( $_POST['show'] ) )
		
		   {

			$_SESSION['start'] = 0;

			if( $_POST['show'] == 'banned' )

			   {

				$_SESSION['show_ban'] = true;
				$_SESSION['show'] = '';
				$_SESSION['show_ban_marker'] = 1;

			   }

			else

			   {
		
				$_SESSION['show'] = $_POST['show'];
				$_SESSION['show_ban'] = false;

			   }
		
		   }
		
		if( isset( $_POST['list'] ) )
		
		   {
		
			$_SESSION['list'] = $_POST['list'];
		
		   }
		
		if( isset( $_POST['order'] ) )
		
		   {
		
			$_SESSION['order'] = $_POST['order'];
		
		   }
		
		if( isset( $_POST['fullemail'] ) )
		
		   {
		
			$_SESSION['fullemail'] = $_POST['fullemail'];
		
		   }

		if( !isset( $_SESSION['limit'] ) || !isset( $_SESSION['limit_num'] ) )

		   {

			$_SESSION['limit'] = ', 25';
			$_SESSION['limit_num'] = 25;

		   }

		elseif( isset( $_POST['limit_num'] ) )

		   { //3.3--1

			$row_result = mysql_query("SELECT * FROM $phpbb_users");
			$row_count = mysql_num_rows($row_result);

			if( $_SESSION['show_ban'] == true )

			   {

				$_SESSION['limit'] = ', '.$row_count;
				$_SESSION['limit_num'] = $row_count;

			   }

			else

			   {  //3.3--2

				if( $_POST['limit_num'] == 'all' )
	
				   {

	
					$_SESSION['limit'] = ', '.$row_count;
					$_SESSION['limit_num'] = $row_count;
	
				   }
	
				else
	
				   {
	
					$_SESSION['limit'] = ', '.$_POST['limit_num'];
					$_SESSION['limit_num'] = $_POST['limit_num'];
	
				   }

			    }  //3.3--2


		   } //3.3--1

		if( isset( $_POST['limit_num'] ) && isset( $_SESSION['show_ban_marker'] )  && $_SESSION['show_ban'] == false && $_SESSION['show_ban_marker'] == 1 )

		   {

			$_SESSION['show_ban_marker'] = 0;
			$_SESSION['limit'] = ', 25';
			$_SESSION['limit_num'] = 25;

		   }

		if( !isset( $_SESSION['start'] ) )

		   {

			$_SESSION['start'] = 0;

		   }

		elseif( isset( $_GET['start'] ) )

		   {

			$_SESSION['start'] = $_GET['start'];

		   }

		if( !isset( $_SESSION['search_by'] ) )

		   {

			$_SESSION['search_by'] = 'username';

		   }

		$search_by = $_SESSION['search_by'];

 		if( $_SESSION['search'] != '' && $_SESSION['show'] != 'all' )

		   {

			$query = $_SESSION['search'];
			$search_query = " AND $search_by LIKE '%$query%'";
		   }

 		elseif( $_SESSION['search'] != '' )

		   {

			$query = $_SESSION['search'];
			$search_query = " WHERE $search_by LIKE '%$query%'";
		   }

		else

		   {

			$search_query = '';

		   }

		$db_show = $_SESSION['show'];
		$db_list = $_SESSION['list'];
		$db_order = $_SESSION['order'];
		$fullemail = $_SESSION['fullemail'];
		$limit = $_SESSION['limit'];
		$limit_num = $_SESSION['limit_num'];
		$start = $_SESSION['start'];

		if( $_SESSION['show'] == 'admin' )

		   {

			$db_show = ' WHERE user_level=1';

		   }

		elseif( $_SESSION['show'] == 'mod' )

		   {

			$db_show = ' WHERE user_level=2';

		   }

		elseif( $_SESSION['show'] == 'hidden' )

		   {

			$db_show = ' WHERE user_allow_viewonline=0';

		   }

		elseif( $_SESSION['show'] == 'inactive' )

		   {

			$db_show = ' WHERE user_active=0';

		   }

		elseif( $_SESSION['show_ban'] == true && $_SESSION['search'] != '' )

		   {

			$_SESSION['errors']['index'][] = 'The search feature cannot be used while "Show" is set to "Banned".';

		   }

		else

		   {

			$db_show = '';

		   }		



	/****************************************************************************************
	//
	//
	//
	//
	//
	// This actually lists the users
	//
	//
	//
	//
	//
	****************************************************************************************/

	//	$result = mysql_query("SELECT * FROM $phpbb_users$db_show$search_query ORDER BY $db_list $db_order LIMIT $start$limit");
		$result = mysql_query("SELECT * FROM $phpbb_users$db_show$search_query ORDER BY $db_list $db_order LIMIT $start$limit");
		$current_result = mysql_query("SELECT * FROM $phpbb_users$db_show$search_query ORDER BY $db_list $db_order");

		$row_result = mysql_query("SELECT * FROM $phpbb_users");
		$total_row_result = mysql_query("SELECT * FROM $phpbb_users");

		$listed_row_count = mysql_num_rows($result);
		$current_row_count = mysql_num_rows($total_row_result);
		$total_row_count = mysql_num_rows($total_row_result);

//		echo "$result = mysql_query(\"SELECT * FROM $phpbb_users$db_show$search_query ORDER BY $db_list $db_order LIMIT $start$limit\");";

		if( $_SESSION['show'] == 'admin' || $_SESSION['show'] == 'hidden' || $_SESSION['show'] == 'inactive' || $_SESSION['show'] == 'mod' || $_SESSION['search'] != '' )

		   {

			$row_count = mysql_num_rows($current_result);

		   }

		else

		   {

			$row_count = mysql_num_rows($row_result);

		   }

//		echo "Start: $start<br />Limit Num: $limit_num";

		if( ( $row_count - $start ) > $limit_num )

		   {

			$limit_temp1 = $start + $limit_num;

			$limit_next = '<a href="?start='.$limit_temp1.'">Next '.$limit_num.'</a>';



		   }

		else

		   {

			$limit_next = 'Next '.$limit_num.'';

		   }

		if( $start > 0 )

		   {

			$limit_first = '<a href="?start=0">First</a>';

		   }

		else

		   {

			$limit_first = 'First';

		   }

		if( $_SESSION['show'] == 'admin' || $_SESSION['show'] == 'hidden' || $_SESSION['show'] == 'inactive' || $_SESSION['show'] == 'mod' || $_SESSION['search'] != '' )

		   {

			$row_count = mysql_num_rows($current_result);

		   }

		else

		   {

			$row_count = mysql_num_rows($row_result);

		   }

		$last_counter = 1;

//		echo $last_counter * $limit_num;
//		echo "<br /> Current Row Count: $current_row_count";
//		echo "<br /> Current Row Count: $row_count";
		
		
		
//		echo "<br />Session List: ".$_SESSION['list']."<br />";


		while( ( $limit_num * $last_counter ) < $row_count )
		
		   {

			if( $last_counter > 100000 )

			   {

				echo '<br /><br /><br /><center><font size="5" color="#ff0000">$Last_Counter Exeeded 100,000, please contact <a href="mailto:starfoxtj@yahoo.com">starfoxtj@yahoo.com</a> with this error message, the number of users your board has, as well as which "view settings" you were using next to the sort button.</font></center><br /><br /><br /><br /><br /><br />';
				exit();
				break;

			    }


			$last_counter++;

		   }

// echo "<br />Row count: $row_count";

//		echo "<br />Last Counter: $last_counter<br />Total: ".$limit_num * $last_counter;

		$last_page_counter = ( $last_counter * $limit_num ) - $limit_num;
//		echo "<br />Last Page Counter: $last_page_counter";


		


		if( $limit_num >= ( $row_count - $start ) )

		   {

			$limit_last = 'Last';

		   }

		else

		   {

			$limit_last = '<a href="?start='.$last_page_counter.'">Last</a>';

		   }


//		echo "<br />Start: $start<br />Rowcount: $row_count<br />Difference:";
//		echo $row_count - $start;

		if(  $start >= $limit_num )

		   {

			$limit_temp2 = $start - $limit_num;

			$limit_previous = '<a href="?start='.$limit_temp2.'">Previous '.$limit_num.'</a>';

		   }

		else

		   {

			$limit_previous = 'Previous '.$limit_num.'';

		   }
				


		/* if( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $modrank == 'yes' ) )

		   {

			echo 'Delete: yes';

		   }
		else

		   {

			echo 'Delete: no';

		   } */


		?>

		<html>
		<head>
		<title>PHPBB Admin ToolKit v<?php echo $_SESSION['toolkitversion']; ?></title>


		<SCRIPT LANGUAGE="JavaScript">
		function placeFocus() {
		if (document.forms.length > 0) {
		var field = document.forms[0];
		for (i = 0; i < field.length; i++) {
		if ((field.elements[i].name == "password") || (field.elements[i].type == "textarea") || (field.elements[i].type.toString().charAt(0) == "s")) {
		document.forms[2].elements[i].focus();
		break;
			 }
		      }
		   }
		}


		</script>


		<script type="text/javascript">

		function boxOK(boxname) {
		var not_these = ['confirm','confirm_date','extra','clear_posts','retain_pms','double_hash'];
		var name, i = 0;
		while (name = not_these[i++]) if (name == boxname) return false;
		return true;
		}
		
		function checkUncheckAll(oCheckbox) {
		var el, i = 0, bWhich = oCheckbox.checked, oForm = oCheckbox.form;
		while (el = oForm[i++])
		if (el.type == 'checkbox' && boxOK(el.name)) el.checked = bWhich;

		}

		</script>


		</head>

		<body link="#0000ff" vlink="#0000ff" alink="#0000ff" OnLoad="placeFocus()" onload="document.forms[0].reset()">

		<?php


		echo '<center>';
		echo '<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">';
		echo '<tr><td><div align="center">'.$_SESSION['toolkit_title'].'</div></td></tr>';
		echo '<tr><td><table border="0" width="100%" cellpadding="0" cellspacing="0"><tr><td align="left">Logged in as: <b>'.$_SESSION['user_level'].'</b></td><td align="right">PHPBB Version: <b>2'.$phpbb_version.'</b></td></tr></table></td></tr></table>';



		// Begin error reporting section

		if( isset( $_SESSION['errors']['index'] ) )

		   {

			foreach( $_SESSION['errors']['index'] as $error )

			   {

				echo "<br />\n";
				echo $error;
				echo "<br />\n";

			   }

			unset( $_SESSION['errors']['index'] );

		   }


		if( isset( $_SESSION['errors']['edituser'] ) )

		   {
			foreach( $_SESSION['errors']['edituser'] as $error )

			   {

				echo "<br />\n";
				echo $error;
				echo "<br />\n";

			   }

			unset( $_SESSION['errors']['edituser'] );

		   }

		// End error reporting section

		echo '</center><br />';

		?>

		<center>
		<table>
		<table width="95%" border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">		

		 <tr>

			<td>


			<center>
			<table border="0" width="100%" bgcolor="#ffffff" cellspacing="1" cellpadding="3">

			 <tr>
				<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">

				<td width="70" valign="top">

				Show:
			
				</td>
			
				<td valign="top">
			
				<select name="show"> 
				<option value="admin"<?php if( $_SESSION['show'] == 'admin' ) { echo ' selected'; } ?>>Administrators</option>
				<option value="mod"<?php if( $_SESSION['show'] == 'mod' ) { echo ' selected'; } ?>>Moderators</option>
				<option value="hidden"<?php if( $_SESSION['show'] == 'hidden' ) { echo ' selected'; } ?>>Hidden Users</option>
				<option value="inactive"<?php if( $_SESSION['show'] == 'inactive' ) { echo ' selected'; } ?>>Inactive Users</option>
				<option value="banned"<?php if( $_SESSION['show_ban'] == true ) { echo ' selected'; } ?>>Banned Users</option>
				<option value="all"<?php if( $_SESSION['show'] == 'all' ) { echo ' selected'; } ?>>All Users</option>
				</select>
			
				</td>

				<td align="right" colspan="2">

				<?php

				if( $_SESSION['user_level'] == 'admin' )

				   {

					echo '<a href="?mode=security_scan"><font color="#ff0000"><b>Run Security Scan</a></b></font>';

				   }

				else

				   {
	
					echo '&nbsp';

				   }

				?>

				</td>
			
			 </tr>
			
			 <tr>
			
				<td valign="top">
			
				Order By:
			
				</td>
			
				<td valign="top" colspan="2">
			

				<select name="list"> 
				<option value="user_id"<?php if ( $db_list == 'user_id' ) { echo ' selected'; } ?>>User ID</option>
				<option value="username"<?php if ( $db_list == 'username' ) { echo ' selected'; } ?>>Username</option>
				<option value="user_email"<?php if ( $db_list == 'user_email' ) { echo ' selected'; } ?>>Email Address</option>
				<option value="user_posts"<?php if ( $db_list == 'user_posts' ) { echo ' selected'; } ?>>Post Count</option>
				<option value="user_level"<?php if ( $db_list == 'user_level' ) { echo ' selected'; } ?>>User Level</option>
				<option value="user_active"<?php if ( $db_list == 'user_active' ) { echo ' selected'; } ?>>Active/Inactive</option>
				<option value="user_regdate"<?php if ( $db_list == 'user_regdate' ) { echo ' selected'; } ?>>Date Joined</option>
				<option value="user_lastvisit"<?php if ( $db_list == 'user_lastvisit' ) { echo ' selected'; } ?>>Last Visit</option>
				</select>
		
				<select name="order">
				<option value="ASC"<?php if( $_SESSION['order'] == 'ASC' ) { echo ' selected'; } ?>>Ascending</option>
				<option value="DESC"<?php if( $_SESSION['order'] == 'DESC' ) { echo ' selected'; } ?>>Decending</option>
				</select>
			
				</td>

				<td align="right">

				<?php

				if( $_SESSION['user_level'] == 'admin' )

				   {

					echo '<a href="?mode=phpinfo" target="_blank">Display PHPInfo</a>';

				   }

				else

				   {
	
					echo '&nbsp';

				   }

				?>

				</td>
			
			 </tr>
			
			 <tr>
			
				<td valign="top">
			
				Emails:
			
				</td>
			
				<td valign="top" colspan="3">

				<table border="0" cellpadding="0" cellspacing="0" width="100%"> 

				<tr>

					<td valign="top" align="left">
			
					<select name="fullemail">
					<option value="full"<?php if( $_SESSION['fullemail'] == 'full' ) { echo ' selected'; } ?>>Full</option>
					<option value="short"<?php if( $_SESSION['fullemail'] == 'short' ) { echo ' selected'; } ?>>Short</option>
					</select>

					<td align="right" valign="top">

					<input type="submit" name="search_by_submit" value="Search By:" />

					<select name="search_by">
					<option value="user_id"<?php if( $_SESSION['search_by'] == 'user_id' ) { echo ' selected'; } ?>>User ID</option>
					<option value="username"<?php if( $_SESSION['search_by'] == 'username' ) { echo ' selected'; } ?>>Username</option>
					<option value="user_email"<?php if( $_SESSION['search_by'] == 'user_email' ) { echo ' selected'; } ?>>Email</option>
					<option value="user_website"<?php if( $_SESSION['search_by'] == 'user_website' ) { echo ' selected'; } ?>>Website</option>
					<option value="user_occ"<?php if( $_SESSION['search_by'] == 'user_occ' ) { echo ' selected'; } ?>>Occupation</option>
					<option value="user_interests"<?php if( $_SESSION['search_by'] == 'user_interests' ) { echo ' selected'; } ?>>Interests</option>
					<option value="user_sig"<?php if( $_SESSION['search_by'] == 'user_sig' ) { echo ' selected'; } ?>>Signiture</option>
					</select>



					<?php

					// if( $_SESSION['search_by'] == 'username' ) { echo '<a href="?search_by=user_email">Email Address</a>'; } else { echo '<a href="?search_by=username">Username</a>'; }

					?>

					</td>

				 </tr>

				</table>
					
			
				</td>
			
			 </tr>
			
			 <tr>
			
				<td valign="top">
			
				Display:
			
				</td>
			
				<td colspan="3">

				<table border="0" cellpadding="0" cellspacing="0" width="100%"> 

				<tr>

					<td valign="top">
			
					<select name="limit_num">
					<option value="25"<?php if( $_SESSION['limit_num'] == 25 ) { echo ' selected'; } ?>>25 Users</option>
					<option value="50"<?php if( $_SESSION['limit_num'] == 50 ) { echo ' selected'; } ?>>50 Users</option>
					<option value="75"<?php if( $_SESSION['limit_num'] == 75 ) { echo ' selected'; } ?>>75 Users</option>
					<option value="100"<?php if( $_SESSION['limit_num'] == 100 ) { echo ' selected'; } ?>>100 Users</option>
					<option value="150"<?php if( $_SESSION['limit_num'] == 150 ) { echo ' selected'; } ?>>150 Users</option>
					<option value="200"<?php if( $_SESSION['limit_num'] == 200 ) { echo ' selected'; } ?>>200 Users</option>
					<option value="all"<?php if( $_SESSION['limit_num'] == $row_count || $_SESSION['limit_num'] == $current_row_count ) { echo ' selected'; } ?>>All Users</option>
					</select> <input type="submit" value="Sort"></form>

					</td>

					<td align="center">

					<?php if( $_SESSION['search'] != '' ) { echo '<a href="'.$_SERVER['PHP_SELF'].'?search=">Clear Search</a>'; } ?>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;

					</td>

					<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="GET">

					<td align="right" valign="top">

					<input type="submit" value="Go">
	
					<select name="mode">
					<?php if( $_SESSION['user_level'] == 'mod' && $modban == 'no' ) { ?><option value="banlist" selected>----------</option><?php } else { ?><option value="banlist">Banlist</option><?php } ?>
					<?php if( $_SESSION['user_level'] == 'admin' ) { ?><option value="config" selected>Board Config</option><?php } ?>
					</select></form>

					</td>

				 </tr>

				</table>
			
				</td>
			
			 </tr>
			
		</table>

		<table border="0" width="100%" bgcolor="#ffffff" cellspacing="1" cellpadding="3">

		 <tr>	
			<td valign="top">
		
			<font size="2">Users: <?php echo $total_row_count.' - Listed: '.$listed_row_count; ?></font>
		
			</td>
		
			<td valign="top" colspan="3">
		
			<table border="0" cellpadding="0" cellspacing="0" width="100%"> 

			<tr>

				<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST" />

				<td align="center" valign="top">

				<?php echo $limit_first; ?> - <?php echo $limit_previous; ?>&nbsp;&nbsp;&nbsp;
				<input type="text" name="editspecificuser"<?php if( $_SESSION['search'] != '' ) { echo ' value="'.$_SESSION['search'].'"'; } ?>style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="25" maxlength="255">&nbsp;&nbsp;<input type="submit" value=" Search User ">
				
				&nbsp;&nbsp;&nbsp;<?php echo $limit_next; ?> - <?php echo $limit_last; ?></form>

				</td>

				<td align="right" valign="top">

				<a href="?mode=logout">Logout</a>

				</td>

			 </tr>

			</table>
		
			</td>
		
		 </tr>
		</table>

		<center><table width="100%" border="0" style="border:2px solid black;" bgcolor="#f5f5f5" cellspacing="1" cellpadding="3">
	

		 <tr>

			<form action="<?php echo $index; ?>" method="POST" />

			<td bgcolor="#d5d5d5" align="center" width="5%" cellpadding="5">

			<input type="checkbox" name="checkall" onclick="checkUncheckAll(this)" />

			</td>

			<td bgcolor="#d5d5d5" width="10%" cellpadding="5">

			<div align="center"><a href="?list=user_id&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>ID:</a></div>

			</td>


			<td bgcolor="#d5d5d5" width="20%" cellpadding="5">

			<div align="center"><a href="?list=username&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Username:</a></div>

			</td>

			<td bgcolor="#d5d5d5" width="20%" cellpadding="5">

			<div align="center"><a href="?list=user_email&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Email:</a></div>

			</td>


			<td bgcolor="#d5d5d5" width="8%" cellpadding="5">

			<div align="center"><a href="?list=user_posts&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Posts:</a></div>

			</td>


			<td bgcolor="#d5d5d5" width="8%" cellpadding="5">

			<div align="center"><a href="?list=user_level&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Level:</a></div>

			</td>

			<td bgcolor="#d5d5d5" width="7%" cellpadding="5">

			<div align="center"><a href="?list=user_active&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Active:</a></div>

			</td>

			<td bgcolor="#d5d5d5" width="7%" cellpadding="5">

			<div align="center"><a href="?list=user_regdate&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Joined</a></div>

			</td>

			<td bgcolor="#d5d5d5" width="7%" cellpadding="5">

			<div align="center"><a href="?list=user_lastvisit&order=<?php if( $_SESSION['order'] == 'ASC' ) { echo 'DESC'; } else { echo 'ASC'; } ?>"><b>Visit:</a></div>

			</td>


			<td bgcolor="#d5d5d5" width="10%" cellpadding="5">

			<div align="center">Ban:</div>

			</td>

		 </tr>

		<?php

		if( 0 == 0 )

		   { //3.9-1

			while( $myrow = mysql_fetch_array($result) )

			   { //3.10

				if( $myrow['user_level'] == 0 )

				   { //3.10.1

					$userlevel = "User";

				   } //3.10.1

				elseif( $myrow['user_level'] == 1 )

				   { //3.10.2

					$userlevel = "Admin";

				   } //3.10.2

				elseif( $myrow['user_level'] == 2 )

				   { //3.10.3

					$userlevel = "Mod";

				   } //3.10.3


				if( $myrow['user_active'] == 1 )

				   { //3.10.3-1

					$useractive = "Yes";

				   } //3.10.3-1

				else

				   { //3.10.3-2

					$useractive = "No";

				   } //3.10.3-2
		
				$user_id = $myrow['user_id'];
				$bantable = mysql_query("SELECT * FROM $phpbb_banlist WHERE ban_userid=$user_id");

				$banstat = '-';
				$banrow = mysql_fetch_array($bantable);

				if( isset( $banrow['ban_userid'] ) )

				   { //3.10.4

					$banstat = 'Banned';
					
					if( $_SESSION['user_level'] == "admin" )

					   { //3.10.4.1

						if( isset( $_GET['show'] ) )

						   { //3.10.4.1.1

							$banstat = '<a href="'.$_SERVER['PHP_SELF'].'?show='.$_GET['show'].'&unban='.$myrow['user_id'].'">UnBan</a>';

						   } //3.10.4.1.1

					else

						   { //3.10.4.1.2

							$banstat = '<a href="'.$_SERVER['PHP_SELF'].'?unban='.$myrow['user_id'].'">UnBan</a>';

						   } //3.10.4.1.2

					   } //3.10.4.1

					if( $_SESSION['user_level'] == "mod" && $modban == 'yes' )

					   { //3.10.4.2

						$banstat = '<a href="'.$_SERVER['PHP_SELF'].'?unban='.$myrow['user_id'].'">UnBan</a>';

					   } //3.10.4.2

				   } //3.10.4

				if( isset( $_GET['show'] ) && $_GET['show'] == "admin" )

				   { //3.10.5

					if( $myrow['user_level'] != 1 )

					   { //3.10.5.1

						continue;

					   } //3.10.5.1

				   } //3.10.5

				if( $_SESSION['show_ban'] == true )

				   { //3.10.6

					if( $banstat == "-" )

					   { //3.10.6.1

						continue;

					   } //3.10.6.1

				   } //3.10.6

				if( isset( $_GET['show'] ) && $_GET['show'] == "inactive" )

				   { //3.10.6-1

					if( $myrow['user_active'] == 1 )

					   { //3.10.6-1.1

						continue;

					   } //3.10.6-1.1


				   } //3.10.6-1

				$useremail = $myrow['user_email'];

				if( isset( $_SESSION['fullemail'] ) && $_SESSION['fullemail'] == "full" )

				   {

					$useremailshort = $useremail;
					$emaildots = "&nbsp;";

				   }

				else

				   {

					$useremailshort = substr( $useremail, 0, 10 );

					if ( strlen( $useremail ) > 10 )

					   {  //3.10.6.2

						$emaildots = "...";

					   }  //3.10.6.2

					else

					   {  //3.10.6.2

						$emaildots = "";

					   }  //3.10.6.2

				   }

				?>

				<tr>

				<td bgcolor="#e5e5e5"><div align="center"><input type="checkbox" name="user[]" value="<?php echo $myrow['user_id']; ?>" /></div></td>
				<td bgcolor="#c5c5c5"><div align="left"><?php echo $myrow['user_id']; ?></div></td>
				<td bgcolor="#e5e5e5"><div align="left"><a href="?user_id=<?php echo $myrow['user_id']; ?>"><?php echo $myrow['username']; ?></a><?php if( $myrow['user_allow_viewonline'] == 0 ) { echo ' (H)'; } ?></div></td>
				<td bgcolor="#c5C5c5" nowrap><div align="left"><?php if( $myrow['user_id'] == -1 ) { echo '<center>-</center>'; } else { ?>&nbsp;<a href="mailto:<?php echo $useremail; ?>"><?php echo $useremailshort.'</a>'; echo $emaildots; } ?></div></td>
				<td bgcolor="#e5e5e5"><div align="right"><?php echo $myrow['user_posts']; ?></div></td>
				<td bgcolor="#c5C5c5"><div align="right"><?php if( $userlevel == 'Admin' ) { echo "<font color=\"#ff0000\"><b>$userlevel</b></font>"; } elseif( $userlevel == 'Mod' ) { echo "<b>$userlevel</b>"; } else { echo $userlevel; } ?></div></td>
				<td bgcolor="#e5e5E5"><div align="center"><?php echo $useractive; ?></div></td>
				<td bgcolor="#c5C5c5" align="center" nowrap><div style="font-family: Verdana; font-size: 9px;"><?php echo date( "m/d/Y", $myrow['user_regdate'] ); ?></div></td>
				<td bgcolor="#e5e5E5" align="center" nowrap><?php if( $myrow['user_lastvisit'] == 0 ) { echo '-'; } else { echo '<div style="font-family: Verdana; font-size: 9px;">'.date( "m/d/Y", $myrow['user_lastvisit'] ).'</div>'; } ?></td>
				<td bgcolor="#c5C5c5"><div align="center"><?php echo $banstat; ?></div></td>

				</tr>

				<?php

			   } //3.10

		   } //3.9-1

		else

		   { //3.9-2

			?>

			 <tr>
				<td colspan="7">

			<br />
			<center>
			No usernames found matching your search query.
			</center>
			<br />

				</td>
			 </tr>

			<?php

		   } //3.9-2

		?>

		</table><br />

		<table width="100%" border="0" height="40" style="border:2px solid black;" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
	

		 <tr>

			<td width="5%" bgcolor="#d5d5d5" align="center">
	
			<input type="checkbox" name="checkall" onclick="checkUncheckAll(this)" />
	
			</td>

			<td width="95%" align="left" bgcolor="#e5e5e5">
	
	
			With selected:
	
			<select name="massuseraction"> 
			<option value="---" selected>----------------------------------</option>
			<option value="activate">Activate</option>
			<option value="deactivate">Deactivate</option>
			<option value="deactivate_and_drop">Deactivate & Drop Key</option><?php
	
	
			if( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $modban == 'yes' ) )
	
			   {
	
				?>
	
				<option value="ban">Ban</option>
				<option value="unban">Unban</option>
	
				<?php

			   }


			if( $_SESSION['user_level'] == 'admin' || ( $_SESSION['user_level'] == 'mod' && $modpost == 'yes' ) )
	
			   {
	
				?>

				<option value="resync">Resync Post Count</option>

				<?php

			   }
	

			if( $_SESSION['user_level'] == 'admin' )
	
			   {

				?>
	
				<option value="admin">Promote to Admin</option>
				<option value="user">Demote to User</option>
	
				<?php

		   	   }

	
			?>
			<option value="clear_sig">Clear Signiture</option>
			<option value="clear_website">Clear Website</option>
			</select>
	
			<input type="submit" value=" Go "  /><?php
	
			if( $_SESSION['user_level'] == 'admin' )
	
			   {
	
				?>
	
				&nbsp;&nbsp;&nbsp;&nbsp;If promoting to admin, click here to confirm: <input type="checkbox" name="confirm" value="yes" />
	
				<?php
	
			   }
	
			?>
	
			</td>

		 </tr>

		<?php

		if( $_SESSION['user_level'] == 'admin' || $moddelete == 'yes' )

			   {
	
			?>
	
			 <tr>
	
				<td width="5%" bgcolor="#d5d5d5" align="center">
		
				&nbsp;
		
				</td>
	
				<td bgcolor="#e5e5e5">
	
				With selected:
	
				<input type="submit" name="delete_users" value=" Delete "  /> <input type="text" name="delete_confirm" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="7" length="6" maxlength="6" /> (Type delete to confirm)&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="clear_posts" value="yes" />Clear Posts&nbsp;&nbsp;&nbsp;&nbsp;<input type="checkbox" name="retain_pms" value="yes" />Retain PMs<br />
	
	
				</td>
	
	
			 </tr>

			<?php

		   }

		?>

		<?php


		if( $_SESSION['user_level'] == 'admin' )

		   {

			?>


			 <tr>
	
				<td width="5%" bgcolor="#d5d5d5" align="center">
		
				&nbsp;
		
				</td>
	
				<td bgcolor="#e5e5e5">
	
				<?php
	
	
				$date_joined = time();
				$date_joined_ap = date( "a", $date_joined );
	
				?>
	
				With Selected: <input type="text" name="join_mm" value="<?php echo date( "m", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
				<input type="text" name="join_dd" value="<?php echo date( "d", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
				<input type="text" name="join_yy" value="<?php echo date( "Y", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="3" maxlength="4" />
				(mm/dd/yyyy)
	
	
				<input type="text" name="join_time_hh" value="<?php echo date( "h", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" />h :
				<input type="text" name="join_time_mm" value="<?php echo date( "i", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />m
				<input type="text" name="join_time_ss" value="<?php echo date( "s", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />s
				<select name="join_time_ap">
				<option value="am"<?php if( $date_joined_ap == 'am' ) { echo ' selected'; } ?>>AM</option>
				<option value="pm"<?php if( $date_joined_ap == 'pm' ) { echo ' selected'; } ?>>PM</option>
				</select>
	
				<input type="submit" name="change_date" value="Set User Joined Date" />
				&nbsp;Click here to confirm: <input type="checkbox" name="confirm_date" value="yes" />
	
				</td>
	
			 </tr>

			<?php

		   }

		?>

		<?php if( $_SESSION['user_level'] == 'admin' )

		   {

			?>

			 <tr>
	
				<td width="5%" bgcolor="#d5d5d5" align="center">
		
				&nbsp;
		
				</td>
	
				<td bgcolor="#e5e5e5">
	
				&nbsp;
	
				</td>
	
			 </tr>

			 <tr>
	
				<td width="5%" bgcolor="#d5d5d5" align="center">
		
				&nbsp;
		
				</td>
	
				<td bgcolor="#e5e5e5">
	
				Export Email list:

				<select name="export_type">
				<option value="email_only">Email Addresses Only</option>
				<option value="gmail_csv">GMail CSV Format</option>
				<option value="hotmail_csv">Hotmail CSV Format</option>
				<option value="yahoo_csv">Yahoo CSV Format</option>
				<option value="outlook_csv" selected>Outlook CSV Format</option>
				<option value="1&1_newsletter_csv">1&1 Newsletter CSV Format</option>
				</select>

				&nbsp<input type="submit" name="export_selected" value="Export Selected Users" />&nbsp;<input type="submit" name="export_all" value="Export ALL Users" />
	

	
				</td>
	
	
			 </tr>

			<?php

		   }

		?>

		 <tr>

			<td width="5%" bgcolor="#d5d5d5" align="center">
	
			&nbsp;
	
			</td>

			<td bgcolor="#e5e5e5">

			&nbsp;

			</td>

		 </tr>


		 <tr>

			</form>

			<td width="5%" bgcolor="#d5d5d5" align="center">
	
			&nbsp;
	
			</td>

			<form method="POST" action="<?php echo $index; ?>">

			<td bgcolor="#e5e5e5">

			<input type="text" name="genhash" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="25" maxlength="255">&nbsp;&nbsp;<input type="submit" value=" Generate MD5 ">&nbsp;&nbsp;Double Hash: <input type="checkbox" name="double_hash" /> <font face="arial" size="2">(Do not check this for phpbb password hashes)</font>
			<?php

			if( isset( $_POST['genhash'] ) && $_POST['genhash'] != '' && isset( $_POST['double_hash'] ) )

			   {

				echo '<br /><br />Hash: <b>'; $hash = $_POST['genhash']; echo md5( md5( $hash ) ).'</b><br />&nbsp;';

			   }

			elseif( isset( $_POST['genhash'] ) && $_POST['genhash'] != '' && !isset( $_POST['double_hash'] ) )

			   {

				echo '<br /><br />Hash: <b>'; $hash = $_POST['genhash']; echo md5( $hash ).'</b><br />&nbsp;';

			   }

			?>



			</td>
			</form>

		 </tr>

		 <tr>

			</form>

			<td width="5%" bgcolor="#d5d5d5" align="center">
	
			&nbsp;
	
			</td>

			<form method="POST" action="<?php echo $index; ?>">

			<td bgcolor="#e5e5e5">

			<?php

			$date_joined = time();
			$date_joined_ap = date( "a", $date_joined );

			?>

			<input type="text" name="join_mm" value="<?php echo date( "m", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
			<input type="text" name="join_dd" value="<?php echo date( "d", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" /> /
			<input type="text" name="join_yy" value="<?php echo date( "Y", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="3" maxlength="4" />
			(mm/dd/yyyy)


			<input type="text" name="join_time_hh" value="<?php echo date( "h", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1" maxlength="2" />h :
			<input type="text" name="join_time_mm" value="<?php echo date( "i", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />m
			<input type="text" name="join_time_ss" value="<?php echo date( "s", $date_joined ); ?>" style="border-right: black 1px solid; border-top: black 1px solid; border-left: black 1px solid; border-bottom: black 1px solid" size="1"maxlength="2" />s
			<select name="join_time_ap">
			<option value="am"<?php if( $date_joined_ap == 'am' ) { echo ' selected'; } ?>>AM</option>
			<option value="pm"<?php if( $date_joined_ap == 'pm' ) { echo ' selected'; } ?>>PM</option>
			</select>

			<input type="submit" name="gen_timestamp" value="Generate Timestamp" />

			<?php

			if( isset( $_POST['gen_timestamp'] )  )

			   {

				$time['mm'] = $_POST['join_mm'];
				$time['dd'] = $_POST['join_dd'];
				$time['yy'] = $_POST['join_yy'];

				$time['time_hh'] = $_POST['join_time_hh'];
				$time['time_mm'] = $_POST['join_time_mm'];
				$time['time_ss'] = $_POST['join_time_ss'];

				$time['time_ap'] = $_POST['join_time_ap'];


				if( !$time = make_time( $time ) )

				   {

					foreach( $_SESSION['errors']['make_time'] as $error )

					   {

						$time = $error;

					   }

					unset( $_SESSION['errors']['make_time'] );

				   }

				echo '<br /><br />Timestamp: <b>'.$time.'</b><br />&nbsp;';

			   }

			?>



			</td>
			</form>

		 </tr>

		</table>
		

		</center>

		</table>

		<?php echo $_SESSION['copyrightfooter']; ?>

		</center>

		</body>
		</html>

		<?php

		   } //3.7-1

/**************************************************

Begin Login

**************************************************/

   } //3

else

   { //4



	// Let's see someone get past this!

	session_destroy();
	//setcookie( "upload_toolkit_enabled", 'yes', 0, '/', $domain, 0 );

	?>

	<html>
	<head>
	<title>PHPBB Admin ToolKit</title>

	<SCRIPT LANGUAGE="JavaScript">
	function placeFocus() {
	if (document.forms.length > 0) {
	var field = document.forms[0];
	for (i = 0; i < field.length; i++) {
	if ((field.elements[i].name == "password") || (field.elements[i].type == "textarea") || (field.elements[i].type.toString().charAt(0) == "s")) {
	document.forms[0].elements[i].focus();
	break;
		 }
	      }
	   }
	}
	</script>
	
	</head>

	<body link="#0000ff" vlink="#0000ff" alink="#0000ff" OnLoad="placeFocus()">

	<center>
	<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
	<tr><td><div align="center"><?php echo $_SESSION['toolkit_title_nversion']; ?></div></td></tr>
	</table><br />
	</center>

	<center>
	<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
	 <tr>

		<td>

	<form action="<?php echo $_SERVER['PHP_SELF']; ?>" method="POST">
	Enter Password to Continue:<br />
	<input type="password" name="password" lengh="20" size="20" maxlengh="20">
	<br /><?php

	if( $modpassword != '' && $modpassword != 'd41d8cd98f00b204e9800998ecf8427e' )

	   {

		echo '<input type="radio" name="usertype" value="admin" checked="checked">Admin&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="usertype" value="mod">Mod<br />';

	   }

	else

	   {

		echo '<input type="hidden" name="usertype" value="admin">';

	   }

	?>

	<br /><input TYPE="submit" VALUE="   Enter   ">
	</form>

		</td>

	 </tr>
	</table>
	</center>


	<?php

	if( isset( $_SESSION['loginerror'] ) )

	   { //4.2.1

		?>

			<center>
		<table border="0" bgcolor="#ffffff" cellspacing="1" cellpadding="3">
		 <tr>

			<td>

		<br /><br /><?php echo $_SESSION['loginerror']; ?>

			</td>

		 </tr>

		</table>


		<?php		

	   } //4.2.1

	?>

	</body>
	</html>

	<?php

   } //4

?>
