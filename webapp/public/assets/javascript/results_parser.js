"use strict";

var ResultsParser = Class.$extend({
  setMeasurements: function(measurements) {
    this.measurements = measurements;
  },

  parse: function(field) {
    var self = this;

    var input = this.measurements;

    if (input.length < 2) {
      return [];
    }

    input = _.map(input, function(el) {
      if (el[field] == 0) { el[field] = null; }
      return el;
    });

    var arrayFiller = SparseArrayFiller(this.positionInArray.bind(this), function(el) { return el[field]; });
    var emptyArray = _.map(_.range(this.singlePeriod(input)+1), function() { return null; });

    var resultArray = arrayFiller.call(input, emptyArray );

    var arrayInterpolator = ArrayInterpolator();
    var interpolatedArray = arrayInterpolator.call(resultArray);

    return interpolatedArray;
  },

  ticks: function() {
    // Can specify a custom tick Array.
    // Ticks should match up one for each y value (category) in the series.
    var startIndex = this.periodStartIndex();

    // ResultsParser should also contain the measurements?
    var range = _.range(startIndex - 1, this.singlePeriod()+startIndex+1);

    return range;
  }
});

var DayResultsParser = ResultsParser.$extend({
  unit: "hour",
  approxDaysPerPeriod: function() { return 1; },

  positionInArray: function(element) {
    var time_stamp = moment(element.time_stamp);
    var hour = time_stamp.hour();
    var day = time_stamp.date();
    var firstElement = _.first(this.measurements);
    var firstDay = moment(firstElement.time_stamp).date();

    if (day != firstDay) { hour += 24; }
    return hour;
  },

  periodStartIndex: function() { return 0; },
  singlePeriod: function() {
    return 24;
  },
});

var MonthResultsParser = ResultsParser.$extend({
  unit: "date",
  approxDaysPerPeriod: function() { return 31; },

  positionInArray: function(element) {
    var time_stamp = moment(element.time_stamp);
    var day = time_stamp.date() - 1;
    var month = time_stamp.month();
    var firstElement = _.first(this.measurements);
    var firstMonth = moment(firstElement.time_stamp).month();

    if (month != firstMonth) { day += this.singlePeriod(); }
    return day;
  },

  periodStartIndex: function() { return 1; },
  singlePeriod: function() {
    var ts = moment(_.head(this.measurements).time_stamp);

    var lastOfMonth = new Date(ts.year(), ts.month()+1, 0);
    return moment(lastOfMonth).date();
  }
});
