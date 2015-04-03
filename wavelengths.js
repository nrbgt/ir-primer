// Generated by CoffeeScript 1.9.0
(function() {
  define(["./explanation.js"], function(Exp) {
    var Wavelengths, converters, d3, domains, expwn, labels, padding, sliderPadding;
    d3 = null;
    padding = {
      top: 40,
      left: 120,
      right: 120,
      bottom: 90,
      middle: 20
    };
    sliderPadding = {
      top: 80,
      left: 10,
      right: 10,
      bottom: 110,
      temperature: 40,
      solution: 140
    };
    domains = {
      x: [0.1, 100],
      y: [[0, 1e5], [0, 3000], [0.01, 13], [1e-21, 1e-17]]
    };
    labels = ["Wavenumber", "Frequency [THz]", "Energy [EV]", "Energy [J]"];
    converters = [Exp.laws.Wavenumber, Exp.laws.Frequency, Exp.laws.EnergyEV, Exp.laws.EnergyJ];
    expwn = Exp.scientificNotation;
    Wavelengths = function(_d3) {
      var api, axes, colorizeLegend, dispatch, i, makeSeries, plotSeries, scales, seriesPath, wavelengths;
      d3 = _d3;
      scales = {
        x: d3.scale.log().domain(domains.x),
        y: [d3.scale.linear().domain(domains.y[0]), d3.scale.linear().domain(domains.y[1]), d3.scale.log().domain(domains.y[2]), d3.scale.log().domain(domains.y[3])],
        color: d3.scale.ordinal().range(["green", "purple", "red", "blue"])
      };
      axes = {
        x: d3.svg.axis().scale(scales.x).orient('bottom'),
        y: [d3.svg.axis().scale(scales.y[0]).orient('left'), d3.svg.axis().scale(scales.y[1]).orient('right'), d3.svg.axis().scale(scales.y[2]).orient('left'), d3.svg.axis().scale(scales.y[3]).orient('right')]
      };
      seriesPath = function(y) {
        return d3.svg.line().x(function(d) {
          return scales.x(d[0]);
        }).y(function(d) {
          return y(d[1]);
        });
      };
      wavelengths = ((function() {
        var _i, _results;
        _results = [];
        for (i = _i = 0.1; _i <= 1.99; i = _i += 0.01) {
          _results.push(i);
        }
        return _results;
      })()).concat((function() {
        var _i, _results;
        _results = [];
        for (i = _i = 2; _i <= 19.5; i = _i += 0.5) {
          _results.push(i);
        }
        return _results;
      })()).concat((function() {
        var _i, _results;
        _results = [];
        for (i = _i = 20; _i <= 100; i = _i += 1) {
          _results.push(i);
        }
        return _results;
      })());
      plotSeries = function(series) {
        return series.call(function(series) {
          return series.enter().append("g").classed({
            series: true
          }).append("path").style({
            stroke: function(d, i) {
              return scales.color(i);
            }
          });
        }).selectAll("path").attr({
          d: function(d) {
            var fn;
            fn = seriesPath(scales.y[d.scaleIdx]);
            return fn(d.points);
          }
        });
      };
      makeSeries = function(fn, i) {
        return {
          scaleIdx: i,
          points: wavelengths.map(function(wavelength) {
            return [wavelength, fn(wavelength)];
          })
        };
      };
      colorizeLegend = function(d, i) {
        if (i) {
          return scales.color(i - 1);
        } else {
          return "black";
        }
      };
      dispatch = d3.dispatch("update");
      api = function(selection) {
        var WAVELENGTH, clip, defs, el_xAxis, el_y0Axis, el_y1Axis, el_y2Axis, el_y3Axis, irBand, plots, plotsBg, references, solutions, spectrum, svg, xLabel, y0Label, y1Label, y2Label, y3Label;
        selection.classed({
          explanation: true,
          wavelengths: true
        });
        WAVELENGTH = 0;
        references = converters.map(makeSeries);
        api.explore = function() {
          var mouseX, mouseY, _ref;
          _ref = d3.mouse(this), mouseX = _ref[0], mouseY = _ref[1];
          WAVELENGTH = Math.min(domains.x[1], Math.max(scales.x.invert(mouseX), domains.x[0]));
          return api.update();
        };
        api.update = function() {
          var scaleSolutions;
          scaleSolutions = converters.map(function(convert) {
            return [WAVELENGTH, convert(WAVELENGTH)];
          });
          plots.selectAll(".solution.interactive").data(scaleSolutions).call(function(solutionLabel) {
            solutionLabel.enter().append("g").classed({
              solution: true,
              interactive: true
            }).append("line").style({
              stroke: function(d, i) {
                return scales.color(i);
              }
            }).attr({
              x1: 0,
              y1: 0,
              x2: function(d, i) {
                if (i % 2) {
                  return -20;
                } else {
                  return 20;
                }
              },
              y2: 0,
              "marker-start": function(d, i) {
                return "url(#end-arrow-" + (scales.color(i)) + ")";
              }
            });
            return solutionLabel.attr({
              transform: function(d, i) {
                var y;
                y = scales.y[i](d[1]);
                y = Number.isNaN(y) ? 0 : y;
                if (i % 2 === 0) {
                  return "translate(" + padding.left + ", " + y + ")";
                } else {
                  return "translate(" + (scales.x.range()[1]) + ", " + y + ")";
                }
              }
            });
          }).select("text").text(function(d, i) {
            if (i === 3) {
              return expwn(d[1]);
            } else {
              return "" + (d[1].toFixed(2));
            }
          });
          plots.selectAll(".scanline path").data([[[scales.x(WAVELENGTH), scales.y[0].range()[0]], [scales.x(WAVELENGTH), scales.y[0].range()[1]]], [[scales.x(WAVELENGTH), scales.y[2].range()[0]], [scales.x(WAVELENGTH), scales.y[2].range()[1]]]]).attr({
            d: d3.svg.line()
          });
          return solutions.selectAll(".solution.legend").data([[WAVELENGTH, WAVELENGTH]].concat(scaleSolutions)).call(function(solution) {
            solution.enter().append("g").classed({
              solution: true,
              legend: true
            }).call(function(solution) {
              solution.append("text").classed({
                scale: true
              }).attr({
                dx: 10
              });
              return solution.append("text").classed({
                value: true
              }).attr("text-anchor", "end");
            });
            solution.attr({
              transform: function(d, i) {
                return "translate(0 " + (i * 30) + ")";
              }
            });
            solution.select(".scale").text(function(d, i) {
              return ["Wavelength"].concat(labels)[i];
            }).style({
              fill: colorizeLegend
            });
            return solution.select(".value").text(function(d, i) {
              return d[1].toFixed(2);
            }).style({
              fill: colorizeLegend
            });
          });
        };
        api.resize = function() {
          var HEIGHT, MID, WIDTH;
          WIDTH = selection.node().clientWidth;
          HEIGHT = selection.node().clientHeight;
          MID = HEIGHT / 2;
          scales.x.range([padding.left, WIDTH - padding.right]);
          scales.y[0].range([MID, padding.top]);
          scales.y[1].range([MID, padding.top]);
          scales.y[2].range([HEIGHT - padding.bottom, MID + padding.middle]);
          scales.y[3].range([HEIGHT - padding.bottom, MID + padding.middle]);
          svg.attr({
            width: WIDTH,
            height: HEIGHT
          });
          plotsBg.attr({
            width: WIDTH - padding.right,
            height: HEIGHT
          });
          solutions.attr({
            transform: "translate(" + (WIDTH - 2.5 * padding.left) + ", " + (2 * padding.top) + ")"
          });
          spectrum.attr({
            transform: "translate(" + (scales.x(0.380)) + " " + padding.top + ")"
          }).select("rect").attr({
            width: (scales.x(0.750)) - (scales.x(0.380)),
            height: HEIGHT
          });
          spectrum.select("text").attr({
            transform: function(d) {
              return "translate(0 10) rotate(-90)";
            }
          });
          irBand.attr({
            transform: function(d) {
              return "translate(" + (scales.x(d.band[0])) + " " + padding.top + ")";
            }
          }).select("rect").attr({
            height: HEIGHT,
            width: function(d) {
              return scales.x(d.band[1]) - scales.x(d.band[0]);
            }
          });
          irBand.select("text").attr({
            transform: function(d) {
              return "translate(0 10) rotate(-90)";
            }
          });
          clip.attr({
            width: WIDTH,
            height: HEIGHT - padding.top - padding.bottom,
            x: 0,
            y: padding.top
          });
          el_xAxis.attr({
            transform: "translate(0, " + (HEIGHT - padding.bottom) + ")"
          }).call(axes.x).selectAll("text").text(function() {
            if (!!this.textContent) {
              return parseFloat(this.textContent);
            }
          });
          el_y0Axis.attr({
            transform: "translate(" + padding.left + ", 0)"
          }).call(axes.y[0]);
          el_y1Axis.attr({
            transform: "translate(" + (WIDTH - padding.right) + ", 0)"
          }).call(axes.y[1]);
          el_y2Axis.attr({
            transform: "translate(" + padding.left + ", 0)"
          }).call(axes.y[2]);
          el_y3Axis.attr({
            transform: "translate(" + (WIDTH - padding.right) + ", 0)"
          }).call(axes.y[3]).selectAll("text").text(function() {
            if (this.textContent[0] === "1") {
              return this.textContent;
            } else {
              return "";
            }
          });
          xLabel.attr({
            transform: "translate(" + [WIDTH / 2, HEIGHT - 30] + ")"
          });
          y0Label.attr({
            transform: "translate(10, " + (HEIGHT / 4) + ") rotate(-90)"
          });
          y1Label.attr({
            transform: "translate(" + (WIDTH - 10) + ", " + (HEIGHT / 4) + ") rotate(90)"
          });
          y2Label.attr({
            transform: "translate(10, " + (HEIGHT * (3 / 4)) + ") rotate(-90)"
          });
          y3Label.attr({
            transform: "translate(" + (WIDTH - 10) + ", " + (HEIGHT * (3 / 4)) + ") rotate(90)"
          });
          plots.selectAll('.series').data(references).call(plotSeries);
          return api.update();
        };
        svg = selection.selectAll(".plot").data([1]).call(function(svg) {
          var defs;
          svg = svg.enter().append("svg").classed({
            plot: true
          });
          defs = svg.append("defs");
          defs.call(Exp.defs.spectrum);
          defs.append("clipPath").classed({
            "wavelengths-path": true
          }).attr({
            id: "wavelengthsPath"
          }).append("rect");
          return defs.selectAll("marker.arrow").data(scales.color.range()).enter().append("marker").classed({
            arrow: true
          }).attr({
            id: function(d) {
              return "end-arrow-" + d;
            },
            viewBox: "0 -5 10 10",
            markerWidth: 6,
            markerHeight: 6,
            orient: "auto"
          }).append("path").attr({
            d: "M 10,-5 L 0,0 L 10,5"
          }).style({
            fill: Object
          });
        });
        svg.append("g").classed({
          plots: true
        }).attr({
          "clip-path": "url(#wavelengthsPath)"
        }).call(function(plots) {
          var _i, _len, _ref, _results;
          plots.append("g").classed({
            spectrum: true
          }).call(function(spectrum) {
            spectrum.append("rect").style({
              fill: "url(#spectrumGradient)"
            });
            return spectrum.append("text").text("Visible Light").attr({
              dy: "1em",
              "text-anchor": "end"
            });
          });
          plots.call(Exp.drawIrBands);
          plots.append("rect").classed({
            bg: true
          }).on({
            mousemove: api.explore
          });
          plots.append("g").classed({
            solutions: true
          });
          _ref = [0, 1];
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            i = _ref[_i];
            _results.push(plots.append("g").classed({
              scanline: true
            }).append("path"));
          }
          return _results;
        });
        svg.append("g").classed({
          axis: true,
          x: true
        });
        svg.append("g").classed({
          axis: true,
          y0: true
        });
        svg.append("g").classed({
          axis: true,
          y1: true
        });
        svg.append("g").classed({
          axis: true,
          y2: true
        });
        svg.append("g").classed({
          axis: true,
          y3: true
        });
        svg.append("g").classed({
          label: true,
          x: true
        }).append("text").attr({
          "text-anchor": "middle",
          dy: ".71em",
          y: -10
        }).call(function(xLabel) {
          xLabel.append("tspan").text("Wavelength");
          return xLabel.append("tspan").classed({
            unit: true
          }).text(" [µm]");
        });
        svg.append("g").classed({
          label: true,
          y0: true
        }).append("text").attr({
          "text-anchor": "middle",
          dy: ".71em"
        }).call(function(yLabel) {
          yLabel.append("tspan").text("Wavenumber").classed({
            "fill-wavenumber": true
          });
          return yLabel.append("tspan").classed({
            unit: true
          }).text(" [cm⁻¹]");
        });
        svg.append("g").classed({
          label: true,
          y1: true
        }).append("text").attr({
          "text-anchor": "middle",
          dy: ".71em"
        }).call(function(yLabel) {
          yLabel.append("tspan").text("Frequency ").classed({
            "fill-frequency": true
          });
          return yLabel.append("tspan").classed({
            unit: true
          }).text(" [THz]");
        });
        svg.append("g").classed({
          label: true,
          y2: true
        }).append("text").attr({
          "text-anchor": "middle",
          dy: ".71em"
        }).call(function(yLabel) {
          yLabel.append("tspan").text("Energy ").classed({
            "fill-energy-ev": true
          });
          return yLabel.append("tspan").classed({
            unit: true
          }).text(" [eV]");
        });
        svg.append("g").classed({
          label: true,
          y3: true
        }).append("text").attr({
          "text-anchor": "middle",
          dy: ".71em"
        }).call(function(yLabel) {
          yLabel.append("tspan").text("Energy ").classed({
            "fill-energy-j": true
          });
          return yLabel.append("tspan").classed({
            unit: true
          }).text(" [J]");
        });
        svg.append("g").classed({
          wavelength: true,
          interactive: true
        }).attr({
          "text-anchor": "middle"
        }).append("text");
        plots = svg.select(".plots");
        solutions = plots.select(".solutions");
        plotsBg = plots.select(".bg");
        defs = svg.select("defs");
        clip = defs.select(".wavelengths-path rect");
        el_xAxis = svg.select(".axis.x");
        el_y0Axis = svg.select(".axis.y0");
        el_y1Axis = svg.select(".axis.y1");
        el_y2Axis = svg.select(".axis.y2");
        el_y3Axis = svg.select(".axis.y3");
        xLabel = svg.select(".label.x text");
        y0Label = svg.select(".label.y0 text");
        y1Label = svg.select(".label.y1 text");
        y2Label = svg.select(".label.y2 text");
        y3Label = svg.select(".label.y3 text");
        spectrum = svg.selectAll(".spectrum");
        irBand = svg.selectAll(".ir-band");
        d3.select(window).on({
          "resize.temperatures": api.resize
        });
        return api.resize();
      };
      api.dispatch = dispatch;
      return api;
    };
    return Wavelengths;
  });

}).call(this);
