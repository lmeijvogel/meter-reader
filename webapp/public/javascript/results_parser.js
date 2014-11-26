"use strict";

var ResultsParser = Class.$extend({
  unit: "hour",

  __init__: function(periodSize) {
    this.periodSize = periodSize;
  },

  parse: function(input, field) {
    if (input.length < 2) {
      return [];
    }

    // Workaround for invalid first element (which is overlapped by the last element):
    // Just don't render the last element for now. This will result in the last element not
    // being rendered correctly, but that is already the case: The graph is not drawn correctly.
    if (moment(_.last(input).time_stamp).hour() == 0) {
      input = _.initial(input);
    }

    var arrayFiller = SparseArrayFiller(function(el) { return moment(el.time_stamp).hour(); }, function(el) { return el[field]; });
    var emptyArray = _.map(_.range(24), function() { return null; });

    var resultArray = arrayFiller.call(input, emptyArray );

    var arrayInterpolator = ArrayInterpolator();
    var interpolatedArray = arrayInterpolator.call(resultArray);

    return interpolatedArray;
  },

  singlePeriod: function() {
    return 24;
  }
});
