var Main = Class.$extend({
  __init__: function() {
    this.observers = [];

    this.gasPlotter = GasPlotter(this, "#gas");
    this.stroomPlotter = StroomPlotter(this, "#stroom");

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

  registerObserver: function(observer) {
    this.observers.push(observer);
  }
});
