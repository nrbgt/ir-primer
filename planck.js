// Generated by CoffeeScript 1.9.0
(function() {
  define(["./explanation.js"], function(Exp) {
    var Planck, axisW, d3, expwn, i, makeSeries, padding, plancksLaw, sidebarWidth, sliderCircle, sliderPadding, temperatures, wavelengths, wiens, wiensLaw, xDomain, yDomain;
    d3 = null;
    plancksLaw = function(temperature, wavelength) {
      return [wavelength, Exp.laws.Planck(temperature, wavelength)];
    };
    wiensLaw = function(temperature) {
      return plancksLaw(temperature, Exp.laws.Wien(temperature));
    };
    padding = {
      top: 40,
      left: 120,
      right: 80,
      bottom: 90
    };
    sliderPadding = {
      top: 80,
      left: 10,
      right: 10,
      bottom: 110,
      temperature: 40,
      solution: 140
    };
    xDomain = [0.1, 100];
    yDomain = [1e-4, 1e9];
    axisW = 20;
    sliderCircle = {
      r: 5,
      cx: 0
    };
    sidebarWidth = 180;
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
    temperatures = [100, 200, 400, 600, 800, 1000, 2000, 3000, 4000, 5000, 6000];
    wiens = temperatures.map(function(temperature) {
      return wiensLaw(temperature);
    });
    expwn = Exp.scientificNotation;
    makeSeries = function(temperature) {
      return {
        temperature: temperature,
        spectral_exitance: wavelengths.map(function(wavelength) {
          return plancksLaw(temperature, wavelength);
        }).filter(function(point) {
          return point[1];
        })
      };
    };
    Planck = function(_d3) {
      var HOVERWIEN, TEMPERATURE, WAVELENGTH, api, axes, plotSeries, references, scales, seriesPath, temperatureColor;
      d3 = _d3;
      TEMPERATURE = temperatures.slice(-1)[0];
      WAVELENGTH = wavelengths.slice(-1)[0];
      HOVERWIEN = false;
      references = temperatures.map(makeSeries);
      seriesPath = d3.svg.line().x(function(d) {
        return scales.x(d[0]);
      }).y(function(d) {
        return scales.y(d[1]);
      });
      temperatureColor = function(d) {
        return scales.color(d.temperature);
      };
      plotSeries = function(series) {
        return series.call(function(series) {
          return series.enter().append("g").classed({
            series: true
          }).append("path").style({
            stroke: temperatureColor
          });
        }).selectAll("path").data(function(d) {
          return [d.spectral_exitance];
        }).attr({
          d: seriesPath
        });
      };
      scales = {
        x: d3.scale.log().domain(xDomain),
        y: d3.scale.log().domain(yDomain),
        slider: d3.scale.log().domain(d3.extent(temperatures)),
        color: d3.scale.category20b()
      };
      axes = {
        x: d3.svg.axis().scale(scales.x).orient('bottom'),
        y: d3.svg.axis().scale(scales.y).orient('left')
      };
      api = function(selection) {
        var clip, defs, el_xAxis, el_yAxis, handleLabel, handleSolution, plots, plotsBg, slide, slideHandle, slider, sliderFormula, sliderLabel, sliderReferences, solutions, spectrum, svg, wavelengthLabel, wienSeries, xLabel, yLabel;
        selection.classed({
          planck: true,
          explanation: true
        });
        slide = d3.behavior.drag().on("drag", function(value) {
          var val;
          val = parseInt(scales.slider.invert(d3.event.y));
          TEMPERATURE = Math.max(temperatures[0], Math.min(val, temperatures.slice(-1)[0]));
          return api.update();
        });
        api.explore = function() {
          var mouseX, mouseY, val, _ref;
          _ref = d3.mouse(svg.node()), mouseX = _ref[0], mouseY = _ref[1];
          WAVELENGTH = scales.x.invert(mouseX);
          val = parseInt(scales.slider.invert(mouseY));
          TEMPERATURE = Math.max(temperatures[0], Math.min(val, temperatures.slice(-1)[0]));
          return api.update();
        };
        api.update = function() {
          var series, solution, solutionObj, wavelengthSolutions;
          series = makeSeries(TEMPERATURE);
          solution = HOVERWIEN ? wiensLaw(TEMPERATURE) : plancksLaw(TEMPERATURE, WAVELENGTH);
          slideHandle.attr({
            transform: "translate(0, " + (scales.slider(TEMPERATURE)) + ")"
          });
          handleLabel.text(TEMPERATURE);
          handleSolution.text(solution[1] ? "I: " + (expwn(solution[1])) : "");
          plots.selectAll('.series.interactive').data([series]).call(plotSeries).classed({
            interactive: true
          }).select("path").style({
            color: "black"
          });
          wavelengthLabel.attr({
            transform: "translate(" + (scales.x(WAVELENGTH)) + ", 20)"
          }).select("text").text("λ: " + (WAVELENGTH.toFixed(2)));
          sliderFormula.select(".wavelength").classed({
            variable: false
          }).text(WAVELENGTH.toFixed(2));
          solutions.selectAll('.solution.interactive').data([solution.solution]).call(function(solution) {
            return solution.enter().append("g").classed({
              solution: true,
              interactive: true
            }).append("circle").attr({
              r: 3
            });
          }).attr({
            transform: function(d) {
              return "translate(" + (scales.x(solution[0])) + ", " + (scales.y(solution[1])) + " )";
            }
          });
          wavelengthSolutions = references.map(function(d) {
            return {
              series: d,
              solution: HOVERWIEN ? wiensLaw(d.temperature) : plancksLaw(d.temperature, WAVELENGTH)
            };
          });
          solutionObj = wavelengthSolutions.reduce(function(memo, obj, i) {
            memo[obj.series.temperature] = obj.solution[1];
            return memo;
          }, {});
          sliderReferences.selectAll("text.solution").text(function(d) {
            return "" + (expwn(solutionObj[d.temperature]));
          });
          solutions.selectAll(".solution.reference").data(wavelengthSolutions).call(function(solution) {
            return solution.enter().append("g").classed({
              solution: true,
              reference: true
            }).call(function(solution) {
              return solution.append("circle").attr({
                r: 5
              }).style({
                stroke: function(d) {
                  return temperatureColor(d.series);
                },
                fill: function(d) {
                  return temperatureColor(d.series);
                }
              });
            });
          }).attr({
            transform: function(d) {
              return "translate(" + (scales.x(d.solution[0])) + ", " + (scales.y(d.solution[1])) + " )";
            }
          });
          return api;
        };
        api.resize = function(event) {
          var HEIGHT, WIDTH;
          WIDTH = selection.node().clientWidth;
          HEIGHT = selection.node().clientHeight;
          scales.x.range([padding.left, WIDTH - padding.right - sidebarWidth]);
          scales.y.range([HEIGHT - padding.bottom, padding.top]);
          svg.attr({
            width: WIDTH,
            height: HEIGHT
          });
          plotsBg.attr({
            width: WIDTH - padding.right - sidebarWidth,
            height: HEIGHT
          });
          spectrum.attr({
            x: scales.x(0.380),
            y: scales.y.range()[1],
            width: (scales.x(0.750)) - (scales.x(0.380)),
            height: HEIGHT
          });
          clip.attr({
            width: scales.x.range().slice(-1),
            height: scales.y.range()[0],
            x: padding.left
          });
          el_xAxis.attr({
            transform: "translate(0, " + (HEIGHT - padding.bottom) + ")"
          }).call(axes.x).selectAll("text").text(function() {
            if (!!this.textContent) {
              return parseFloat(this.textContent);
            }
          });
          el_yAxis.attr({
            transform: "translate(" + padding.left + ", 0)"
          }).call(axes.y).selectAll("text").text(function() {
            return expwn(this.textContent);
          });
          yLabel.attr({
            transform: "translate(10, " + (HEIGHT / 2) + ") rotate(-90)"
          });
          xLabel.attr({
            transform: "translate(" + [WIDTH / 2, HEIGHT - 50] + ")"
          });
          plots.selectAll('.series').data(references).call(plotSeries);
          scales.slider.range([HEIGHT - sliderPadding.bottom, sliderPadding.top]);
          slider.attr({
            transform: "translate(" + (scales.x.range()[1] + 20) + ", 0)"
          });
          sliderLabel.attr({
            transform: "translate(" + sidebarWidth + ", " + (HEIGHT / 2) + ") rotate(90)"
          });
          sliderFormula.attr({
            transform: "translate(" + (sidebarWidth / 2) + " " + padding.top + " )"
          });
          sliderReferences.attr({
            transform: function(d) {
              return "translate(0, " + (scales.slider(d.temperature)) + ")";
            }
          });
          wienSeries.selectAll("path").data([wiens]).attr({
            d: seriesPath
          });
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
            "planck-path": true
          }).attr({
            id: "planckPath"
          }).append("rect");
          svg.append("g").classed({
            plots: true
          }).attr({
            "clip-path": "url(#planckPath)"
          }).call(function(plots) {
            plots.append("rect").classed({
              spectrum: true
            }).style({
              fill: "url(#spectrumGradient)"
            });
            plots.append("rect").classed({
              bg: true
            }).on({
              "mousemove.planck": api.explore
            });
            plots.append("g").classed({
              solutions: true
            });
            return plots.append("g").classed({
              wien: true
            }).on({
              mouseover: function() {
                HOVERWIEN = true;
                return api.update();
              },
              mouseout: function() {
                HOVERWIEN = false;
                return api.update();
              }
            }).append("path");
          });
          svg.append("g").classed({
            axis: true,
            x: true
          });
          svg.append("g").classed({
            axis: true,
            y: true
          });
          svg.append("g").classed({
            label: true,
            y: true
          }).append("text").attr({
            "text-anchor": "middle",
            dy: ".71em"
          }).call(function(yLabel) {
            yLabel.append("tspan").text("Spectral Exitance");
            yLabel.append("tspan").classed({
              unit: true
            }).text(" [W/m²-µm]");
            return yLabel.append("tspan").classed({
              variable: true
            }).text(" I(λ,T)");
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
            xLabel.append("tspan").classed({
              unit: true
            }).text(" [µm]");
            return xLabel.append("tspan").classed({
              variable: true
            }).text(" λ");
          });
          return svg.append("g").classed({
            wavelength: true,
            interactive: true
          }).attr({
            "text-anchor": "middle"
          }).append("text");
        });
        plots = svg.select(".plots");
        solutions = plots.select(".solutions");
        plotsBg = plots.select(".bg");
        defs = svg.select("defs");
        clip = defs.select(".planck-path rect");
        el_xAxis = svg.select(".axis.x");
        el_yAxis = svg.select(".axis.y");
        yLabel = svg.select(".label.y text");
        xLabel = svg.select(".label.x text");
        wavelengthLabel = svg.select(".wavelength.interactive");
        wienSeries = plots.select(".wien");
        spectrum = svg.select(".spectrum");
        slider = svg.selectAll(".slider").data([1]).call(function(slider) {
          slider = slider.enter().append("g").classed({
            slider: true
          });
          slider.append("text").classed({
            formula: true,
            label: true
          }).call(function(sliderFormula) {
            sliderFormula.append("tspan").classed({
              variable: true
            }).text("I(");
            sliderFormula.append("tspan").classed({
              variable: true,
              wavelength: true
            }).text("λ");
            return sliderFormula.append("tspan").classed({
              variable: true
            }).text(",T)");
          });
          slider.append("text").classed({
            label: true,
            axisLabel: true
          }).attr({
            "text-anchor": "middle"
          }).call(function(sliderLabel) {
            sliderLabel.append("tspan").text("Temperature");
            sliderLabel.append("tspan").text(" [K]").classed({
              unit: true
            });
            return sliderLabel.append("tspan").text(" T").classed({
              variable: true
            });
          });
          slider.selectAll(".reference").data(references).enter().append("g").classed({
            reference: true
          }).call(function(reference) {
            reference.append("circle").attr(sliderCircle).style({
              fill: temperatureColor
            });
            reference.append("text").classed({
              temperature: true
            }).text(function(d) {
              return d.temperature;
            }).style({
              fill: temperatureColor
            }).attr({
              dy: ".35em",
              "text-anchor": "end",
              x: sliderPadding.temperature
            });
            return reference.append("text").classed({
              solution: true
            }).attr({
              x: sliderPadding.solution,
              dy: ".35em",
              "text-anchor": "end"
            }).style({
              fill: temperatureColor
            });
          });
          return slider.append("g").classed({
            handle: true
          }).call(function(slideHandle) {
            slideHandle.call(slide);
            return slideHandle.append("circle").attr(sliderCircle);
          });
        });
        sliderReferences = slider.selectAll(".reference");
        slideHandle = slider.select(".handle");
        sliderLabel = slider.select(".label.axisLabel");
        sliderFormula = slider.select(".label.formula");
        handleLabel = slideHandle.select("text.temperature");
        handleSolution = slideHandle.select("text.solution");
        d3.select(window).on({
          "resize.planck": api.resize
        });
        return api.resize();
      };
      return api;
    };
    return Planck;
  });

}).call(this);
