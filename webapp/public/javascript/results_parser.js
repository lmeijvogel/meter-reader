"use strict";

var ResultsParser = Class.$extend({
  __init__: function(periodSize) {
    this.periodSize = periodSize;
  },

  parse: function(input, field) {
    var self = this;

    if (input.length == 0) {
      return [];
    }

    this.firstTimeStamp = moment(input[0].time_stamp);

    var result = _.map(_.range(24), function(i) {
      var row = {time_stamp: self.firstTimeStamp.clone().hour(i)};
      row[field] = 0;

      return row;
    });

    if (input.length == 1) {
      // Nothing to interpolate, stop
      return result;
    }

    var previousHour = 0;
    var previousValue = null;

    var sortedInput = _.sortBy(input, "timeStamp");

    _.each(sortedInput, function(element) {
      var hour = moment(element.time_stamp).hour();
      var value = element[field];

      if (previousValue != null) {
        var numberOfHours = hour - previousHour;

        var step = (value - previousValue) / numberOfHours;

        result[previousHour] = self.measurement( previousHour, field, previousValue );

        for (var i = 1 ; i < hour - previousHour ; i++) {
          var currentValue = i*step + previousValue;

          var index = i + previousHour;
          result[index] = self.measurement(index, field, currentValue);
          result[index].interpolated = true;
        }
      }

      result[hour] = self.measurement( hour, field, value );

      previousHour = hour;
      previousValue = value;
    });

    return result;
  },

  measurement: function( hour, field, value ) {
    var result = { time_stamp: this.firstTimeStamp.clone().hour(hour) }
    result[field] = value;

    return result;
  }
});
