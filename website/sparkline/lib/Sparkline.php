<?php
/*
 * Sparkline PHP Graphing Library
 * Copyright 2004 James Byers <jbyers@users.sf.net>
 * http://sparkline.org
 *
 * Sparkline is distributed under a BSD License.  See LICENSE for details.
 *
 * $Id: Sparkline.php,v 1.2 2005/03/31 23:29:25 theyworkforyou Exp $
 *
 */

require_once('sparkline/lib/Object.php');

class Sparkline extends Object {

  var $imageX;
  var $imageY;
  var $imageHandle;
  var $colorList;
  var $colorBackground;
  var $lineSize;

  ////////////////////////////////////////////////////////////////////////////
  // constructor
  //
  function Sparkline($catch_errors = true) {
    parent::Object($catch_errors);

    $this->colorList       = array();
    $this->colorBackground = 'white';
    $this->lineSize        = 1;
  } // function Sparkline

  ////////////////////////////////////////////////////////////////////////////
  // init
  //
  function Init($x, $y) {
    $this->Debug("Sparkline :: Init($x, $y)", DEBUG_CALLS);

    $this->imageX = $x;
    $this->imageY = $y;
    
    $this->imageHandle = $this->CreateImageHandle($x, $y);

    // load default colors; set all color handles
    //
    $this->SetColorDefaults();
    while (list($k, $v) = each($this->colorList)) {
      $this->SetColorHandle($k, $this->DrawColorAllocate($k, $this->imageHandle));
    }
    reset($this->colorList);

    if ($this->IsError()) {
      return false;
    } else {
      return true;
    }
  } // function Init

  ////////////////////////////////////////////////////////////////////////////
  // color, drawing setup functions
  //
  function SetColor($name, $r, $g, $b) {
    $this->Debug("Sparkline :: SetColor('$name', $r, $g, $b)", DEBUG_SET);
    $name = strtolower($name);
    $this->colorList[$name] = array('rgb' => array($r, $g, $b));
  } // function SetDecColor

  function SetColorHandle($name, $handle) {
    $this->Debug("Sparkline :: SetColorHandle('$name', $handle)", DEBUG_SET);
    $name = strtolower($name);
    if (array_key_exists($name, $this->colorList)) {
      $this->colorList[$name]['handle'] = $handle;
      return true;
    } else {
      return false;
    }
  } // function SetColorHandle

  function SetColorHex($name, $r, $g, $b) {
    $this->Debug("Sparkline :: SetColorHex('$name', $r, $g, $b)", DEBUG_SET);
    $this->SetColor($name, hexdec($r), hexdec($g), hexdec($b));
  } // function SetHexColor

  function SetColorHtml($name, $rgb) {
    $this->Debug("Sparkline :: SetColorHtml('$name', '$rgb')", DEBUG_SET);
    $rgb = trim($rgb, '#');
    $this->SetColor($name, hexdec(substr($rgb, 0, 2)), hexdec(substr($rgb, 2, 2)), hexdec(substr($rgb, 4, 2)));
  } // function SetHexColor

  function SetColorBackground($name) {
    $this->Debug("Sparkline :: SetColorBackground('$name')", DEBUG_SET);
    $this->colorBackground = $name;
  } // function SetColorBackground

  function GetColor($name) {
    if (array_key_exists($name, $this->colorList)) {
      return $this->colorList[$name]['rgb'];
    } else {
      return false;
    }
  } // function GetColor

  function GetColorHandle($name) {
    $name = strtolower($name);
    if (array_key_exists($name, $this->colorList)) {
      return $this->colorList[$name]['handle'];
    } else {
      $this->Debug("Sparkline :: GetColorHandle color '$name' not set", DEBUG_WARNING);
      return false;
    }
  } // function GetColorHandle

  function SetColorDefaults() {
    $this->Debug("Sparkline :: SetColorDefaults()", DEBUG_SET);
    $colorDefaults = array(array('aqua',   '#00FFFF'),
                           array('black',  '#010101'), // TODO failure if 000000?
                           array('blue',   '#0000FF'),
                           array('fuscia', '#FF00FF'),
                           array('gray',   '#808080'),
                           array('grey',   '#808080'),
                           array('green',  '#008000'),
                           array('lime',   '#00FF00'),
                           array('maroon', '#800000'),
                           array('navy',   '#000080'),
                           array('olive',  '#808000'),
                           array('purple', '#800080'),
                           array('red',    '#FF0000'),
                           array('silver', '#C0C0C0'),
                           array('teal',   '#008080'),
                           array('white',  '#FFFFFF'),
                           array('yellow', '#FFFF00'));
    while (list(, $v) = each($colorDefaults)) {
      if (!array_key_exists($v[0], $this->colorList)) {
        $this->SetColorHtml($v[0], $v[1]);
      }
    }
  } // function SetColorDefaults

  function SetLineSize($size) {
    $this->lineSize = $size;
  } // function SetLineSize

  function GetLineSize() {
    return($this->lineSize);
  } // function GetLineSize

  ////////////////////////////////////////////////////////////////////////////
  // canvas setup
  //
  function CreateImageHandle($x, $y) {

    $this->Debug("Sparkline :: CreateImageHandle($x, $y)", DEBUG_CALLS);

    $handle = @imagecreatetruecolor($x, $y);
    if (!is_resource($handle)) {
      $handle = imagecreate($x, $y);
      $this->Debug('imagecreatetruecolor unavailable', DEBUG_WARNING);
    }

    if (!is_resource($handle)) {
      $this->Debug('imagecreate unavailable', DEBUG_WARNING);
      $this->Error('could not create image; GD imagecreate functions unavailable');
    }

    return $handle;
  } // function CreateImageHandle

  ////////////////////////////////////////////////////////////////////////////
  // drawing primitives
  //
  // NB: all drawing primitives use the coordinate system where (0,0) 
  //     corresponds to the bottom left of the image, unlike y-inverted 
  //     PHP gd functions
  //
  function DrawBackground($handle = false) {

    $this->Debug("Sparkline :: DrawBackground()", DEBUG_DRAW);

    if (!$this->IsError()) {
      if ($handle === false) $handle = $this->imageHandle;
      return $this->DrawRectangleFilled(0, 
                                        0, 
                                        imagesx($handle) - 1,
                                        imagesy($handle) - 1,
                                        $this->colorBackground,
                                        $handle);
    }
  } // function DrawBackground

  function DrawColorAllocate($color, $handle = false) {

    $this->Debug("Sparkline :: DrawColorAllocate('$color')", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorRGB = $this->GetColor($color)) {
      if ($handle === false) $handle = $this->imageHandle;
      return imagecolorallocate($handle,
                                $colorRGB[0], 
                                $colorRGB[1], 
                                $colorRGB[2]);
    }
  } // function DrawColorAllocate

  function DrawFill($x, $y, $color, $handle = false) {

    $this->Debug("Sparkline :: DrawFill($x, $y, '$color')", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      if ($handle === false) $handle = $this->imageHandle;
      return imagefill($handle,
                       $x, 
                       $this->CyGdToSl($y, $handle), 
                       $colorHandle);
    }
  } // function DrawFill

  function DrawLine($x1, $y1, $x2, $y2, $color, $thickness = 1, $handle = false) {

    $this->Debug("Sparkline :: DrawLine($x1, $y1, $x2, $y2, '$color', $thickness)", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      if ($handle === false) $handle = $this->imageHandle;

      imagesetthickness($handle, $thickness);
      $result = imageline($handle, 
                          $x1,
                          $this->CyGdToSl($y1, $handle),
                          $x2,
                          $this->CyGdToSl($y2, $handle),
                          $colorHandle);
      imagesetthickness($handle, 1);
      return $result;
    }
  } // function DrawLine

  function DrawPoint($x, $y, $color, $handle = false) {

    $this->Debug("Sparkline :: DrawPoint($x, $y, '$color')", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      if ($handle === false) $handle = $this->imageHandle;
      return imagesetpixel($handle, 
                           $x, 
                           $this->CyGdToSl($y, $handle), 
                           $colorHandle);
    }
  } // function DrawPoint

  function DrawRectangle($x1, $y1, $x2, $y2, $color, $handle = false) {

    $this->Debug("Sparkline :: DrawRectangle($x1, $y1, $x2, $y2 '$color')", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      if ($handle === false) $handle = $this->imageHandle;
      return imagerectangle($handle, 
                            $x1, 
                            $this->CyGdToSl($y1, $handle), 
                            $x2, 
                            $this->CyGdToSl($y2, $handle), 
                            $colorHandle);
    }
  } // function DrawRectangle

  function DrawRectangleFilled($x1, $y1, $x2, $y2, $color, $handle = false) {

    $this->Debug("Sparkline :: DrawRectangleFilled($x1, $y1, $x2, $y2 '$color')", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      // NB: switch y1, y2 post conversion
      //
      if ($y1 < $y2) {
        $yt = $y1;
        $y1 = $y2;
        $y2 = $yt;
      }

      if ($handle === false) $handle = $this->imageHandle;
      return imagefilledrectangle($handle, 
                                  $x1,
                                  $this->CyGdToSl($y1, $handle),
                                  $x2,
                                  $this->CyGdToSl($y2, $handle),
                                  $colorHandle);
    }
  } // function DrawRectangleFilled

  function DrawCircleFilled($x, $y, $radius, $color, $handle = false) {

    $this->Debug("Sparkline :: DrawCircleFilled($x, $y, $radius, '$color')", DEBUG_DRAW);

    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      if ($handle === false) $handle = $this->imageHandle;
      return imagefilledellipse($handle, 
                                $x,
                                $this->CyGdToSl($y, $handle),
                                $radius,
                                $radius,
                                $colorHandle);
    }
  } // function DrawCircleFilled

  function DrawText($string, $x, $y, $color, $font = 1, $handle = false) {
    
    $this->Debug("Sparkline :: DrawText('$string', $x, $y, '$color', $font)", DEBUG_DRAW);
      
    if (!$this->IsError() &&
        $colorHandle = $this->GetColorHandle($color)) {
      // adjust for font height so x,y corresponds to bottom left of font
      //
      if ($handle === false) $handle = $this->imageHandle;
      return imagestring($handle, 
                         $font, 
                         $x,
                         $this->CyGdToSl($y + imagefontheight($font), $handle),
                         $string,
                         $colorHandle);
    }
  } // function DrawText

  function DrawImageCopyResampled($dhandle, $shandle, $dx, $dy, $sx, $sy, $dw, $dh, $sw, $sh) {
    $this->Debug("Sparkline :: DrawImageCopyResampled($dhhandle, $shandle, $dx, $dy, $sx, $sy, $dw, $dh, $sw, $sh)", DEBUG_DRAW);
    if (!$this->IsError()) {
      return imagecopyresampled($dhandle,  // dest handle
                                $shandle,  // src  handle
                                $dx, $dy,  // dest x, y
                                $sx, $sy,  // src  x, y
                                $dw, $dh,  // dest w, h
                                $sw, $sh); // src  w, h
    }
  } // function DrawImageCopyResampled
  
  ////////////////////////////////////////////////////////////////////////////
  // coordinate system functions
  //
  function CyGdToSl($y, $handle) {
    return imagesy($handle) - 1 - $y;
  } // function CyGdToSl

  function GetGraphWidth() {
    return $this->imageX;
  } // function GetGraphWidth

  function GetGraphHeight() {
    return $this->imageY;
  } // function GetGraphHeight

  ////////////////////////////////////////////////////////////////////////////
  // other
  //
  function GetWidth() {
    return $this->imageX;
  } // function GetWidth

  function GetHeight() {
    return $this->imageY;
  } // function GetHeight

  ////////////////////////////////////////////////////////////////////////////
  // image output
  //
  function Output($file = '') {

    $this->Debug("Sparkline :: Output($file)", DEBUG_CALLS);

    if ($this->IsError()) {
      $colorError = imagecolorallocate($this->imageHandle, 0xFF, 0x00, 0x00);
      imagestring($this->imageHandle, 
                  1, 
                  ($this->imageX / 2) - (5 * imagefontwidth(1) / 2), 
                  ($this->imageY / 2) - (imagefontheight(1) / 2), 
                  "ERROR", 
                  $colorError);
    }

    if ($file == '') {
      header('Content-type: image/png');
      imagepng($this->imageHandle);
    } else {
      imagepng($this->imageHandle, $file);
    }

    $this->Debug('Sparkline :: Output - total execution time: ' . round($this->microTimer() - $this->startTime, 4) . ' seconds', DEBUG_STATS);
  } // function Output

  function OutputToFile($file) {
    $this->Output($file);
  } // function OutputToFile

} // class Sparkline

?>
