var GraphsPlotter = Class.$extend({
  __init__: function(element, resultsParser) {
    this.element = element;
    this.resultsParser = resultsParser;
  },

  render: function() {
    this.element.empty();

    var options = DeepObjectDefaults.merge(this.options(), this.defaultPlotOptions());
    this.element.jqplot([this.data], options);
  },

  notifyNewMeasurements: function(measurements) {
    this.load(measurements);
    this.render();
  },

  load: function(measurements) {
    this.measurements = measurements;
    this.data = this.processData();
  },

  defaultPlotOptions: function() {
    var graphWidth = this.element.innerWidth();
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
          ticks: this.ticks(),
          tickOptions: {formatString: '%d'}
        },

        yaxis: {
          min: 0,
          max: this.daysPerSet() * this.expectedDailyMax(),
          tickOptions: {formatString: '%d'}
        }
      }
    };
  },

  ticks: function() {
    // Can specify a custom tick Array.
    // Ticks should match up one for each y value (category) in the series.
    return _.range(0, this.resultsParser.singlePeriod(this.measurements));
  },

  daysPerSet: function() {
    return this.resultsParser.approxDaysPerPeriod();
  }
});

var StroomPlotter = GraphsPlotter.$extend({
  expectedDailyMax: function() { return 1500; },
  processData: function() {
    var parsedStroomTotaal = this.resultsParser.parse(this.measurements, "stroom_totaal");
    var stroomRelative = RelativeConverter().convert(parsedStroomTotaal);

    return _.map(stroomRelative, function(kwh) { return kwh*1000; });
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
        }
      }
    };
  },
});

var GasPlotter = GraphsPlotter.$extend({
  expectedDailyMax: function() { return 600; },
  processData: function() {
    var gas = this.resultsParser.parse(this.measurements, "gas");
    var gasRelative = RelativeConverter().convert(gas);

    return _.map(gasRelative, function(m3) { return m3*1000; });
  },

  options: function() {
    return {
      series: [
        { label: 'Gas', color: '#f0ad4e'}
      ],
      axes: {
        yaxis: {
        }
      }
    };
  }
});
