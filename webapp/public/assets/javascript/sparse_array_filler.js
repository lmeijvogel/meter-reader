window.SparseArrayFiller = Class.$extend({
  __init__: function(positionFunction, selectorFunction) {
    this.positionFunction = positionFunction;
    this.selectorFunction = selectorFunction;
  },

  call: function(input, inputArray) {
    var self = this;

    var result = _.clone(inputArray);

    _.each(input, function(element) {
      var position = self.positionFunction(element, input);

      if (0 <= position && position < result.length) {
        result[position] = self.selectorFunction(element);
      }
    });

    return result;
  }
});
