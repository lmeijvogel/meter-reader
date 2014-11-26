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
        loading: function() {
            this.controllerFor("day.show").set("loading", true);
        },
        didTransition: function() {
            this.controllerFor("day.show").set("loading", false);
        },
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
    resultsParser: function() {
        return DayResultsParser();
    }.property(),

    header: function() {
        return moment(this.get("day")).format("dddd DD-MM-YYYY");
    }.property("day")
});

Energy.DayShowView = Ember.View.extend(Ember.ViewTargetActionSupport, {
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

    didInsertElement: function() {
      this._keyDownHandler = this.keyDownHandler.bind(this);
      $(document).on("keydown", this._keyDownHandler);

      this._swipeLeftHandler = this.swipeLeftHandler.bind(this);
      this._swipeRightHandler = this.swipeRightHandler.bind(this);

      Hammer(window).on("swipeleft", this._swipeLeftHandler);
      Hammer(window).on("swiperight", this._swipeRightHandler);
    },

    willDestroyElement: function() {
        $(document).off("keydown", this._keyDownHandler);
        Hammer(window).off("swipeleft", this._swipeLeftHandler);
        Hammer(window).off("swiperight", this._swipeRightHandler);
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
            self.set("id", json.id);
            self.set("value", json.current);
        });
    }
});

Energy.CurrentEnergyUsageView = Ember.View.extend({
    classNameBindings: ["newValue"],
    classNames: ["current_energy bg-info col-xs-2 col-sm-2 numeric"],

    idObserver: function() {
        var self = this;

        this.set("newValue", true);

        setTimeout(function() {
            self.set("newValue", false);
        }, 1100);
    }.observes("controller.id")
});

Energy.GraphsView = Ember.View.extend({
    classNames: ["row"],
    templateName: "graphs",

    didInsertElement: function() {
        this._resizeHandler = this.resizeHandler.bind(this);
        $(window).on("resize", this._resizeHandler);
    },

    willDestroyElement: function() {
        $(window).off("resize", this._resizeHandler);
    },

    resizeHandler: function() {
        var throttleDistance = 1000;
        var immediate        = false;

        this._rerenderAfterResize = this._rerenderAfterResize;
        Ember.run.throttle(
            window.main,
            this._rerenderAfterResize,
            throttleDistance, immediate);
    }
});

Energy.TotalsView = Ember.View.extend({
    templateName: "totals",

    value: function() {
        var stroom_totaal_measurements = _.chain(this.get("controller.content")).pluck(this.get("fieldName"));

        var min = stroom_totaal_measurements.min().value();
        var max = stroom_totaal_measurements.max().value();

        return this.truncateDigits(max-min);
    }.property("controller.content"),

    truncateDigits: function(value) {
        var multiplier = Math.pow(10, this.get("accuracy"));

        return parseFloat(Math.round((value) * multiplier) / multiplier).toFixed(this.get("accuracy"));
    },
});

Energy.EnergyTotalsView = Energy.TotalsView.extend({
    fieldName: "stroom_totaal",
    accuracy: 2,

    formattedValue: function() {
        return this.get("value") +" kWh"
    }.property("value")
});

Energy.GasTotalsView = Energy.TotalsView.extend({
    fieldName: "gas",
    accuracy: 3,

    formattedValue: function() {
        return this.get("value") +" m<sup>3</sup>"
    }.property("value")
});

Energy.GraphView = Ember.View.extend({
    didInsertElement: function() {
        this.graph = this.initGraph();

        this.drawMeasurements();

    },

    contentObserver: function() {
        if (!this.graph) { return; }

        this.drawMeasurements();
    }.observes("controller.content"),

    drawMeasurements: function() {
        var self = this;

        return new Promise(function(resolve, reject) {
            self.$().animate({
                opacity: 0.5
            }, function() {
                resolve();
            });
        }).then(function() {
            self.graph.notifyNewMeasurements(self.get("controller.content"));
            self.$().css("opacity", "1");
        });
    }
});

Energy.StroomGraphView = Energy.GraphView.extend({
    attributeBindings: ['style'],
    classNames: "col-sm-5 col-sm-offset-1 col-xs-10 col-xs-offset-1 img-responsive graph",
    style: "height: 300px",

    initGraph: function() {
        return StroomPlotter(this.$(), this.get("controller.resultsParser"));
    }
});

Energy.GasGraphView = Energy.GraphView.extend({
    attributeBindings: ['style'],
    classNames: "col-sm-5 col-xs-10 col-sm-offset-0 col-xs-offset-1 img-responsive graph",
    style: "height: 300px",

    initGraph: function() {
        return GasPlotter(this.$(), this.get("controller.resultsParser"));
    }
})
