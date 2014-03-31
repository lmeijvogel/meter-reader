var emptyArray = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

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

      expect(result).toContainData(_.range(24));
    });
  });

  describe("when the input contains two elements", function() {
    // Add a month to prevent being bitten by Daylight Savings Time, as I was today.
    var input = [{time_stamp: moment({hour: 12, month: 5}), value: 10}, {time_stamp: moment({hour: 16, month: 5}), value: 18}];

    it("interpolates only between the elements", function() {
      var result = ResultsParser("day").parse(input, "value");
      expect(result).toContainData(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 12, 14, 16, 18, 0, 0, 0, 0, 0, 0, 0]
      );
    });

    it("marks (only) the interpolated values", function() {
      var result = ResultsParser("day").parse(input, "value");

      expect(result[12].interpolated).not.toBe(true);
      _.each(_.range(13, 15), function(hour) {
        expect(result[hour].interpolated).toBe(true);
      });
      expect(result[16].interpolated).not.toBe(true);
    });
  });
});
