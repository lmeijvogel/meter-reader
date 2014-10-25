var Main = Class.$extend({
  __init__: function() {
    this.observers = [];

    this.graphsPlotter = GraphsPlotter(this);
    EnergyTotals($(".energy_totals"), this);
    GasTotals($(".gas_totals"), this);

    this.urls = {};

    this.urls.current = jQuery("body").data('current-url');
    this.urls.prefix = jQuery("body").data('url-prefix');
  },

  renderDay: function(data) {
    var self = this;

    $("#error_icon").hide();
    $("#loading_spinner").css('display', 'inline-block');

    var $graph = $(".graph");

    var fadeOut;

    if ($graph.length > 0) {
        fadeOut = new Promise(function(resolve, reject) {
            $graph.animate({
                opacity: 0.5
            }, function() {
                resolve();
            });
        });
    } else {
        fadeOut = RSVP.Promise.resolve();
    }

    return fadeOut .then(function() {
      _.each(self.observers, function(observer) {
        observer.notifyNewMeasurements(data);
      });
      $graph.css("opacity", "1");
    });
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

  /* TODO: Move this to the CurrentUsageView */
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
