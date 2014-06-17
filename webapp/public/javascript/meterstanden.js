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
