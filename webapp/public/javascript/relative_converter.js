"use strict";

var RelativeConverter = Class.$extend({
  convert: function(input) {
    var copy = input.slice(0);

    var previousValue = copy.shift();

    return _.map(copy, function(value) {
      var result;

      if (previousValue != null && value != null) {
        result = value - previousValue;
      } else {
        result = 0;
      }

      previousValue = value;

      return result;
    });
  }
});
