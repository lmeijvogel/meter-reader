var GraphsPlotter = Class.$extend({
  __init__: function(main) {
    main.registerObserver(this);
  },

  load: function(measurements) {
    var resultsParser = ResultsParser("day");

    $("#loading_spinner").hide();

    var parsedStroomTotaal = resultsParser.parse(measurements, "stroom_totaal");
    var stroomTotaalAbsolute = _.pluck(parsedStroomTotaal, "stroom_totaal");
    var stroomTotaal = RelativeConverter().convert(stroomTotaalAbsolute);
    this.stroomWHTotaal = _.map(stroomTotaal, function(kwh) { return kwh*1000; });

    var gas = _.pluck(resultsParser.parse(measurements, "gas"), "gas");
    gas = RelativeConverter().convert(gas);
    this.gasdm3 = _.map(gas, function(m3) { return m3*1000; });
  },

  render: function() {
    $("#stroom,#gas").empty();

    // Both graphs have the same width:
    var graphWidth = jQuery("#gas").innerWidth();
    var barMargin = graphWidth / 40;
    var showPointLabels = graphWidth > 300;

    // Can specify a custom tick Array.
    // Ticks should match up one for each y value (category) in the series.
    var hourTicks = _.range(0, 24);

    var defaultPlotOptions = {
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
          ticks: hourTicks,
          tickOptions: {formatString: '%d'}
        },

        yaxis: {
          min: 0,
          tickOptions: {formatString: '%d'}
        }
      }
    };

    var stroomOptions = DeepObjectDefaults.merge({
      // Custom labels for the series are specified with the "label"
      // option on the series option.  Here a series option object
      // is specified for each series.
      series:[
        {label:'Stroom', color: '#428bca'}
      ],
      axes: {
        yaxis: {
          tickOptions: {formatString: '%d'}
        }
      }

    }, defaultPlotOptions);

    var gasOptions = DeepObjectDefaults.merge({
      series: [
        { label: 'Gas', color: '#f0ad4e'}
      ]
    }, defaultPlotOptions);

    var stroomPlot = $.jqplot('stroom', [this.stroomWHTotaal], stroomOptions);
    var gasPlot    = $.jqplot('gas',    [this.gasdm3],          gasOptions);
  },

  notifyNewMeasurements: function(measurements) {
    this.load(measurements);
    this.render();
  }
});
