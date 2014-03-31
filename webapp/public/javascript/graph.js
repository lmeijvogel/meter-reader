"use strict";

var Graph = Class.$extend({
  __init__: function(canvas) {
    this.canvas = canvas;

    this.paddingX = 0;

    this.paddingTop = 0;

    this.yStepSize = 0.25;

    this.dataSets = [];
  },

  setPeriodSize: function(periodSize) {
    this.periodSize = periodSize;
  },

  draw: function() {
    this.drawAxes();
    this.drawDataSets();
  },


  drawAxes: function() {
    var left = 0;
    var top = 0;
    var bottom = 100;
    var right = 100;

    this.canvas.drawLine(Point(left, top), Point(left, bottom), "#000");
    this.canvas.drawLine(Point(left, bottom), Point(right, bottom), "#000");

    this.canvas.drawLine(Point(left, top), Point(right, top), "#ddf");
    this.canvas.drawLine(Point(right, top), Point(right, bottom), "#ddf");

    this.drawXMarkers();
    this.drawYMarkers();
  },

  drawXMarkers: function() {
    var top = 0;
    var bottom = 105;

    for (var i = 0 ; i < 24 ; i++) {
      var xCoordinate = this.xCoordinateFor(i);

      this.canvas.text(Point(xCoordinate, bottom), i, "right");
    }
  },

  drawYMarkers: function() {
    var left = 0;
    var right = 100;

    this.canvas.text(Point(left-1, this.yCoordinateFor(0)), 0, "right");

    for (var value = this.yStepSize ; value <= this.scaleTop ; value += this.yStepSize) {
      var yCoordinate = this.yCoordinateFor(value)

      this.canvas.text(Point(left-1, yCoordinate), value, "right");

      this.canvas.drawLine(Point(left, yCoordinate), Point(right, yCoordinate), "#ddf");
    }
  },

  data: function(dataPoints) {
    this._numberOfPointsCache = null;

    var pointsWithDefaults = _.defaults(dataPoints, { type: "line" });

    this.dataSets.push(pointsWithDefaults);
  },

  interpolations: function(dataPoints) {
    this.interpolationData = dataPoints;
  },

  popupValue: function(element, value) {
    this.canvas.drawPopup( element, value );
  },

  hidePopup: function() {
    this.canvas.hidePopup();
  },

  drawDataSets: function() {
    var self = this;

    _.each(this.dataSets, function(dataSet) {
      var mappedDataPoints = _.map(dataSet, function(point, i) {
        var mappedPoint = Point(
          self.xCoordinateFor(i),
          self.yCoordinateFor(point),
          self.interpolationData[i]
        );

        return mappedPoint;
      });

      switch(dataSet.type) {
        case 'line':
          self.canvas.drawLines(mappedDataPoints, dataSet.color, dataSet);
          break;
        case 'bar':
          self.canvas.drawBars(mappedDataPoints, self.entryWidth(), dataSet.color);
          break;
        default:
          throw "Unknown chart type: "+dataSet.type;
          break;
      }
    });
  },

  xCoordinateFor: function( x ) {
    return this.paddingX + (x+0.5)*this.entryWidth();
  },

  yCoordinateFor: function( y ) {
    if (this.max() != 0) {
      this.scaleTop = (Math.ceil(this.max() / this.yStepSize)) * this.yStepSize;
    }

    return 100 - ((y/this.scaleTop)*(100-this.paddingTop));
  },

  numberOfPoints: function() {
    if (!this._numberOfPointsCache) {
      this._numberOfPointsCache = _.max(_.map(this.dataSets, function(d) { return d.length; }));
    }

    return this._numberOfPointsCache;
  },

  entryWidth: function() {
    var widthMinusPadding = 100 - 2*this.paddingX;

    return (widthMinusPadding/this.numberOfPoints());
  },

  max: function() {
    if (this.maxY) {
      return this.maxY;
    }

    var allPoints = _.flatten(this.dataSets);

    this.maxY = _.max(allPoints);

    return this.maxY;
  },

  clear: function() {
    this.maxY = undefined;
    this.dataSets = [];
    this.canvas.$svg.html("");
  }
});
