$(function() {
  var canvas = Canvas('chart');

  window.graph = Graph(canvas);

  var render = function(url, periodSize) {
    $("#error_icon").hide();
    $("#loading_spinner").css('display', 'inline-block');

    return $.getJSON(url).then( function( measurements ) {
      var resultsParser = ResultsParser("day");

      $("#loading_spinner").hide();

      var parsedStroomTotaal = resultsParser.parse(measurements, "stroom_totaal");
      var stroomTotaalAbsolute = _.pluck(parsedStroomTotaal, "stroom_totaal");
      var stroomTotaal = RelativeConverter().convert(stroomTotaalAbsolute);

      stroomTotaal.type = "line";

      var gas = _.pluck(resultsParser.parse(measurements, "gas"), "gas");
      gas = RelativeConverter().convert(gas);
      gas.type = "bar";
      gas.color = "#f84";

      window.graph.clear();
      window.graph.setPeriodSize(periodSize);
      window.graph.data(gas);
      window.graph.data(stroomTotaal);
      window.graph.interpolations(_.pluck(parsedStroomTotaal, "interpolated"));
      window.graph.draw();
    }).fail(function() {
      $("#error_icon").css('display', 'inline-block');
      $("#loading_spinner").hide();
    });
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

  $("svg").on("mouseover", "circle", function(event) {
    var circle = event.target;
    var $circle = jQuery(circle);

    var value = $circle.data("value");
    window.graph.popupValue( circle, value );
  });

  $("svg").on("mouseout", "circle", function() {
    window.graph.hidePopup();
  });

  (function() {
    var now = new Date();

    renderDay( now );
  })();

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
