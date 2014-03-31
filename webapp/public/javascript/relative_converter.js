"use strict";

var RelativeConverter = Class.$extend({
  convert: function(input) {
    var copy = input.slice(0);

    var previousValue = copy.shift();

    return _.map(copy, function(value) {
      var result = value - previousValue;

      previousValue = value;

      return result;
    });
  }
});
