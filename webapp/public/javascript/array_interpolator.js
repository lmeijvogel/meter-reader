"use strict";

window.ArrayInterpolator = Class.$extend({
  call: function(input) {
    if (input.length == 0) {
      return [];
    }
    var result = this.callRecursive(input, null);

    return result;
  },

  callRecursive: function(input, lastValue) {
    if (input.length == 0) {
      return [];
    }

    var head = _.head(input);

    if (head != null) {
      var tail = _.tail(input);
      return [head].concat(this.callRecursive(tail, head));
    } else {
      var tail = _.tail(input);

      // There is no known previous value, so don't try to interpolate.
      if (lastValue == null) {
        return [null].concat(this.callRecursive(tail, null));
      }

      var nextExistingElementIndex = this.firstIndexWhere(input, function(el) { return el != null; });

      if (nextExistingElementIndex == -1) {
        return input;
      }

      var nextValue = input[nextExistingElementIndex];

      // +1 because lastValue is *before* the array (index: -1),
      var stepSize = (nextValue - lastValue) / (nextExistingElementIndex + 1);

      var filledIn = _.map(_.range(nextExistingElementIndex), function(el) {
        return lastValue + (el+1) * stepSize;
      });

      var rest = _.drop(input, nextExistingElementIndex);

      return filledIn.concat(this.callRecursive(rest, nextValue));
    }
  },

  firstIndexWhere: function(input, test) {
    var firstIndexWhereInt = function(input, test) {
      var head = _.head(input);

      if (input.length == 0) { return -1; }

      if (test(head)) {
        return 0;
      } else {
        var indexInTail = firstIndexWhereInt(_.tail(input), test);

        if (indexInTail == -1) { return -1; }
        return 1 + indexInTail;
      }
    };

    return firstIndexWhereInt(input, test);
  }

});
