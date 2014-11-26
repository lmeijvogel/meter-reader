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
