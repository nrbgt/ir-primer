// Generated by CoffeeScript 1.9.0
(function() {
  define([], function() {
    var Refraction, d3;
    d3 = null;
    Refraction = function(_d3) {
      var api;
      d3 = _d3;
      api = function(selection) {
        return selection.classed({
          refraction: true,
          explanation: true
        });
      };
      api.update = function() {
        return api;
      };
      api.resize = function(event) {
        return api.update();
      };
      d3.select(window).on({
        "resize.refraction": api.resize
      });
      return api;
    };
    return Fresnel;
  });

}).call(this);
