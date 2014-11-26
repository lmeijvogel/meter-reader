describe("ArrayInterpolator", function() {
  beforeEach(function() {
    this.subject = ArrayInterpolator();
  });

  describe("when the input is empty", function() {
    it("returns an empty array", function() {
      expect(this.subject.call([])).toEqual([]);
    });
  });

  describe("when the input contains a single element", function() {
    it("returns the same array", function() {
      expect(this.subject.call([12])).toEqual([12]);
    });
  });

  describe("when the input contains data that can be interpolated", function() {
    beforeEach(function() {
      this.input = [10, 11, null, null, null, 19, null, 9];
    });

    it("returns the interpolated array", function() {
      var expected = [10, 11, 13, 15, 17, 19, 14, 9];
      expect(this.subject.call(this.input)).toEqual(expected);
    });
  });

  describe("when the input starts on null", function() {
    beforeEach(function() {
      this.input = [null, null, 10, 11, null, 13];
    });

    it("returns the interpolated array, starting on nulls", function() {
      var expected = [null, null, 10, 11, 12, 13];
      expect(this.subject.call(this.input)).toEqual(expected);
    });
  });

  describe("when the input ends on null", function() {
    beforeEach(function() {
      this.input = [10, 11, null, 13, null, null];
    });

    it("returns the interpolated array, ending on nulls", function() {
      var expected = [10, 11, 12, 13, null, null];
      expect(this.subject.call(this.input)).toEqual(expected);
    });
  });
});
