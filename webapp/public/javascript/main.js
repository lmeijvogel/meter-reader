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
  },

  registerObserver: function(observer) {
    this.observers.push(observer);
  }
});
