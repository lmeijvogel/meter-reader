$(function() {
  var canvas = Canvas('chart');

  window.graph = Graph(canvas);

  var makeLabels = function(measurements) {
    return _.map(measurements, function(value, i) {
      var time_stamp = new Date(value.time_stamp);

      if (time_stamp.getHours() % 3 == 0) {
        return moment(time_stamp).format("HH:mm");
      } else {
        return "";
      }
    });
  }

  var determineMaxGridSteps = function(measurements, stepSize) {
    var allValues = [_.pluck(measurements, "stroom_totaal"), _.pluck(measurements, "gas")];
    var maxValue = _.max(_.flatten(allValues));

    return (maxValue / stepSize) + stepSize;
  };

  var render = function(url) {
    $("#error_icon").hide();
    $("#loading_spinner").css('display', 'inline-block');

    return $.getJSON(url).then( function( measurements ) {
      $("#loading_spinner").hide();

      var stroomTotaal = _.pluck(measurements, "stroom_totaal");
      stroomTotaal.type = "line";

      var gas = _.pluck(measurements, "gas")
      gas.type = "bar";
      gas.color = "#f84";

      window.graph.clear();
      window.graph.data(gas);
      window.graph.data(stroomTotaal);
      window.graph.draw();
    }).fail(function() {
      $("#error_icon").css('display', 'inline-block');
      $("#loading_spinner").hide();
    });
  };

  var datasetSize;
  var date;

  $('.yesterday').on('click', function() {
    var yesterday = new Date();
    yesterday.setDate(yesterday.getDate()-1);

    renderDay(yesterday);
  });

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

    render(url).then(function() {
      date = day;
      datasetSize = "day";

      header( moment(date).format("dddd DD-MM-YYYY") );
    });
  };

  renderMonth = function(month) {
    month = new Date(month);
    var url = "/month/"+month.getFullYear()+"/"+(month.getMonth()+1);
    render(url).then(function() {
      date = month;
      datasetSize = "month";

      header( moment(date).format("MM-YYYY") );
    });
  };

  header = function(text) {
    $('.header').text(text);
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
});
