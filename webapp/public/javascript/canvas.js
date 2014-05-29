"use strict";

var svgns = "http://www.w3.org/2000/svg";

var Canvas = Class.$extend({
  __init__: function(svg_selector) {
    this.svg = document.getElementById(svg_selector);
    this.$svg = jQuery("#"+svg_selector);
    this.svgDoc = this.svg.ownerDocument;

    this.width = this.$svg.width();
    this.height = this.$svg.height();

    this.marginLeft = 40;
    this.marginRight = 10;
    this.marginTop = 10;
    this.marginBottom = 30;
  },

  drawLine: function( point1, point2, color ) {
    var element = this.elementWithAttributes("line", {
      x1:      this.x(point1.x),
      y1:      this.y(point1.y),
      x2:      this.x(point2.x),
      y2:      this.y(point2.y),
      stroke:  color
    });

    this.svg.appendChild(element);
  },

  drawLines: function(points, color, data) {
    if (points.length == 0){
      return;
    }

    var self = this;

    var strokeStyle = color || "#000";

    var prev = points.shift();

    var circles = [[prev, data.x]];

    _.each(points, function(point, i) {
      var thisStrokeStyle = point.interpolated ? "#999" : strokeStyle;
      self.drawLine(prev, point, thisStrokeStyle);

      circles.push([point, data[i+1]]);

      prev = point;
    });

    _.each(circles, function(circle) {
      var thisFillStyle = circle[0].interpolated ? "#bbb" : "#000";
      self.circle(circle[0], circle[1], thisFillStyle);
    });
  },

  drawBars: function(points, width, color) {
    if (points.length == 0){
      return;
    }

    var self = this;

    var fillStyle = color || "#000";

    _.each(points, function(point, i) {
      var thisFillStyle = point.interpolated ? "#bbb" : fillStyle;

      self.bar(point, width, thisFillStyle);
    });
  },

  bar: function(point, width, fillStyle) {
    var height = this.y(100) - this.y(point.y) - 1; // -1 to not draw over the bottom bar

    height = Math.max(0, height);
    
    var barWidth = (width*this.canvasWidth())/100;

    var bar = this.elementWithAttributes("rect", {
      x: this.x(point.x)-(barWidth / 2),
      y: this.y(point.y),
      width: barWidth,
      height: height,
      fill: fillStyle,
    });

    this.svg.appendChild(bar);
  },

  circle: function( center, value, fillStyle ) {
    var x = this.x(center.x);
    var y = this.y(center.y);

    var circle = this.elementWithAttributes("circle", {
      cx: x,
      cy: y,
      r: 6,
      "stroke-width": "3",
      stroke: "#fff",
      fill: fillStyle
    });

    var hoverOverlay = this.elementWithAttributes("circle", {
      cx: x,
      cy: y,
      r: 12,
      "fill-opacity": 0.0,
      "data-value": value
    });

    this.svg.appendChild(circle);
    this.svg.appendChild(hoverOverlay);
  },

  text: function( point, text, align ) {
    var x = this.x(point.x);
    var y = this.y(point.y);
    var textElement = this.elementWithAttributes("text", {
      x: x,
      y: y,
      "text-anchor": "end"
    });

    textElement.textContent = text;

    this.svg.appendChild(textElement);
  },

  drawPopup: function( element, value ) {
    var $element = $(element);

    var height = 40;

    var elementX = parseInt($element.attr('cx'), 10);
    var elementY = parseInt($element.attr('cy'), 10);
    var x = elementX + 10;
    var y = elementY - height/2;

    this.popup = this.elementWithAttributes("g", {
      x: x,
      y: y,
      width: 200,
      height: height,
    });

    var rect = this.elementWithAttributes("rect", {
      x: x,
      y: y,
      width: 200,
      height: height,
      fill: "#ffd",
      stroke: "#000"
    });

    var text = this.elementWithAttributes("text", {
      x: x+5,
      y: y + height/2,
      "alignment-baseline": "middle"
    });

    text.textContent = value;

    var line = this.elementWithAttributes("line", {
      x1: elementX,
      y1: elementY,
      x2: this.x(0),
      y2: elementY,
      stroke: "#66f"
    });

    this.popup.appendChild(line);
    this.popup.appendChild(rect);
    this.popup.appendChild(text);

    this.svg.appendChild(this.popup);
  },

  hidePopup: function() {
    this.svg.removeChild(this.popup);
  },

  clear: function() {
    this.$svg.html("");
  },

  // private
  x: function(coordinate) {
    return this.marginLeft + 0.5+(coordinate/100)*this.canvasWidth();
  },

  y: function(coordinate) {
    return this.marginTop + 0.5+(coordinate/100)*this.canvasHeight();
  },

  canvasWidth: function() {
    return (this.width - this.marginLeft - this.marginRight);
  },

  canvasHeight: function() {
    return (this.height - this.marginTop - this.marginBottom);
  },

  elementWithAttributes: function( type, attributes ) {
    var element = this.svgDoc.createElementNS(svgns, type);

    _.each(_.keys(attributes), function(key) {
      var value = attributes[key];

      element.setAttributeNS(null, key, value);
    });

    return element;
  }
});


var Point = Class.$extend({
  __init__: function(x, y, interpolated) {
    this.x = x;
    this.y = y;
    this.interpolated = interpolated;
  }
});
