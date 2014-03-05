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
          data : _.pluck(measurements, "stroom_piek")
        },
        {
          fillColor : "rgba(151,187,205,0.5)",
          strokeColor : "rgba(151,187,205,1)",
          pointColor : "rgba(151,187,205,1)",
          pointStrokeColor : "#fff",
          data : _.pluck(measurements, "stroom_dal")
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
      var ctx = document.getElementById("chart").getContext("2d");
      new Chart(ctx).Line(data, {});
    });
  };

  $('.today').on('click', function() {
    var now = new Date();

    var url = "/day/today"
    render(url);
  });

  $('.this_month').on('click', function() {
    var now = new Date();

    var url = "/month/"+now.getFullYear()+"/"+(now.getMonth()+1);
    render(url);
  });
});
