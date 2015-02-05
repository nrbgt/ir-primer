define ["./explanation.js"], (Exp)->
  d3 = null

  # formulae
  plancksLaw = (temperature, wavelength) ->
    [
      wavelength
      Exp.laws.Planck temperature, wavelength
    ]

  wiensLaw = (temperature) ->
    plancksLaw temperature, Exp.laws.Wien temperature

  # magic numbers
  padding = top: 40, left: 120, right: 80, bottom: 90
  sliderPadding = {
    top: 80, left: 10, right: 10, bottom: 110, temperature: 40, solution: 140
  }
  xDomain = [0.1, 100]
  yDomain = [1e-4, 1e9]
  axisW = 20
  sliderCircle = r: 5, cx: 0
  sidebarWidth = 180

  # data
  wavelengths = (i for i in [0.1..1.99] by 0.01)
     .concat (i for i in [2..19.5] by 0.5)
     .concat (i for i in [20..100] by 1)

  temperatures = [
    100, 200, 400, 600, 800, 1000,
    2000, 3000, 4000, 5000, 6000
  ]

  wiens = temperatures.map (temperature) -> wiensLaw temperature

  # d3 generatory things
  expwn = Exp.scientificNotation


  makeSeries = (temperature)->
    # accepts a temperature (in Kelvin), returns a sampled series of points
    # solving Planck's Law
    temperature: temperature
    spectral_exitance: wavelengths
      .map (wavelength)-> plancksLaw temperature, wavelength
      .filter (point)-> point[1]


  Planck = (_d3) ->
    d3 = _d3
    # instance-level values...
    TEMPERATURE = temperatures.slice(-1)[0]
    WAVELENGTH = wavelengths.slice(-1)[0]
    HOVERWIEN = false

    color = d3.scale.category20b()
    temperatureColor = (d) -> color d.temperature

    # data
    references = temperatures.map makeSeries

    # d3 functions
    seriesPath = d3.svg.line()
      .x (d) -> xScale d[0]
      .y (d) -> yScale d[1]

    sliderScale = d3.scale.log()
      .domain d3.extent temperatures

    plotSeries = (series) ->
      # generate an svg path from a series
      series
        .call (series) ->
          series.enter()
            .append "g"
            .classed series: true
            .append "path"
            .style stroke: temperatureColor

        .selectAll "path"
          .data (d) -> [d.spectral_exitance]
          .attr d: seriesPath

    # scales
    xScale = d3.scale.log()
      .domain xDomain
    yScale = d3.scale.log()
      .domain yDomain

    xAxis = d3.svg.axis()
      .scale xScale
      .orient 'bottom'
    yAxis = d3.svg.axis()
      .scale yScale
      .orient 'left'


    api = (selection) ->
      # probably not reentrant
      selection.classed planck: true, explanation: true

      explore = ->
        [mouseX, mouseY] = d3.mouse @
        WAVELENGTH = xScale.invert mouseX

        val = parseInt sliderScale.invert mouseY
        TEMPERATURE = Math.max temperatures[0],
          Math.min(val, temperatures.slice(-1)[0])

        api.update()

      api.update = ->
        series = makeSeries TEMPERATURE
        solution = if HOVERWIEN
            wiensLaw TEMPERATURE
          else
            plancksLaw TEMPERATURE, WAVELENGTH

        slideHandle.attr transform: "translate(0, #{ sliderScale TEMPERATURE })"
        handleLabel.text TEMPERATURE
        handleSolution.text if solution[1] then "I: #{expwn solution[1]}" else ""
        plots.selectAll '.series.interactive'
          .data [series]
          .call plotSeries
          .classed interactive: true
          .select "path"
            .style color: "black"

        wavelengthLabel.attr transform: "translate(#{ xScale WAVELENGTH }, 20)"
          .select "text"
          .text "λ: #{ WAVELENGTH.toFixed(2) }"

        solutions.selectAll '.solution.interactive'
          .data [solution.solution]
          .call (solution) ->
            solution.enter()
              .append "g"
              .classed solution: true, interactive: true
              .append "circle"
              .attr r: 3
          .attr transform: (d) ->
            "translate(#{xScale solution[0]}, #{yScale solution[1]} )"

        wavelengthSolutions = references.map (d) ->
          series: d
          solution: if HOVERWIEN
              wiensLaw d.temperature
            else
              plancksLaw d.temperature, WAVELENGTH

        solutionObj = wavelengthSolutions.reduce(
          (memo, obj, i)->
            memo[obj.series.temperature] = obj.solution[1]
            memo
          {}
        )

        sliderReferences.selectAll "text.solution"
          .text (d) -> "#{ expwn solutionObj[d.temperature] }"

        solutions.selectAll ".solution.reference"
          .data wavelengthSolutions
          .call (solution) ->
            solution.enter()
              .append "g"
              .classed solution: true, reference: true
              .call (solution) ->
                solution.append "circle"
                  .attr r: 5
                  .style stroke: (d) -> temperatureColor d.series
          .attr transform: (d) ->
            "translate(#{xScale d.solution[0]}, #{yScale d.solution[1]} )"

        # for chaining
        api

      # update screen-relevant stuff
      api.resize = (event)->
        WIDTH = selection.node().clientWidth
        HEIGHT = selection.node().clientHeight

        xScale.range [padding.left, WIDTH - padding.right - sidebarWidth]
        yScale.range [HEIGHT - padding.bottom, padding.top]

        plotSvg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr width: WIDTH - padding.right - sidebarWidth, height: HEIGHT
        clip.attr {
          width: xScale.range().slice(-1),
          height: yScale.range()[0],
          x: padding.left
        }

        el_xAxis.attr transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call xAxis
          .selectAll "text"
          .text ->
            parseFloat this.textContent unless not this.textContent

        el_yAxis.attr transform: "translate(#{ padding.left }, 0)"
          .call yAxis
          .selectAll "text"
          .text -> expwn this.textContent

        yLabel.attr transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"
        xLabel.attr transform: "translate(#{ [WIDTH/2, HEIGHT - 50] })"

        el_references = plots.selectAll '.series'
          .data references
          .call plotSeries

        sliderScale.range [
          HEIGHT - sliderPadding.bottom
          sliderPadding.top
        ]
        slider.attr transform: "translate(#{ xScale.range()[1] + 20 }, 0)"
        sliderLabel.attr transform: "translate(#{ sidebarWidth }, #{ HEIGHT/2 }) rotate(90)"
        sliderReferences.attr transform: (d) ->
          "translate(0, #{ sliderScale d.temperature })"

        wienSeries.selectAll "path"
          .data [wiens]
          .attr d: seriesPath

        api.update()

      plotSvg = selection.selectAll ".plot.planck"
        .data [1]
        .call (plotSvg) ->
          plotSvg = plotSvg.enter()
            .append "svg"
            .classed plot: true

          plotSvg.append "defs"
            .append "clipPath"
              .classed "planck-path": true
              .attr id: "planckPath"
              .append "rect"

          plotSvg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#planckPath)"
            .call (plots) ->
              plots.append "rect"
                .classed bg: true
                .on mousemove: explore

              plots.append "g"
                .classed solutions: true

              plots.append "g"
                .classed wien: true
                .on {
                  mouseover: ->
                    HOVERWIEN = true
                    api.update()
                  mouseout: ->
                    HOVERWIEN = false
                    api.update()
                }
                .append "path"

          plotSvg.append "g"
            .classed axis: true, x: true

          plotSvg.append "g"
            .classed axis: true, y: true

          plotSvg.append "g"
            .classed label: true, y: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Spectral Exitance"

              yLabel.append "tspan"
                .classed unit: true
                .text " [W/m²-µm]"

              yLabel.append "tspan"
                .classed variable: true
                .text " I(λ,T)"

          plotSvg.append "g"
            .classed label: true, x: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em", y: -10
            .call (xLabel) ->
              xLabel.append "tspan"
                .text "Wavelength"

              xLabel.append "tspan"
                .classed unit: true
                .text " [µm]"

              xLabel.append "tspan"
                .classed variable: true
                .text " λ"


          plotSvg.append "g"
            .classed wavelength: true, interactive: true
            .attr "text-anchor": "middle"
            .append "text"



      plots = plotSvg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = plotSvg.select "defs"
      clip = defs.select ".planck-path rect"
      el_xAxis = plotSvg.select ".axis.x"
      el_yAxis = plotSvg.select ".axis.y"
      yLabel = plotSvg.select ".label.y text"
      xLabel = plotSvg.select ".label.x text"
      wavelengthLabel = plotSvg.select ".wavelength.interactive"
      wienSeries = plots.select ".wien"


      # slider stuff
      slide = d3.behavior.drag()
        .on "drag", (value) ->
          val = parseInt sliderScale.invert d3.event.y
          TEMPERATURE = Math.max temperatures[0],
            Math.min(val, temperatures.slice(-1)[0])
          api.update()

      slider = plotSvg.selectAll ".slider"
        .data [1]
        .call (slider) ->
          slider = slider.enter()
            .append "g"
            .classed slider: true

          slider.append "text"
            .classed label: true
            .attr "text-anchor": "middle"
            .call (sliderLabel) ->
              sliderLabel.append "tspan"
                .text "Temperature"
              sliderLabel.append "tspan"
                .text " [K]"
                .classed unit: true
              sliderLabel.append "tspan"
                .text " T"
                .classed variable: true


          slider.selectAll ".reference"
            .data references
            .call (init) ->
              init = init.enter()
                .append "g"
                .classed reference: true

              init.append "circle"
                .attr sliderCircle
                .style fill: temperatureColor

              init.append "text"
                .classed temperature: true
                .text (d) -> d.temperature
                .attr {
                  dy: ".35em"
                  "text-anchor": "end"
                  x: sliderPadding.temperature
                }
                .style fill: temperatureColor

              init.append "text"
                .classed solution: true
                .attr x: sliderPadding.solution, dy: ".35em", "text-anchor": "end"
                .style fill: temperatureColor

          slider.append "g"
            .classed handle: true
            .call (slideHandle) ->
              slideHandle.call slide
              slideHandle.append "circle"
                .attr sliderCircle
              """
              slideHandle.append "text"
                .classed temperature: true
                .attr dy: ".35em", x: sliderCircle.cx, "text-anchor": "middle"
              slideHandle.append "text"
                .classed solution: true
                .attr "text-anchor": "end", dy: ".35em", dx: -5
              """

      sliderReferences = slider.selectAll ".reference"
      slideHandle = slider.select ".handle"
      sliderLabel = slider.select "text"
      handleLabel = slideHandle.select "text.temperature"
      handleSolution = slideHandle.select "text.solution"

      d3.select window
        .on "resize.planck": api.resize

      api.resize()

    # end of the instance api
    return api

  # THIS IS THE END of the library
  return Planck
