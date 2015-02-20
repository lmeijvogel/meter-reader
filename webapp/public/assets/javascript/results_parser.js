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
    throw "NotImplemented: ResultsParser.ticks()";
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

  singlePeriod: function() {
    return 24;
  },

  ticks: function() {
    // Make the range a little larger on both sides
    return _.map(_.range(-1, 23+2), function(el) {
      if (el % 5 == 0 || el == 23) {
        return el;
      } else {
        return null;
      }
    });
  }
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

  singlePeriod: function() {
    var ts = moment(_.head(this.measurements).time_stamp);

    var lastOfMonth = new Date(ts.year(), ts.month()+1, 0);
    return moment(lastOfMonth).date();
  },

  ticks: function() {
    // Make the range a bit larger to the left and right to
    // have a bit of room.
    var singlePeriod = this.singlePeriod();
    return _.map(_.range(0, singlePeriod+2), function(el) {
      // if a month contains 31 days, don't print '30' on the x-axis since '31' is already printed.
      if (el == 1 || el == singlePeriod || (el % 5 == 0 && el != 0 && (singlePeriod -1 != el))) {
        return el;
      } else {
        return null;
      }
    });
  }
});
