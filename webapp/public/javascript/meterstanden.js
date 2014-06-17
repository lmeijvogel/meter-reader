var GraphsPlotter = Class.$extend({
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
  }
});

$(function() {
  var graphsPlotter = GraphsPlotter();

  var render = function(url, periodSize) {
    $("#error_icon").hide();
    $("#loading_spinner").css('display', 'inline-block');

    var $graph = $(".graph");

    var fadeOut = new Promise(function(resolve, reject) {
      $graph.animate({
        opacity: 0.5
      }, function() {
        resolve();
      });
    });

    return Promise.cast(fadeOut.then(function() {
      $.getJSON(url).then( function( measurements ) {
        graphsPlotter.load(measurements);
        graphsPlotter.render();
      }).fail(function() {
        $("#error_icon").css('display', 'inline-block');
        $("#loading_spinner").hide();
      }).then(function() {
        $graph.css("opacity", "1");
      });
    }));
  };

  var datasetSize;
  var date;

  $('.today').on('click', function() {
    var today = new Date();

    renderDay(today);
  });

  $('.this_month').on('click', function() {
    var this_month = new Date();
    // make sure that adding months on e.g. the 31st doesn't
    // skip months if the next month only has 30 days.
    this_month.setDate(1);

    renderMonth(this_month);
  });

  $('.previous').on('click', function() {
    previousPeriod();
  });

  $('.next').on('click', function() {
    nextPeriod();
  });

  Hammer(window).on("swipeleft", function() {
    nextPeriod();
  }).on("swiperight", function() {
    previousPeriod();
  });

  previousPeriod = function() {
    switch(datasetSize) {
      case 'day':
        var newDate = new Date(date).setDate(date.getDate() - 1);

        renderDay(newDate);
        break;
      case 'month':
        var newDate = new Date(date).setMonth(date.getMonth() - 1);

        renderMonth(newDate);
        break;
    }
  };

  nextPeriod = function() {
    switch(datasetSize) {
      case 'day':
        var newDate = new Date(date).setDate(date.getDate() + 1);

        renderDay(newDate);
        break;
      case 'month':
        var newDate = new Date(date).setMonth(date.getMonth() + 1);

        renderMonth(newDate);
        break;
    }
  };

  renderDay  = function(day) {
    day = new Date(day);
    var url = "/day/"+day.getFullYear()+"/"+(day.getMonth()+1)+"/"+day.getDate();

    render(url, "day").then(function() {
      date = day;
      datasetSize = "day";

      header( moment(date).format("dddd DD-MM-YYYY") );
    });
  };

  renderMonth = function(month) {
    month = new Date(month);
    var url = "/month/"+month.getFullYear()+"/"+(month.getMonth()+1);
    render(url, "month").then(function() {
      date = month;
      datasetSize = "month";

      header( moment(date).format("MM-YYYY") );
    });
  };

  header = function(text) {
    $('.header').text(text);
  };

  delayAndExecuteOnce = function(method, timeout, timerName) {
    if (window[timerName]) {
      clearTimeout(window[timerName]);
      delete window[timerName];
    }

    window[timerName] = setTimeout(function() {
      delete window[timerName];
      method();
    }, timeout);
  };

  refreshCurrentUsage = function() {
    return RSVP.Promise.cast(jQuery.getJSON("/energy/current")).then(function(json) {
      var current = Math.round(parseFloat(json.current) * 1000);
      jQuery(".current_energy").text(current+" Watt");
    }).catch(function() {
      jQuery(".current_energy").text("-");
    });
  };


  $("html").keydown(function(event) {
    switch(event.keyCode) {
      case 37:
        previousPeriod();
        break;
      case 39:
        nextPeriod();
        break;
    }
  });

  (function() {
    var now = new Date();

    renderDay( now );
  })();

  jQuery(window).on("resize", function() {
    delayAndExecuteOnce( function() {
      graphsPlotter.render();
    }, 1000, "resizeTimer");
  });
  setInterval(function() {
    jQuery(".energy_spinner").show();

    refreshCurrentUsage()
      .then(function() {
        // Slight timeout to make sure the spinner is noticeable: this increases
        // trust.
        setTimeout(function() {
          jQuery(".energy_spinner").hide();
        }, 100);
      });
  }, 3000);
});
