Energy = Ember.Application.create();

Energy.Router.map(function() {
    this.resource("day", function() {
        this.route("index");
        this.route("show", {path: "show/:date"});
    });
});

Energy.ApplicationRoute = Ember.Route.extend({
});
Energy.IndexRoute = Ember.Route.extend({
    beforeModel: function() {
        this.transitionTo('day.index');
    }
});

Energy.DayIndexRoute = Ember.Route.extend({
    beforeModel: function() {
        var date = moment();
        this.transitionTo("day.show", date.format("YYYY-MM-DD"));
    }
});

Energy.DayShowRoute = Ember.Route.extend({
    beforeModel: function(args) {
        var date = args.params["day.show"].date;

        var dateParts = date.split("-");
        var day = new Date(dateParts[0], dateParts[1]-1, dateParts[2]);

        this.set("date", day)
    },

    model: function(params) {
        var day = moment(params.date);
        this.set("day", day);

        var url_prefix = jQuery("body").data('url-prefix');
        var url = url_prefix+"day/"+day.format("YYYY/MM/DD");

        return RSVP.Promise.cast($.getJSON(url));
    },

    setupController: function(controller, model) {
        this._super(controller, model);
        controller.set("day", this.get("day"));
    },

    actions: {
        previous: function() {
            var newDate = moment(this.get("date")).add(-1, "d");

            this.transitionTo("day.show", newDate.format("YYYY-MM-DD"));
        },

        next: function() {
            var newDate = moment(this.get("date")).add(1, "d");

            this.transitionTo("day.show", newDate.format("YYYY-MM-DD"));
        },

        today: function() {
            this.transitionTo("day.index");
        }
    }
});

Energy.DayShowController = Ember.Controller.extend({
    header: function() {
        return moment(this.get("day")).format("dddd DD-MM-YYYY");
    }.property("day")
});

Energy.DayShowView = Ember.View.extend(Ember.ViewTargetActionSupport, {
    contentObserver: function() {
        window.main.renderDay(this.get("controller.content"));
    }.observes("controller.content"),

    keyDownHandler: function(event) {
        switch(event.keyCode) {
          case 37:
            this.triggerAction({action: "previous"});
            break;
          case 39:
            this.triggerAction({action: "next"});
            break;
        }
    },

    swipeLeftHandler: function() {
        this.triggerAction({action: "next"});
    },

    swipeRightHandler: function() {
        this.triggerAction({action: "previous"});
    },

    resizeHandler: function() {
        window.main.delayAndExecuteOnce( function() {
            window.main.graphsPlotter.render();
        }, 1000, "resizeTimer");
    },

    didInsertElement: function() {
      this._keyDownHandler = this.keyDownHandler.bind(this);
      $(document).on("keydown", this._keyDownHandler);

      this._swipeLeftHandler = this.swipeLeftHandler.bind(this);
      this._swipeRighttHandler = this.swipeRightHandler.bind(this);

      Hammer(window).on("swipeleft", this._swipeLeftHandler);
      Hammer(window).on("swiperight", this._swipeRightHandler);

      this._resizeHandler = this.resizeHandler.bind(this);
      $(window).on("resize", this._resizeHandler);
    },

    willDestroyElement: function() {
        $(document).off("keydown", this._keyDownHandler);
        Hammer(window).off("swipeleft", this._swipeLeftHandler);
        Hammer(window).off("swiperight", this._swipeRightHandler);
        $(window).off("resize", this._resizeHandler);
    }
});

Energy.CurrentEnergyUsageController = Ember.Controller.extend({
    valueInWatts: function() {
        return ""+ 1000*this.get("value");
    }.property("value"),

    init: function() {
        var self = this;
        this.set("url", jQuery("body").data('current-url'));

        this.scheduleLoadValue();

        Ember.run.next(function() {
            self.loadValue();
        });
    },

    scheduleLoadValue: function() {
        var self = this;

        Ember.run.later(function() {
            self.loadValue();
            self.scheduleLoadValue();
        }, 3000);
    },

    loadValue: function() {
        var self = this;
        RSVP.Promise.cast(jQuery.getJSON(this.get("url")))
        .then(function(json) {
            self.set("value", json.current);
        });
    }
});
