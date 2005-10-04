<?
#require_once "common.inc";
#include "account/user.inc";

phpinfo();

include "DifferenceEngine.inc";

#$df  = new WordLevelDiff(array("hello", "Hello this loses the life", "mouse", "humbug"),
#                         array("hello", "Hello this wins the life", "cheese", "humbug"));
#$df  = new WordLevelDiff(array("NO Hello this loses the life"),
#                         array("Hello this wins the life"));
$df  = new WordLevelDiff(array('<p>The Aye-voters failed to remove the words <i>and written ministerial statements</i> from the motion:</p> <p class="indent">This House takes note of the <a href="http://www.publications.parliament.uk/pa/cm200102/cmselect/cmproced/622/62202.htm">Third Report from the Procedure Committee, <i>Parliamentary Questions,</i> House of Commons Paper No. 622</a>, and the Government Response thereto, <a href="http://www.hmso.gov.uk/information/cmpapers/cm_5600.htm">Cm 5628</a>, and approves the proposals in both for a quota on named day questions, a reduction in the daily quota of questions per department, the introduction of electronic tabling subject to safeguards to ensure the authenticity of questions and the power of the Speaker to modify or halt the system if it appears it is being abused, and the timing and printing of answers to written questions <i>and written ministerial statements</i>.</p> <p>This would have meant that ministers wouldnt be able to email their Ministerial Statements to the House.</p>'), array('<p>The Aye-voters failed to remove the words <i>and written ministerial statements</i> from the motion:</p> <p class="indent">This House takes note of the <a href="http://www.publications.parliament.uk/pa/cm200102/cmselect/cmproced/622/62202.htm">Third Report from the Procedure Committee, <i>Parliamentary Questions,</i> House of Commons Paper No. 622</a>, and the Government Response thereto, <a href="http://www.hmso.gov.uk/information/cmpapers/cm_5600.htm">Cm 5628</a>, and approves the proposals in both for a quota on named day questions, a reduction in the daily quota of questions per department, the introduction of electronic tabling subject to dangerguards to ensure the authenticity of questions and the power of the Speaker to modify or halt the system if it appears it is being abused, and the timing and printing of answers to written questions <i>and written ministerial statements</i>.</p> <p>This would have meant that ministers wouldnt be able to email their Ministerial Statements to the House.</p>'));

#$tdf = new TableDiffFormatter();
#print "<table>";
#print $tdf->format($df);
#print "</table>";

$del = $df->orig();
$add = $df->closing();

include "config.php";
include "header.inc";
print "<p>-----------------------<p>";
print($del[0]);
print "<p>-----------------------<p>";
print($add[0]);
print "<p>-----------------------<p>";
exit;

while ( $line = array_shift( $del ) ) {
    $aline = array_shift( $add );
    print( '<tr>' . $this->deletedLine( $line ) .
      $this->addedLine( $aline ) . "</tr>\n" );
}
$this->_added( $add ); # If any leftovers

?>
