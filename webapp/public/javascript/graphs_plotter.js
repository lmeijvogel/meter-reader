var GraphsPlotter = Class.$extend({
  __init__: function(main, selector) {
    main.registerObserver(this);
    this.selector = selector;
  },

  render: function() {
    $(this.selector).empty();

    // Strip leading '#' from selector
    var jqPlotSelector = this.selector.substring(1);

    var options = DeepObjectDefaults.merge(this.options(), this.defaultPlotOptions());
    $.jqplot(jqPlotSelector, [this.data], options);
  },

  notifyNewMeasurements: function(measurements) {
    this.load(measurements);
    this.render();
  },

  load: function(measurements) {
    this.data = this.processData(measurements);
  },

  defaultPlotOptions: function() {
    // Both graphs have the same width:
    var graphWidth = jQuery(this.selector).innerWidth();
    var barMargin = graphWidth / 40;
    var showPointLabels = graphWidth > 300;

    return {
      seriesDefaults:{
        renderer:$.jqplot.BarRenderer,
        rendererOptions: {
          barMargin: barMargin
        },
        pointLabels: {
          show: showPointLabels,
          hideZeros: true

        }
      },
      grid: {
        background: 'white'
      },

      // Show the legend and put it outside the grid, but inside the
      // plot container, shrinking the grid to accomodate the legend.
      // A value of "outside" would not shrink the grid and allow
      // the legend to overflow the container.
      axes: {
        xaxis: {
          ticks: this.hourTicks(),
          tickOptions: {formatString: '%d'}
        },

        yaxis: {
          min: 0,
          tickOptions: {formatString: '%d'}
        }
      }
    };
  },

  hourTicks: function() {
    // Can specify a custom tick Array.
    // Ticks should match up one for each y value (category) in the series.
    return _.range(0, 24);
  }
});

var StroomPlotter = GraphsPlotter.$extend({
  processData: function(measurements) {
    var resultsParser = ResultsParser("day");

    var parsedStroomTotaal = resultsParser.parse(measurements, "stroom_totaal");
    var stroomTotaalAbsolute = _.pluck(parsedStroomTotaal, "stroom_totaal");
    var stroomTotaal = RelativeConverter().convert(stroomTotaalAbsolute);

    return _.map(stroomTotaal, function(kwh) { return kwh*1000; });
  },

  options: function() {
    return {
      // Custom labels for the series are specified with the "label"
      // option on the series option.  Here a series option object
      // is specified for each series.
      series:[
        {label:'Stroom', color: '#428bca'}
      ],
      axes: {
        yaxis: {
          tickOptions: {formatString: '%d'},
          max: 1500
        }
      }
    };
  },
});

var GasPlotter = GraphsPlotter.$extend({
  processData: function(measurements) {
    var resultsParser = ResultsParser("day");

    var gas = _.pluck(resultsParser.parse(measurements, "gas"), "gas");
    gas = RelativeConverter().convert(gas);

    return _.map(gas, function(m3) { return m3*1000; });
  },

  options: function() {
    return {
      series: [
        { label: 'Gas', color: '#f0ad4e'}
      ],
      axes: {
        yaxis: {
          max: 600
        }
      }
    };
  }
});
