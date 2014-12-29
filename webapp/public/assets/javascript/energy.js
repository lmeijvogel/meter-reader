Energy = Ember.Application.create();

Energy.Router.map(function() {
    this.resource("day", function() {
        this.route("index");
        this.route("show", {path: "show/:date"});
    });

    this.resource("month", function() {
        this.route("index");
        this.route("show", {path: "show/:date"});
    });
});

Energy.IndexRoute = Ember.Route.extend({
    beforeModel: function() {
        this.transitionTo('month.index');
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
        var day = moment(params.date, "YYYY-MM-DD");
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
        },

        barClicked: Em.K,

        upToMonth: function() {
          var today = moment(this.get("day"));
          this.transitionTo("month.show", today.format("YYYY-MM"));
        }
    }
});

Energy.DayShowController = Ember.Controller.extend({
    isMonth: false,

    resultsParser: function() {
        return DayResultsParser();
    }.property(),

    header: function() {
        return moment(this.get("day")).format("dddd DD-MM-YYYY");
    }.property("day")
});

Energy.DayShowView = Ember.View.extend(Ember.ViewTargetActionSupport, {
    templateName: "show",

    keyDownHandler: function(event) {
        switch(event.keyCode) {
          case 37:
            this.triggerAction({action: "previous"});
            break;
          case 38:
            this.triggerAction({action: "upToMonth"});
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
      var root = document.getElementById("body");
      this.hammer = Hammer(root);
      this._keyDownHandler = this.keyDownHandler.bind(this);
      $(document).on("keydown", this._keyDownHandler);

      this._swipeLeftHandler = this.swipeLeftHandler.bind(this);
      this._swipeRightHandler = this.swipeRightHandler.bind(this);

      this.hammer.on("swipeleft", this._swipeLeftHandler);
      this.hammer.on("swiperight", this._swipeRightHandler);
    },

    willDestroyElement: function() {
        $(document).off("keydown", this._keyDownHandler);
        this.hammer.off("swipeleft", this._swipeLeftHandler);
        this.hammer.off("swiperight", this._swipeRightHandler);
    }
});

Energy.MonthIndexRoute = Ember.Route.extend({
    beforeModel: function() {
        var date = moment();
        this.transitionTo("month.show", date.format("YYYY-MM"));
    }
});

Energy.MonthShowRoute = Ember.Route.extend({
    beforeModel: function(args) {
        var date = args.params["month.show"].date;

        var dateParts = date.split("-");
        var month = new Date(dateParts[0], dateParts[1]-1);

        this.set("date", month)
    },

    model: function(params) {
        var month = moment(params.date, "YYYY-MM");
        this.set("month", month);

        var url_prefix = jQuery("body").data('url-prefix');
        var url = url_prefix+"month/"+month.format("YYYY/MM");

        return RSVP.Promise.cast($.getJSON(url));
    },

    setupController: function(controller, model) {
        this._super(controller, model);
        controller.set("month", this.get("month"));
    },

    actions: {
        barClicked: function(barIndex) {
          var date = this.get("month").clone();
          date.set("date", (barIndex+1));

          this.transitionTo("day.show", date.format("YYYY-MM-DD"));
        },

        loading: function() {
            this.controllerFor("month.show").set("loading", true);
        },
        didTransition: function() {
            this.controllerFor("month.show").set("loading", false);
        },
        previous: function() {
            var newDate = moment(this.get("date")).add(-1, "M");

            this.transitionTo("month.show", newDate.format("YYYY-MM"));
        },

        next: function() {
            var newDate = moment(this.get("date")).add(1, "M");

            this.transitionTo("month.show", newDate.format("YYYY-MM"));
        },

        today: function() {
            this.transitionTo("day.index");
        }
    }
});

Energy.MonthShowController = Ember.Controller.extend({
    isMonth: true,

    resultsParser: function() {
        return MonthResultsParser();
    }.property(),

    header: function() {
        return moment(this.get("month")).format("MM-YYYY");
    }.property("month")
});

Energy.MonthShowView = Ember.View.extend(Ember.ViewTargetActionSupport, {
    templateName: "show",

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
      var root = document.getElementById("body");
      this.hammer = Hammer(root);

      this._keyDownHandler = this.keyDownHandler.bind(this);
      $(document).on("keydown", this._keyDownHandler);

      this._swipeLeftHandler = this.swipeLeftHandler.bind(this);
      this._swipeRightHandler = this.swipeRightHandler.bind(this);

      this.hammer.on("swipeleft", this._swipeLeftHandler);
      this.hammer.on("swiperight", this._swipeRightHandler);
    },

    willDestroyElement: function() {
        $(document).off("keydown", this._keyDownHandler);
        this.hammer.off("swipeleft", this._swipeLeftHandler);
        this.hammer.off("swiperight", this._swipeRightHandler);
    }
});

Energy.NavigationButtonsComponent = Ember.Component.extend({
  layoutName: "components/navigation-buttons",

  actions: {
    previous:  function() { this.sendAction('previous') },
    next:      function() { this.sendAction('next') },
    upToMonth: function() { this.sendAction('upToMonth') },
    today:     function() { this.sendAction('today') }
  }
});

Energy.CurrentEnergyUsageComponent = Ember.Component.extend({
    classNameBindings: ["newValue"],
    classNames: ["current_energy bg-info col-xs-2 col-sm-2 numeric"],

    valueInWatts: function() {
        return ""+ 1000*this.get("value");
    }.property("value"),

    didInsertElement: function() {
        var self = this;
        this.set("url", jQuery("body").data('current-url'));

        this.set("stopPolling", false);

        this.scheduleLoadValue();

        Ember.run.next(function() {
            self.loadValue();
        });
    },

    willDestroyElement: function() {
        this.set("stopPolling", true);
    },

    scheduleLoadValue: function() {
        if (this.get("stopPolling")) {
            return;
        }

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
    },

    idObserver: function() {
        var self = this;

        this.set("newValue", true);

        setTimeout(function() {
            self.set("newValue", false);
        }, 1100);
    }.observes("id")
});

Energy.UsageGraphsComponent = Ember.Component.extend({
    classNames: ["row"],
    layoutName: "components/usage-graphs",

    actions: {
      barClicked: function(data) { this.sendAction('barClicked', data); }
    }
});

Energy.TotalsComponent = Ember.Component.extend({
    layoutName: "components/totals",

    value: function() {
        var stroom_totaal_measurements = _.chain(this.get("content")).pluck(this.get("fieldName")).filter(function(el) { return el > 0; });

        var min = stroom_totaal_measurements.min().value();
        var max = stroom_totaal_measurements.max().value();

        return this.truncateDigits(max-min, this.get("accuracy"));
    }.property("controller.content"),

    truncateDigits: function(value, accuracy) {
        var multiplier = Math.pow(10, accuracy);

        return parseFloat(Math.round((value) * multiplier) / multiplier).toFixed(accuracy);
    },

    cost: function() {
        return this.truncateDigits(this.get("value") * this.get("costPerUnit"), 2);
    }.property("value", "costPerUnit")
});

Energy.EnergyTotalsComponent = Energy.TotalsComponent.extend({
    fieldName: "stroom_totaal",
    accuracy: 2,
    costPerUnit: 0.2345,

    formattedUsage: function() {
        return this.get("value") +" kWh";
    }.property("value")
});

Energy.GasTotalsComponent = Energy.TotalsComponent.extend({
    fieldName: "gas",
    accuracy: 3,
    costPerUnit: 0.7184,

    formattedUsage: function() {
      return this.get("value") +" m³";
    }.property("value")
});

Energy.GraphComponent = Ember.Component.extend({
    didInsertElement: function() {
        this.graph = this.initGraph();

        this.drawMeasurements();

        this._resizeHandler = this.resizeHandler.bind(this);
        $(window).on("resize", this._resizeHandler);
    },

    willDestroyElement: function() {
        $(window).off("resize", this._resizeHandler);
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
    },

    resizeHandler: function() {
        var throttleDistance = 1000;
        var immediate        = false;

        this._rerenderAfterResize = this._rerenderAfterResize || function() { this.graph.render(); };

        Ember.run.throttle(
            this,
            this._rerenderAfterResize,
            throttleDistance, immediate);
    }
});

Energy.StroomGraphComponent = Energy.GraphComponent.extend({
    attributeBindings: ['style'],
    classNames: "col-sm-5 col-sm-offset-1 col-xs-10 col-xs-offset-1 img-responsive graph",
    style: "height: 300px",

    initGraph: function() {
        var self = this;

        var plotter = StroomPlotter(this.$(), this.get("controller.resultsParser"));
        plotter.onBarClicked(function(value) {
          self.sendAction('action', value);
        });

        return plotter;
    }
});

Energy.GasGraphComponent = Energy.GraphComponent.extend({
    attributeBindings: ['style'],
    classNames: "col-sm-5 col-xs-10 col-sm-offset-0 col-xs-offset-1 img-responsive graph",
    style: "height: 300px",

    initGraph: function() {
        var self = this;

        var plotter = GasPlotter(this.$(), this.get("controller.resultsParser"));

        plotter.onBarClicked(function(value) {
          self.sendAction('action', value);
        });

        return plotter;
    }
})
