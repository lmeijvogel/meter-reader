describe("SparseArrayFiller", function() {
  beforeEach(function() {
    this.emptyArray = [null, null, null, null, null];

    var positionFunction = function(el) { return el.position; };
    var selectorFunction = function(el) { return el.value; };
    this.subject = SparseArrayFiller(positionFunction, selectorFunction);
  });

  describe("when the input is empty", function() {
    it("returns an array containing nulls", function() {
      var result = this.subject.call([], this.emptyArray)

      expect(result).toEqual(this.emptyArray);
    });
  });

  describe("when the input contains a single element", function() {
    beforeEach(function() {
      // This also tests boundary behavior since the array contains 5 elements
      this.element = {position: 4, value: 3};

      this.input = [this.element];
    });

    it("places it at the correct position", function() {
      var result = this.subject.call(this.input, this.emptyArray);

      var expected = [null, null, null, null, 3];

      expect(result).toEqual(expected);
    });

    it("does not change the original array", function() {
      var result = this.subject.call(this.input, this.emptyArray);

      expect(this.emptyArray[3]).toBe(null);
    });
  });

  describe("when the input contains an element outside the input array", function() {
    beforeEach(function() {
      this.element = {position: 6, value: 3};

      this.input = [this.element];
    });

    it("does not place it in the array", function() {
      var result = this.subject.call(this.input, this.emptyArray);

      var expected = [null, null, null, null, null];

      expect(result).toEqual(expected);
    });

  });
});
