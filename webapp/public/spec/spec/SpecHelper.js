beforeEach(function () {
  jasmine.addMatchers({
    toContainData: function () {
      return {
        compare: function (actual, expected) {
          var mappedActual = [];

          _.each(actual, function(el) {
            var hour = parseInt(el.time_stamp.hour(), 10);

            mappedActual[hour] = el.value;
          });

          var passed = true;

          _.each(expected, function(el, i) {
            var comparison = (mappedActual[i] == expected[i]);

            passed &= comparison;
          });

          var result = {
            pass: passed
          }

          if (result.pass) {
            result.message = "Measurements with values "+ mappedActual +" contain the same values as "+expected;
          } else {
            result.message = "Measurements with values "+ mappedActual +" do not contain the same values as "+expected;
          }


          return result;
        }
      };
    }
  });
});
