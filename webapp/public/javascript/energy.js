Energy = Ember.Application.create();

Energy.Router.map(function() {
    this.resource("day", function() {
        this.route("show", {path: "day/show/:date"});
    });
});

Energy.IndexRoute = Ember.Route.extend({
    beforeModel: function() {
        this.transitionTo('day.show', "today");
    }
});
