Energy = Ember.Application.create();

Energy.Router.map(function() {
    this.resource("day", function() {
        this.route("index");
        this.route("show", {path: "show/:date"});
    });
});

Energy.ApplicationRoute = Ember.Route.extend({
    beforeModel: function() {
        window.main.scheduleCurrentUsage();
    }
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

        Ember.run.next(function() {
            window.main.renderDay(day);
        });
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
