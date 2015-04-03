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
  padding =
    top: 40
    left: 120
    right: 80
    bottom: 90
  sliderPadding =
    top: 80
    left: 10
    right: 10
    bottom: 110
    temperature: 40
    solution: 140
  xDomain = [0.1, 100]
  yDomain = [1e-4, 1e9]
  axisW = 20
  sliderCircle = r: 5, cx: 0
  sidebarWidth = 80

  # data
  wavelengths = (i for i in [0.1..1.99] by 0.01)
     .concat (i for i in [2..19.5] by 0.5)
     .concat (i for i in [20..100] by 1)

  temperatures = [
    100, 250, 500, 1000, 2500, 5000
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

    # data
    references = temperatures.map makeSeries

    # d3 functions
    seriesPath = d3.svg.line()
      .x (d) -> scales.x d[0]
      .y (d) -> scales.y d[1]

    temperatureColor = (d) -> scales.color d.temperature

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

    scales =
      x: d3.scale.log().domain xDomain
      y: d3.scale.log().domain yDomain
      slider: d3.scale.log().domain d3.extent temperatures
      color: d3.scale.category20b()

    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y: d3.svg.axis().scale(scales.y).orient 'left'


    api = (selection) ->
      # probably not reentrant
      selection.classed planck: true, explanation: true

      # slider stuff
      slide = d3.behavior.drag()
        .on "drag", (value) ->
          val = parseInt scales.slider.invert d3.event.y
          TEMPERATURE = val
          api.update()

      api.explore = ->
        [mouseX, mouseY] = d3.mouse svg.node()
        WAVELENGTH = scales.x.invert mouseX

        val = parseInt scales.slider.invert mouseY
        TEMPERATURE = Math.max temperatures[0],
          Math.min(val, temperatures.slice(-1)[0])

        api.update()

      api.update = ->
        series = makeSeries TEMPERATURE
        solution = if HOVERWIEN
            wiensLaw TEMPERATURE
          else
            plancksLaw TEMPERATURE, WAVELENGTH

        slideHandle.attr
          transform: "translate(0, #{ scales.slider TEMPERATURE })"
        plots.selectAll '.series.interactive'
          .data [series]
          .call plotSeries
          .classed interactive: true

        sliderFormula.select ".wavelength"
          .classed variable: false
          .text WAVELENGTH.toFixed(2)


        plots.selectAll ".scanline path"
          .data [
            [
              [scales.x(WAVELENGTH), scales.y.range()[0]]
              [scales.x(WAVELENGTH), scales.y.range()[1]]
            ]
          ]
          .attr
            d: d3.svg.line()

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

        labels = [
          "Wavelength [µm]"
          "Temperature [K]"
          "Spectral Exitance [W/m²-µm]"
          "Max Spectral Exitance [W/m²-µm]"
        ]

        solutions
          .selectAll ".solution.legend"
          .data [
            WAVELENGTH.toFixed 2
            TEMPERATURE.toFixed 2
            expwn solution[1]
            expwn wiensLaw(TEMPERATURE)[1]
          ]
          .call (solution) ->
            solution.enter()
              .append "g"
              .classed solution: true, legend: true
              .call (solution) ->
                solution.append "text"
                  .classed scale: true
                  .attr dx: 10
                solution.append "text"
                  .classed value: true
                  .attr "text-anchor", "end"

            solution
              .attr
                transform: (d, i) ->
                  """translate(
                    #{scales.x.range()[1] - sidebarWidth * 4}
                    #{(i+1) * 30})
                  """

            solution.select ".scale"
              .text (d, i) -> labels[i]
              .style fill: (d, i) -> "#900" if i == 3

            solution.select ".value"
              .text (d, i) -> d
              .style fill: (d, i) -> "#900" if i == 3

        # for chaining
        api

      # update screen-relevant stuff
      api.resize = (event)->
        WIDTH = selection.node().clientWidth
        HEIGHT = selection.node().clientHeight

        scales.x.range [padding.left, WIDTH - padding.right - sidebarWidth]
        scales.y.range [HEIGHT - padding.bottom, padding.top]

        svg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr width: WIDTH - padding.right - sidebarWidth, height: HEIGHT

        spectrum
          .attr
            transform: "translate(#{scales.x 0.380} #{padding.top})"
        .select "rect"
          .attr
            width: (scales.x 0.750) - (scales.x 0.380)
            height: HEIGHT

        spectrum.select "text"
          .attr
            transform: (d) ->
              "translate(0 10) rotate(-90)"

        irBand
          .attr
            transform: (d) ->
              "translate(#{ scales.x(d.band[0])} #{padding.top})"
          .select "rect"
            .attr
              height: HEIGHT
              width: (d) -> scales.x(d.band[1]) - scales.x(d.band[0])
        irBand
          .select "text"
          .attr
            transform: (d) ->
              "translate(0 10) rotate(-90)"

        clip.attr
          width: scales.x.range().slice(-1),
          height: scales.y.range()[0],
          x: padding.left

        el_xAxis.attr transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call axes.x
          .selectAll "text"
          .text ->
            parseFloat this.textContent unless not this.textContent

        el_yAxis.attr transform: "translate(#{ padding.left }, 0)"
          .call axes.y
          .selectAll "text"
          .text -> expwn this.textContent

        yLabel.attr transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"
        xLabel.attr transform: "translate(#{ [WIDTH/2, HEIGHT - 50] })"

        plots.selectAll '.series'
          .data references
          .call plotSeries

        scales.slider.range [
          HEIGHT - sliderPadding.bottom
          sliderPadding.top
        ]
        slider.attr
          transform: "translate(#{ scales.x.range()[1] + 20 }, 0)"
        sliderLabel.attr
          transform: "translate(#{ sidebarWidth }, #{ HEIGHT/2 }) rotate(90)"
        sliderFormula.attr
          transform: "translate(#{ sidebarWidth/2 } #{padding.top} )"
        sliderReferences.attr transform: (d) ->
          "translate(0, #{ scales.slider d.temperature })"

        wienSeries.selectAll "path"
          .data [wiens]
          .attr d: seriesPath

        api.update()

      svg = selection.selectAll ".plot"
        .data [1]
        .call (svg) ->
          svg = svg.enter()
            .append "svg"
            .classed plot: true

          defs = svg.append "defs"

          defs.call Exp.defs.spectrum

          defs.append "clipPath"
            .classed "planck-path": true
            .attr id: "planckPath"
            .append "rect"

          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#planckPath)"
            .call (plots) ->
              plots.append "g"
                .classed spectrum: true
                .call (spectrum) ->
                  spectrum.append "rect"
                    .style fill: "url(#spectrumGradient)"
                  spectrum.append "text"
                    .text "Visible Light"
                    .attr
                      dy: "1em"
                      "text-anchor": "end"

              plots.append "g"
                .classed scanline: true
                .append "path"

              plots.call Exp.drawIrBands

              plots.append "rect"
                .classed bg: true
                .on "mousemove.planck": api.explore

              plots.append "g"
                .classed solutions: true

              plots.append "g"
                .classed wien: true
                .on
                  mouseover: ->
                    HOVERWIEN = true
                    api.update()
                  mouseout: ->
                    HOVERWIEN = false
                    api.update()
                .append "path"


          svg.append "g"
            .classed axis: true, x: true

          svg.append "g"
            .classed axis: true, y: true

          svg.append "g"
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

          svg.append "g"
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

      # harvest selectors just initialized
      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".planck-path rect"
      el_xAxis = svg.select ".axis.x"
      el_yAxis = svg.select ".axis.y"
      yLabel = svg.select ".label.y text"
      xLabel = svg.select ".label.x text"
      wienSeries = plots.select ".wien"
      spectrum = svg.select ".spectrum"
      irBand = svg.selectAll ".ir-band"


      slider = svg.selectAll ".slider"
        .data [1]
        .call (slider) ->
          slider = slider.enter()
            .append "g"
            .classed slider: true


          slider.append "text"
            .classed
              label: true
              axisLabel: true
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
            .enter()
            .append "g"
            .classed reference: true
            .call (reference) ->
              reference.append "circle"
                .attr sliderCircle
                .style fill: temperatureColor

              reference.append "text"
                .classed temperature: true
                .text (d) -> d.temperature
                .style fill: temperatureColor
                .attr
                  dy: ".35em"
                  "text-anchor": "end"
                  x: sliderPadding.temperature

          slider.append "g"
            .classed handle: true
            .call (slideHandle) ->
              slideHandle.call slide
              slideHandle.append "circle"
                .attr sliderCircle

      sliderReferences = slider.selectAll ".reference"
      slideHandle = slider.select ".handle"
      sliderLabel = slider.select ".label.axisLabel"
      sliderFormula = slider.select ".label.formula"
      handleLabel = slideHandle.select "text.temperature"
      handleSolution = slideHandle.select "text.solution"

      d3.select window
        .on "resize.planck": api.resize

      api.resize()

    # end of the instance api
    return api

  # THIS IS THE END of the library
  return Planck
