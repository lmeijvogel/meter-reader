$(function() {
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
    $.getJSON(url).then( function( measurements ) {
      var data = {
        labels : makeLabels(measurements),
        datasets : [
        {
          fillColor : "rgba(220,220,220,0.5)",
          strokeColor : "rgba(220,220,220,1)",
          pointColor : "rgba(220,220,220,1)",
          pointStrokeColor : "#fff",
          data : _.pluck(measurements, "stroom_totaal")
        },
        {
          datasetStroke: false,
          datasetFill: false,
          fillColor : "rgba(255,120,120,0)",
          strokeColor : "rgba(255,120,120,1)",
          pointColor : "rgba(255,120,120,1)",
          pointStrokeColor : "#fff",
          data : _.pluck(measurements, "gas")
        },
        ]
      }

      var options = {
        animation: false,
        scaleOverride: true,
        scaleStepWidth: 0.25,
        scaleSteps: determineMaxGridSteps(measurements, 0.25),

        scaleGridLineColor: "rgba(0, 0, 0, 0.2)"
      }

      var ctx = document.getElementById("chart").getContext("2d");
      new Chart(ctx).Line(data, options);
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
        date.setDate(date.getDate() - 1);

        renderDay(date);
        break;
      case 'month':
        date.setMonth(date.getMonth() - 1);

        renderMonth(date);
        break;
    }
  };

  nextPeriod = function() {
    switch(datasetSize) {
      case 'day':
        date.setDate(date.getDate() + 1);

        renderDay(date);
        break;
      case 'month':
        date.setMonth(date.getMonth() + 1);

        renderMonth(date);
        break;
    }
  };

  renderDay  = function(day) {
    date = day;
    datasetSize = "day";

    var url = "/day/"+date.getFullYear()+"/"+(date.getMonth()+1)+"/"+date.getDate();
    render(url);

    header( moment(date).format("dddd DD-MM-YYYY") );
  };

  renderMonth = function(month) {
    date = month;
    datasetSize = "month";

    var url = "/month/"+date.getFullYear()+"/"+(date.getMonth()+1);
    render(url);

    header( moment(date).format("MM-YYYY") );
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
