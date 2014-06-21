var DayStats = Class.$extend({
  __init__: function(main) {
    main.registerObserver(this);
  },

  notifyNewMeasurements: function(measurements) {
    this.showEnergyUsage(measurements);
    this.showGasUsage(measurements);
  },

  showEnergyUsage: function(measurements) {
    var stroom_totaal_measurements = _.chain(measurements).pluck("stroom_totaal");

    var min = stroom_totaal_measurements.min().value();
    var max = stroom_totaal_measurements.max().value();

    var value = parseFloat(Math.round((max-min) * 100) / 100).toFixed(2);;
    $(".energy_total").text(value +" kWh");
  },

  showGasUsage: function(measurements) {
    var gas_measurements = _.chain(measurements).pluck("gas");

    var min = gas_measurements.min().value();
    var max = gas_measurements.max().value();

    var value = parseFloat(Math.round((max-min) * 100) / 100).toFixed(2);
    $(".gas_total").html(value +" m<sup>3</sup>");
  }
});
