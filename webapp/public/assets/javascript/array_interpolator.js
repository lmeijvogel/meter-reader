"use strict";

window.ArrayInterpolator = Class.$extend({
  call: function(input) {
    var firstNonNull = this.firstNonNull(input);

    if (firstNonNull == -1) {
      // No elements are filled in!
      return input;
    }

    if (firstNonNull == 0) {
      // Fill a single range by finding the next non-null element and
      // interpolate between them

      // Skip the first element, but still count it in the offset
      var nextNonNull = this.firstNonNull(_.tail(input)) + 1;

      // No further elements are filled in, nothing to interpolate
      if (nextNonNull == 0) {
        return input;
      }

      var first = _.take(input, nextNonNull+1);
      var rest  = _.drop(input, nextNonNull);

      var interpolatedFirst = this.interpolate(first);

      return _.initial(interpolatedFirst).concat(this.call(rest));
    } else {
      var nulls = _.take(input, firstNonNull);
      var rest  = _.drop(input, firstNonNull);

      return nulls.concat(this.call(rest));
    }
  },

  interpolate: function(array) {
    var first = _.head(array);
    var last  = _.last(array);

    var count = array.length;

    var stepSize = (last - first) / (count - 1);

    return _.map(_.range(count), function(el) {
      return first + el*stepSize;
    });
  },

  firstNonNull: function(input) {
    var firstIndexWhereInt = function(input, test) {
      if (input.length == 0) { return -1; }

      var head = _.head(input);

      if (test(head)) {
        return 0;
      } else {
        var indexInTail = firstIndexWhereInt(_.tail(input), test);

        if (indexInTail == -1) { return -1; }
        return 1 + indexInTail;
      }
    };

    return firstIndexWhereInt(input, function(el) { return el != null; });
  }

});
