"use strict";

var ResultsParser = Class.$extend({
  parse: function(input, field) {
    var self = this;

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
  }
});

var DayResultsParser = ResultsParser.$extend({
  unit: "hour",
  approxDaysPerPeriod: function() { return 1; },

  positionInArray: function(element, allElements) {
    var time_stamp = moment(element.time_stamp);
    var hour = time_stamp.hour();
    var day = time_stamp.date();
    var firstElement = _.first(allElements);
    var firstDay = moment(firstElement.time_stamp).date();

    if (day != firstDay) { hour += this.singlePeriod(allElements); }
    return hour;
  },

  periodStartIndex: function() { return 0; },
  singlePeriod: function(input) {
    return 24;
  }
});

var MonthResultsParser = ResultsParser.$extend({
  unit: "date",
  approxDaysPerPeriod: function() { return 31; },

  positionInArray: function(element, allElements) {
    var time_stamp = moment(element.time_stamp);
    var day = time_stamp.date() - 1;
    var month = time_stamp.month();
    var firstElement = _.first(allElements);
    var firstMonth = moment(firstElement.time_stamp).month();

    if (month != firstMonth) { day += this.singlePeriod(allElements); }
    return day;
  },

  periodStartIndex: function() { return 1; },
  singlePeriod: function(input) {
    var ts = moment(_.head(input).time_stamp);

    var lastOfMonth = new Date(ts.year(), ts.month()+1, 0);
    return moment(lastOfMonth).date();
  }
});
