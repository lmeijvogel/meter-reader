Energy = Ember.Application.create();

Energy.Router.map(function() {
    this.resource("day", function() {
        this.route("show", {path: "day/show/:date"});
    });
});

Energy.ApplicationRoute = Ember.Route.extend({
    beforeModel: function() {
        window.main.scheduleCurrentUsage();
    }
});
Energy.IndexRoute = Ember.Route.extend({
    beforeModel: function() {
        this.transitionTo('day.show', "today");
    }
});

Energy.DayShowRoute = Ember.Route.extend({
    beforeModel: function(args) {
        Ember.run.next(function() {
            window.main.renderToday();
        });
    }
});
