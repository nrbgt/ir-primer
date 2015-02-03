define [], ->
  d3 = null

  # constants
  c1_boltzman = 3.74e8
  c2_boltzman = 1.44e4
  wien = 2898


  # formulae
  plancksLaw = (temperature, wavelength) ->
    [
      wavelength,
      c1_boltzman / (
        (wavelength ** 5) * (
          Math.exp(c2_boltzman / (wavelength * temperature)) - 1
        )
      )
    ]

  # magic numbers
  padding = top: 40, left: 120, right: 80, bottom: 90
  xDomain = [0.1, 100]
  yDomain = [1e-4, 1e9]
  axisW = 20
  sliderCircle = r: 18, cx: 22
  sidebarWidth = 150

  # data
  wavelengths = (i for i in [0..0.95] by 0.05)
     .concat (i for i in [1..19.5] by 0.5)
     .concat (i for i in [20..100] by 1)

  temperatures = [
    100, 200, 400, 600, 800, 1000,
    2000, 3000, 4000, 5000, 6000
  ]


  # d3 generatory things
  expwn = (d) ->
    d.toExponential 1
      .replace /^(.*)e([+-])(\d*)$/,
        (match, mag, sign, exp)->
          sign = if sign == "-" then "⁻" else ""
          exp =  exp.split ""
            .map (e) -> "⁰¹²³⁴⁵⁶⁷⁸⁹"[+e]
            .join ""
          mag + "×10" + sign + exp


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
    # TODO: expose as settable/gettable?
    TEMPERATURE = temperatures[0]
    WAVELENGTH = wavelengths.slice(-1)[0]

    color = d3.scale.category20c()
    temperatureColor = (d) -> color d.temperature

    # data
    references = temperatures.map makeSeries

    # d3 functions
    seriesPath = d3.svg.line()
      .x (d) -> xScale d[0]
      .y (d) -> yScale d[1]
      .interpolate "basis"

    sliderScale = d3.scale.log()
      .domain d3.extent temperatures

    sliderWidth = 140

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
      selection.classed planck: true

      explore = ->
        #console.log WAVELENGTH, xScale(WAVELENGTH),  d3.event.dx, d3.mouse @
        WAVELENGTH = xScale.invert d3.mouse(@)[0]
        render()

      render = ->
        series = makeSeries TEMPERATURE
        slideHandle.attr transform: "translate(0, #{ sliderScale TEMPERATURE })"
        handleLabel.text "#{ TEMPERATURE }°K"
        plots.selectAll '.interactive'
          .data [series]
          .call plotSeries
          .classed interactive: true
          .select "path"
            .style color: "black"

        solutions.selectAll ".solution"
          .data ->
            references.map (d) ->
              series: d
              solution: plancksLaw d.temperature, WAVELENGTH
          .call (solution) ->
            solution.enter()
              .append "g"
              .classed solution: true
              .call (solution) ->
                solution.append "circle"
                  .attr r: 5
                  .style stroke: (d) -> temperatureColor d.series
          .attr transform: (d) ->
            "translate(#{xScale d.solution[0]}, #{yScale d.solution[1]} )"

      # update screen-relevant stuff
      resize = ->
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

        el_yAxis.attr transform: "translate(#{ padding.left }, 0)"
          .call yAxis

        yLabel.attr transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"
        xLabel.attr transform: "translate(#{ [WIDTH/2, HEIGHT - 50] })"

        el_references = plots.selectAll '.series'
          .data references
          .call plotSeries

        sliderScale.range [
          HEIGHT - (sliderCircle.r * 4),
          sliderCircle.r * 4
        ]
        slider.attr transform: "translate(#{ WIDTH - sidebarWidth }, 0)"
        sliderReferences.attr transform: (d) ->
          "translate(0, #{ sliderScale d.temperature })"

        render()

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
                .text " [W/m²-µ]"

          plotSvg.append "g"
            .classed label: true, x: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em", y: -10
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Wavelength"

              yLabel.append "tspan"
                .classed unit: true
                .text " [µ]"


      plots = plotSvg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = plotSvg.select "defs"
      clip = defs.select ".planck-path rect"
      el_xAxis = plotSvg.select ".axis.x"
      el_yAxis = plotSvg.select ".axis.y"
      yLabel = plotSvg.select ".label.y text"
      xLabel = plotSvg.select ".label.x text"

      # slider stuff
      slide = d3.behavior.drag()
        .on "drag", (value) ->
          val = parseInt sliderScale.invert d3.event.y
          TEMPERATURE = Math.max temperatures[0],
            Math.min(val, temperatures.slice(-1)[0])
          render()

      slider = plotSvg.selectAll ".slider"
        .data [1]
        .call (slider) ->
          slider = slider.enter()
            .append "g"
            .classed slider: true

          slider.append "text"
            .classed variable: true
            .attr y: sliderCircle.r * 2, x: sliderCircle.r * .5
            .text "T"
            .style "font-style": "italic", "font-size": 32


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
                .text (d) -> d.temperature
                .attr dy: ".35em", x: sliderCircle.cx, "text-anchor": "middle"

          slider.append "g"
            .classed handle: true
            .call (slideHandle) ->
                slideHandle.call slide
                slideHandle.append "circle"
                  .attr sliderCircle
                slideHandle.append "text"
                  .attr dy: ".35em", x: 48 # TODO: magic number

      sliderReferences = slider.selectAll ".reference"
      slideHandle = slider.select ".handle"
      handleLabel = slideHandle.select "text"

      d3.select window
        .on resize: resize

      resize()

    # end of the
    return api

  # THIS IS THE END of the library
  return Planck
