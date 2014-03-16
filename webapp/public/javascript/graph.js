"use strict";

var Graph = Class.$extend({
  __init__: function(canvas) {
    this.canvas = canvas;

    this.paddingX = 0;

    this.paddingTop = 0;

    this.yStepSize = 0.25;

    this.dataSets = [];
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

    this.canvas.drawLine([left, top], [left, bottom], "#000");
    this.canvas.drawLine([left, bottom], [right, bottom], "#000");

    this.canvas.drawLine([left, top], [right, top], "#ddf");
    this.canvas.drawLine([right, top], [right, bottom], "#ddf");

    this.drawYMarkers();
  },

  drawYMarkers: function() {
    var left = 0;
    var right = 100;

    this.canvas.text([left-1, this.yCoordinateFor(0)], 0, "right");

    for (var value = this.yStepSize ; value <= this.scaleTop ; value += this.yStepSize) {
      var yCoordinate = this.yCoordinateFor(value)

      this.canvas.text([left-1, yCoordinate], value, "right");

      this.canvas.drawLine([left, yCoordinate], [right, yCoordinate], "#ddf");
    }
  },

  data: function(dataPoints) {
    var pointsWithDefaults = _.defaults(dataPoints, { type: "line" });

    this.dataSets.push(pointsWithDefaults);
  },

  popupValue: function(element, value) {
    this.canvas.drawPopup( element, value );
  },

  hidePopup: function() {
    this.canvas.hidePopup();
  },

  drawDataSets: function() {
    var self = this;

    this.numberOfPoints = _.max(_.map(this.dataSets, function(d) { return d.length; }));

    _.each(this.dataSets, function(dataSet) {
      var mappedDataPoints = _.map(dataSet, function(point, i) {
        var mappedPoint = [];

        mappedPoint[0] = self.xCoordinateFor(i);
        mappedPoint[1] = self.yCoordinateFor(point);

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

  entryWidth: function() {
    var widthMinusPadding = 100 - 2*this.paddingX;

    return (widthMinusPadding/this.numberOfPoints);
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
