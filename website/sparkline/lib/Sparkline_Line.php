<?php
/*
 * Sparkline PHP Graphing Library
 * Copyright 2004 James Byers <jbyers@users.sf.net>
 * http://sparkline.org
 *
 * Sparkline is distributed under a BSD License.  See LICENSE for details.
 *
 * $Id: Sparkline_Line.php,v 1.1 2005/03/31 22:58:54 frabcus Exp $
 *
 */

require_once('Sparkline.php');

class Sparkline_Line extends Sparkline {

  var $dataSeries;
  var $dataSeriesStats;
  var $dataSeriesConverted;
  var $yMin;
  var $yMax;

  ////////////////////////////////////////////////////////////////////////////
  // constructor
  //
  function Sparkline_Line($catch_errors = true) {
    parent::Sparkline($catch_errors);

    $this->dataSeries          = array();
    $this->dataSeriesStats     = array();
    $this->dataSeriesConverted = array();
  } // function Sparkline

  ////////////////////////////////////////////////////////////////////////////
  // data setting
  //
  function SetData($x, $y, $series = 1) {
    $x = trim($x);
    $y = trim($y);

    $this->Debug("Sparkline_Line :: SetData($x, $y, $series)", DEBUG_SET);

    if (!is_numeric($x) || 
        !is_numeric($y)) {
      $this->Debug("Sparkline_Line :: SetData rejected values($x, $y) in series $series", DEBUG_WARNING);
      return false;
    } // if

    $this->dataSeries[$series][$x] = $y;
   
    if (!isset($this->dataSeriesStats[$series]['min']) ||
        $y < $this->dataSeriesStats[$series]['min']) {
      $this->dataSeriesStats[$series]['min'] = $y;
    }

    if (!isset($this->dataSeriesStats[$series]['max']) ||
        $y > $this->dataSeriesStats[$series]['max']) {
      $this->dataSeriesStats[$series]['max'] = $y;
    }
  } // function SetData

  function SetYMin($value) {
    $this->Debug("Sparkline_Line :: SetYMin($value)", DEBUG_SET);
    $this->yMin = $value;
  }

  function SetYMax($value) {
    $this->Debug("Sparkline_Line :: SetYMax($value)", DEBUG_SET);
    $this->yMax = $value;
  }

  function ConvertDataSeries($series, $xBound, $yBound) {
    $this->Debug("Sparkline_Line :: ConvertDataSeries($series, $xBound, $yBound)", DEBUG_CALLS);

    if (!isset($this->yMin)) {
      $this->yMin = $this->dataSeriesStats[$series]['min'];
    }

    if (!isset($this->yMax)) {
      $this->yMax = $this->dataSeriesStats[$series]['max'] + $offset;
    }

    $offset = $this->yMin * -1;

    for ($i = 0; $i < sizeof($this->dataSeries[$series]); $i ++) {
      $y = round(($this->dataSeries[$series][$i] + $offset) * ($yBound / $this->yMax));
      $x = round($i * $xBound / sizeof($this->dataSeries[$series]));
      $this->dataSeriesConverted[$series][$x] = $y;
    }
  } // function ConvertDataSeries

  ////////////////////////////////////////////////////////////////////////////
  // rendering
  //
  function Render($x, $y) {
    $this->Debug("Sparkline_Line :: Render($x, $y)", DEBUG_CALLS);

    if (!parent::Init($x, $y)) {
      return false;
    }

    // convert based on actual canvas size
    //
    $this->ConvertDataSeries(1, $this->GetGraphWidth(), $this->GetGraphHeight());

    // stats debugging
    //
    $this->Debug('Sparkline_Line :: Draw' . 
                 ' series: 1 min: ' . $this->dataSeriesStats[1]['min'] . 
                 ' max: ' . $this->dataSeriesStats[1]['max'] . 
                 ' offset: ' . ($this->dataSeriesStats[1]['min'] * -1) . 
                 ' height: ' . $this->GetGraphHeight() . 
                 ' yfactor: ' . ($this->GetGraphHeight() / ($this->dataSeriesStats[1]['max'] + ($this->dataSeriesStats[1]['min'] * -1))));

    $this->DrawBackground();

    for ($i = 0; $i < sizeof($this->dataSeriesConverted[1]) - 1; $i++) {
      $this->DrawLine($i, $this->dataSeriesConverted[1][$i], $i+1, $this->dataSeriesConverted[1][$i+1], 'black');
    }
  } // function Render

  function RenderResampled($x, $y) {
    $this->Debug("Sparkline_Line :: RenderResampled($x, $y)", DEBUG_CALLS);

    if (!parent::Init($x, $y)) {
      return false;
    }

    // draw background on standard image in case of resample blit miss
    //
    $this->DrawBackground($this->imageHandle);

    // convert based on virtual canvas: x based on size of dataset, y scaled proportionately
    //
    $xVC = sizeof($this->dataSeries[1]);
    $yVC = floor($xVC * ($this->GetGraphHeight() / $this->GetGraphWidth()));
    $this->ConvertDataSeries(1, $xVC, $yVC);

    // stats debugging
    //
    $this->Debug('Sparkline_Line :: DrawResampled' . 
                 ' series: 1 min: ' . $this->dataSeriesStats[1]['min'] . 
                 ' max: ' . $this->dataSeriesStats[1]['max'] . 
                 ' offset: ' . ($this->dataSeriesStats[1]['min'] * -1) . 
                 ' height: ' . $this->GetGraphHeight() . 
                 ' yfactor: ' . ($this->GetGraphHeight() / ($this->dataSeriesStats[1]['max'] + ($this->dataSeriesStats[1]['min'] * -1))), DEBUG_STATS);

    // create virtual image
    // allocate colors
    // draw background, graph
    // resample and blit onto original graph
    //
    $imageVCHandle = $this->CreateImageHandle($xVC, $yVC);

    while (list($k, $v) = each($this->colorList)) {
      $this->SetColorHandle($k, $this->DrawColorAllocate($k, $imageVCHandle));
    }
    reset($this->colorList);

    $this->DrawBackground($imageVCHandle);

    for ($i = 0; $i < sizeof($this->dataSeriesConverted[1]) - 1; $i++) {
      $this->DrawLine($i, $this->dataSeriesConverted[1][$i], $i+1, $this->dataSeriesConverted[1][$i+1], 'black', $this->GetLineSize(), $imageVCHandle);
    }

    $this->DrawImageCopyResampled($this->imageHandle, 
                                  $imageVCHandle, 
                                  0, 0,                    // dest x, y
                                  0, 0,                    // src x, y
                                  $this->GetGraphWidth(),  // dest width
                                  $this->GetGraphHeight(), // dest height
                                  $xVC,                    // src  width
                                  $yVC);                   // src  height
  } // function RenderResampled
} // class Sparkline_Line

?>
