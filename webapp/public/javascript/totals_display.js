var TotalsDisplay = Class.$extend({
  __init__: function($element, main) {
    this.$element = $element;
    main.registerObserver(this);
  },

  notifyNewMeasurements: function(measurements) {
    var stroom_totaal_measurements = _.chain(measurements).pluck(this._dataField);

    var min = stroom_totaal_measurements.min().value();
    var max = stroom_totaal_measurements.max().value();

    var value = this._truncateDigits(max-min);

    this.$element.html(this._formatValue(value));
  },

  _truncateDigits: function(value) {
    var multiplier = Math.pow(10, this._accuracy);

    return parseFloat(Math.round((value) * multiplier) / multiplier).toFixed(this._accuracy);
  }
});

var EnergyTotals = TotalsDisplay.$extend({
  _formatValue: function(value) {
    return value +" kWh"
  },

  _dataField: "stroom_totaal",
  _accuracy: 2
});

var GasTotals = TotalsDisplay.$extend({
  _formatValue: function(value) {
    return value +" m<sup>3</sup>"
  },

  _dataField: "gas",
  _accuracy: 3
});
