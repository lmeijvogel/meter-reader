"use strict";

var RelativeConverter = Class.$extend({
  convert: function(input) {
    var copy = input.slice(0);

    var previousValue = copy.shift();

    return _.map(copy, function(value) {
      var result;

      if (value != 0) {
        result = value - previousValue;
      } else {
        result = 0;
      }

      previousValue = value;

      return result;
    });
  }
});
