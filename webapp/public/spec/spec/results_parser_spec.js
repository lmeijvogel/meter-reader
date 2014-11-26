var emptyArray = [null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null];

describe("results_parser", function() {
  describe("when the input is empty", function() {
    it("returns an empty array", function() {
      expect(ResultsParser().parse([]).length).toBe(0);
    });
  });

  describe("when the input is a single element", function() {
    var input = [{time_stamp: moment({hour: 12, month: 5}), value: 13}];

    // Interpolating a single value is nonsensical.
    // Or, it should be duplicated to every position,
    // decide on that later.
    it("returns an empty array", function() {
      result = ResultsParser("day").parse(input, "value");

      expect(result).toContainData(emptyArray);
    });
  });

  describe("when the input contains all elements", function() {
    var input = [];

    beforeEach(function() {
      for (i = 0 ; i < 24 ; i++) {
        var time_stamp = moment({hour: i, month: 5});

        input.push({time_stamp: time_stamp, value: i});
      }
    });

    it("returns all elements", function() {
      result = ResultsParser("day").parse(input, "value");

      expect(result).toEqual(_.range(24));
    });

    describe("when the input contains an element on the next day", function() {
      var input = [];
      beforeEach(function() {
        for (i = 0 ; i < 23 ; i++) {
          var time_stamp = moment({hour: i, month: 5});
          input.push({time_stamp: time_stamp, value: i});
        }
        var nextDay = moment(Date.now()).day()+1;
        input.push({time_stamp: moment({hour: 0, month: 5, day: nextDay}), value: 24});
      });

      // We now select an extra measurement on the next day. Previously, the
      // parse method only looked at hours, which caused the graph to be drawn incorrectly:
      // The value for the last hour overwrote the first measurement since they both had
      // hour() == 0.
      it("works as expected", function() {
        pending();
        result = ResultsParser("day").parse(input, "value");

        expect(result[0]).toBe(0);
        expect(result[result.length-1]).toBe(24);
      });
    });
  });

  describe("when the input contains two elements", function() {
    // Add a month to prevent being bitten by Daylight Savings Time, as I was today.
    var input = [{time_stamp: moment({hour: 12, month: 5}), value: 10}, {time_stamp: moment({hour: 16, month: 5}), value: 18}];

    it("interpolates only between the elements", function() {
      var result = ResultsParser("day").parse(input, "value");
      expect(result).toEqual(
        [null, null, null, null, null, null, null, null, null, null, null, null, 10, 12, 14, 16, 18, null, null, null, null, null, null, null]
      );
    });
  });
});
