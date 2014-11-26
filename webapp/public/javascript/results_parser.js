"use strict";

var ResultsParser = Class.$extend({
  parse: function(input, field) {
    var self = this;

    if (input.length < 2) {
      return [];
    }

    input = this.prefilter(input);

    var arrayFiller = SparseArrayFiller(function(el) { return moment(el.time_stamp)[self.unit](); }, function(el) { return el[field]; });
    var emptyArray = _.map(_.range(this.singlePeriod(input)), function() { return null; });

    var resultArray = arrayFiller.call(input, emptyArray );

    var arrayInterpolator = ArrayInterpolator();
    var interpolatedArray = arrayInterpolator.call(resultArray);

    return this.postfilter(interpolatedArray);
  },

  prefilter: function(input) {
    return input;
  },

  postfilter: function(input) {
    return input;
  },
});

var DayResultsParser = ResultsParser.$extend({
  unit: "hour",

  prefilter: function(input) {
    // Workaround for invalid first element (which is overlapped by the last element):
    // Just don't render the last element for now. This will result in the last element not
    // being rendered correctly, but that is already the case: The graph is not drawn correctly.
    if (moment(_.last(input).time_stamp).hour() == 0) {
        return _.initial(input);
    } else {
        return input;
    }
  },

  singlePeriod: function(input) {
    return 24;
  }
});

var MonthResultsParser = ResultsParser.$extend({
  unit: "date",

  postfilter: function(input) {
    return _.tail(input);
  },

  singlePeriod: function(input) {
    var ts = moment(_.head(input).time_stamp);

    var lastOfMonth = new Date(ts.year(), ts.month()+1, 0);
    return moment(lastOfMonth).date();
  }
});
