Energy = Ember.Application.create();

Energy.Router.map(function() {
    this.resource("day", function() {
        this.route("show");
    });
});

Energy.IndexRoute = Ember.Route.extend({
    beforeModel: function() {
        this.transitionTo('day.show');
    }
});
