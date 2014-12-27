window.DeepObjectDefaults = {
  merge: function(input, defaults) {
    var result = {};

    for (var prop in defaults) {
      if (prop in input) {
        var propertyValue = input[prop];
        if (typeof(propertyValue) === "object") {
          result[prop] = DeepObjectDefaults.merge(input[prop], defaults[prop]);
        } else {
          result[prop] = input[prop];
        }
      } else {
        result[prop] = defaults[prop];
      }
    }

    for (var inputProp in input) {
      if (!(inputProp in result)) {
        result[inputProp] = input[inputProp];
      }
    }

    return result;
  }
};


