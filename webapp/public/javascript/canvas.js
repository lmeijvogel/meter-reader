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
    this.marginBottom = 10;

  },

  drawLine: function( point1, point2, color ) {
    var element = this.elementWithAttributes("line", {
      x1:      this.x(point1[0]),
      y1:      this.y(point1[1]),
      x2:      this.x(point2[0]),
      y2:      this.y(point2[1]),
      stroke:  color
    });

    this.svg.appendChild(element);
  },

  drawLines: function(points, color) {
    if (points.length == 0){
      return;
    }

    var self = this;

    var strokeStyle = color || "#000";

    var prev = points.shift();

    var circles = [prev];

    _.each(points, function(point, i) {
      self.drawLine(prev, point, strokeStyle);

      circles.push(point);

      prev = point;
    });

    _.each(circles, function(position) {
      self.circle(position);
    });
  },

  drawBars: function(points, width, color) {
    if (points.length == 0){
      return;
    }

    var self = this;

    var fillStyle = color || "#000";

    _.each(points, function(point, i) {
      self.bar(point, width, fillStyle);
    });
  },

  bar: function(point, width, fillStyle) {
    var height = this.y(100-point[1]) - this.marginBottom; // -1 to prevent overwriting the bottom line

    height = Math.max(0, height);
    
    var barWidth = (width*this.canvasWidth())/100;

    var bar = this.elementWithAttributes("rect", {
      x: this.x(point[0])-(barWidth / 2),
      y: this.y(point[1]),
      width: barWidth,
      height: height,
      fill: fillStyle,
    });

    this.svg.appendChild(bar);
  },

  circle: function( center ) {
    var circle = this.elementWithAttributes("circle", {
      cx: this.x(center[0]),
      cy: this.y(center[1]),
      r: 6,
      "stroke-width": "3",
      stroke: "#fff",
      fill: "#000",
    });

    this.svg.appendChild(circle);
  },

  text: function( point, text, align ) {
    var textElement = this.elementWithAttributes("text", {
      x: this.x(point[0]),
      y: this.y(point[1]),
      "text-anchor": "end"
    });

    textElement.textContent = text;

    this.svg.appendChild(textElement);
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
