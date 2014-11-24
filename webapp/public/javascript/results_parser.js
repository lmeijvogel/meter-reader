"use strict";

var ResultsParser = Class.$extend({
  unit: "hour",

  __init__: function(periodSize) {
    this.periodSize = periodSize;
  },

  parse: function(input, field) {
    var self = this;

    if (input.length == 0) {
      return [];
    }

    this.firstTimeStamp = moment(input[0].time_stamp);

    var result = this.initializeResult(this.firstTimeStamp, field);

    if (input.length == 1) {
      // Nothing to interpolate, stop
      return result;
    }

    var previousTimestamp = 0;
    var previousValue = null;

    var sortedInput = _.sortBy(input, "timeStamp");

    _.each(sortedInput, function(element) {
      var mTimestamp = moment(element.time_stamp);
      var timestamp = mTimestamp[self.unit]();

      if (!self.inCurrentPeriod(mTimestamp)) {
        timestamp += self.singlePeriod();
      }
      var value = element[field];

      if (previousValue != null) {
        var numberOfTimestamps = timestamp - previousTimestamp;

        var step = (value - previousValue) / numberOfTimestamps;

        result[previousTimestamp] = self.measurement( previousTimestamp, field, previousValue );

        for (var i = 1 ; i < numberOfTimestamps; i++) {
          var currentValue = i*step + previousValue;

          var index = i + previousTimestamp;
          result[index] = self.measurement(index, field, currentValue);
          result[index].interpolated = true;
        }
      }

      result[timestamp] = self.measurement( timestamp, field, value );

      previousTimestamp = timestamp;
      previousValue = value;
    });

    return result;
  },

  initializeResult: function(firstTimestamp, field) {
    var self = this;

    var resultLength = this.singlePeriod();

    return _.map(_.range(resultLength), function(i) {
      var row = {time_stamp: firstTimestamp.clone()[self.unit](i)};
      row[field] = 0;

      return row;
    });
  },

  measurement: function( timestamp, field, value ) {
    var result = { time_stamp: this.firstTimeStamp.clone()[this.unit](timestamp) }
    result[field] = value;

    return result;
  },

  inCurrentPeriod: function( timestamp ) {
    return timestamp.date() == this.firstTimeStamp.date();
  },

  singlePeriod: function() {
    return 24;
  }
});
