var Main = Class.$extend({
  __init__: function() {
    this.date = null;
    this.observers = [];

    this.graphsPlotter = GraphsPlotter(this);
    EnergyTotals($(".energy_totals"), this);
    GasTotals($(".gas_totals"), this);

    this.setEventHandlers();
  },

  render: function(url, periodSize) {
    var self = this;

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
        _.each(self.observers, function(observer) {
          observer.notifyNewMeasurements(measurements);
        });
      }).fail(function() {
        $("#error_icon").css('display', 'inline-block');
        $("#loading_spinner").hide();
      }).then(function() {
        $graph.css("opacity", "1");
      });
    }));
  },

  setEventHandlers: function() {
    var self = this;

    $(function() {
      $('.today').on('click', function() {
        var today = new Date();

        self.renderDay(today);
      });

      $('.previous').on('click', function() {
        self.previousPeriod();
      });

      $('.next').on('click', function() {
        self.nextPeriod();
      });

      Hammer(window).on("swipeleft", function() {
        self.nextPeriod();
      }).on("swiperight", function() {
        self.previousPeriod();
      });

      $("html").keydown(function(event) {
        switch(event.keyCode) {
          case 37:
            self.previousPeriod();
            break;
          case 39:
            self.nextPeriod();
            break;
        }
      });

      jQuery(window).on("resize", function() {
        self.delayAndExecuteOnce( function() {
          self.graphsPlotter.render();
        }, 1000, "resizeTimer");
      });
      setInterval(function() {
        jQuery(".energy_spinner").css("visibility", "visible");

        self.refreshCurrentUsage()
          .then(function() {
            // Slight timeout to make sure the spinner is noticeable: this increases
            // trust.
            setTimeout(function() {
              jQuery(".energy_spinner").css("visibility", "hidden");
            }, 100);
          });
      }, 3000);
    });
  },

  previousPeriod: function() {
    var newDate = new Date(this.date).setDate(this.date.getDate() - 1);

    this.renderDay(newDate);
  },

  nextPeriod: function() {
    var newDate = new Date(this.date).setDate(this.date.getDate() + 1);

    this.renderDay(newDate);
  },

  renderDay: function(day) {
    var self = this;

    day = new Date(day);
    var url = "/day/"+day.getFullYear()+"/"+(day.getMonth()+1)+"/"+day.getDate();

    this.render(url, "day").then(function() {
      self.date = day;

      self.header( moment(day).format("dddd DD-MM-YYYY") );
    });
  },

  header: function(text) {
    $('.header').text(text);
  },

  delayAndExecuteOnce: function(method, timeout, timerName) {
    if (window[timerName]) {
      clearTimeout(window[timerName]);
      delete window[timerName];
    }

    window[timerName] = setTimeout(function() {
      delete window[timerName];
      method();
    }, timeout);
  },

  refreshCurrentUsage: function() {
    return RSVP.Promise.cast(jQuery.getJSON("/energy/current")).then(function(json) {
      var current = Math.round(parseFloat(json.current) * 1000);
      jQuery(".current_energy").text(current+" Watt");
    }).catch(function() {
      jQuery(".current_energy").text("-");
    });
  },

  registerObserver: function(observer) {
    this.observers.push(observer);
  }
});
