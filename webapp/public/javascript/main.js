var Main = Class.$extend({
  __init__: function() {
    this.date = null;
    this.observers = [];

    this.graphsPlotter = GraphsPlotter(this);
    EnergyTotals($(".energy_totals"), this);
    GasTotals($(".gas_totals"), this);

    this.setEventHandlers();

    this.urls = {};

    this.urls.current = jQuery("body").data('current-url');
    this.urls.prefix = jQuery("body").data('url-prefix');
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

    return fadeOut.then(function() {
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
    });
  },

  setEventHandlers: function() {
    var self = this;

    $(function() {
      $('.today').on('click', function() {
        self.renderToday();
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

  renderToday: function() {
    var today = new Date();

    this.renderDay(today);
  },

  renderDay: function(day) {
    var self = this;

    day = new Date(day);
    var url = this.urls.prefix+"/day/"+day.getFullYear()+"/"+(day.getMonth()+1)+"/"+day.getDate();

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

  scheduleCurrentUsage: function() {
    this.refreshCurrentUsageAndScheduleNew();
  },

  refreshCurrentUsageAndScheduleNew: function() {
    var self = this;

    this.refreshCurrentUsage()
    .then(function() {
      setTimeout(function() {
        self.refreshCurrentUsageAndScheduleNew();
      }, 3000);
    });
  },

  refreshCurrentUsage: function() {
    var self = this;

    jQuery(".energy_spinner").css("visibility", "visible");

    return RSVP.Promise.cast(jQuery.getJSON(this.urls.current))
    .then(function(json) {
      var element = jQuery(".current_energy");
      var oldColor = element.css("background-color");

      if (json.id != self.old_energy_id) {
        self.old_energy_id = json.id;
        element.css("background-color", "#fff");

        setTimeout(function() {
          element.css("background-color", oldColor);
        }, 1100);

      }

      var current = Math.round(parseFloat(json.current) * 1000);
      element.text(current+" Watt");
    }).catch(function() {
      jQuery(".current_energy").text("-");
    }).then(function() {
      // Slight timeout to make sure the spinner is noticeable: this increases
      // trust.
      setTimeout(function() {
        jQuery(".energy_spinner").css("visibility", "hidden");
      }, 100);
    });
  },

  registerObserver: function(observer) {
    this.observers.push(observer);
  }
});
