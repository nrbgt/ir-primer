define ["./explanation.js"], (Exp)->
  d3 = null

  # magic numbers
  padding =
    top: 40
    left: 120
    right: 120
    bottom: 90
  sliderPadding =
    top: 80
    left: 10
    right: 10
    bottom: 110
    temperature: 40
    solution: 140

  domains =
    x: [0, 2000]
    y0: [-500, 2000]
    y1: [-1000, 4000]

  converters = [
    Exp.laws.Celsius
    Exp.laws.Fahrenheit
    Exp.laws.Rankine
  ]

  labels = [
    "Celsius [C]"
    "Fahrenheit [F]"
    "Rankine [R]"
  ]

  references = converters.map (convert, i) ->
    scaleIdx: i
    points: domains.x.map (k)-> [k, convert k]

  Temperatures = (_d3)->
    d3 = _d3

    scales =
      x: d3.scale.linear().domain domains.x
      y0: d3.scale.linear().domain domains.y0
      y1: d3.scale.linear().domain domains.y1
      color: d3.scale.ordinal().range ["green", "red", "blue"]

    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y0: d3.svg.axis().scale(scales.y0).orient 'left'
      y1: d3.svg.axis().scale(scales.y1).orient 'right'

    seriesPath = (y)->
      d3.svg.line()
        .x (d) -> scales.x d[0]
        .y (d) -> y d[1]

    useScale = [scales.y0, scales.y1, scales.y1]

    plotSeries = (series) ->
      # generate an svg path from a series
      series
        .call (series) ->
          series.enter()
            .append "g"
            .classed series: true
            .append "path"
            .style stroke: (d, i)-> scales.color i

        .selectAll "path"
          .attr d: (d)->
            fn = seriesPath useScale[d.scaleIdx]
            fn d.points

    colorizeLegend = (d, i) ->
      if i then scales.color i - 1  else "black"

    dispatch = d3.dispatch "update"

    api = (selection) ->
      selection.classed
        explanation: true
        temperatures: true

      TEMPERATURE = 0


      api.explore = ->
        [mouseX, mouseY] = d3.mouse @
        TEMPERATURE = Math.min(
          domains.x[1]
          Math.max scales.x.invert(mouseX), domains.x[0]
        )
        api.update()

      api.update = ->
        scaleSolutions = converters.map (convert)->
          [
            TEMPERATURE
            convert TEMPERATURE
          ]

        dispatch.update
          K: TEMPERATURE
          C: scaleSolutions[0][1]
          F: scaleSolutions[1][1]
          R: scaleSolutions[2][1]

        svg.selectAll ".solution.interactive"
          .data [
            [TEMPERATURE, scaleSolutions[0][1]]
            [TEMPERATURE, scaleSolutions[1][1]]
            [TEMPERATURE, scaleSolutions[2][1]]
          ]
          .call (solutionLabel) ->
            solutionLabel.enter()
              .append "g"
              .classed solution: true, interactive: true
              .append "line"
              .style
                stroke: (d, i) -> ["green", "red", "blue"][i]
              .attr
                x1: 0
                y1: 0
                x2: (d, i) -> if i == 0 then 20 else -20
                y2: 0
                "marker-start": (d, i) -> "url(#end-arrow-#{scales.color i})"


          .attr
            transform: (d, i) ->
              if i == 0
                "translate(#{padding.left}, #{scales.y0 d[1]})"
              else
                "translate(#{scales.x.range()[1]}, #{scales.y1 d[1]})"
          .select "text"
            .text (d, i)-> "#{'KCFR'[i]} = #{d[1].toFixed 2}"

        plots.select ".scanline path"
          .datum [
            [scales.x(TEMPERATURE), scales.y0.range()[0]]
            [scales.x(TEMPERATURE), scales.y0.range()[1]]
          ]
          .attr
            d: d3.svg.line()

        solutions
          .attr
            transform: "translate(#{ padding.left + 2 * padding.top }, #{ 2 * padding.top})"
          .selectAll ".solution.legend"
          .data [[TEMPERATURE, TEMPERATURE]].concat scaleSolutions
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
                transform: (d, i) -> "translate(0 #{i * 30})"

            solution.select ".scale"
              .text (d, i) -> ["Kelvin [K]"].concat(labels)[i]
              .style fill: colorizeLegend

            solution.select ".value"
              .text (d, i) -> d[1].toFixed 2
              .style fill: colorizeLegend
        api

      api.resize = (event) ->
        # do things based on window resize
        WIDTH = selection.node().clientWidth
        HEIGHT = selection.node().clientHeight

        scales.x.range [padding.left, WIDTH - padding.right]
        scales.y1.range [HEIGHT - padding.bottom, padding.top]
        scales.y0.range [HEIGHT - padding.bottom, padding.top]

        svg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr width: WIDTH - padding.right, height: HEIGHT
        clip.attr
          width: WIDTH,
          height: scales.y0.range()[0],
          x: 0

        el_xAxis.attr transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call axes.x

        el_y0Axis.attr transform: "translate(#{ padding.left }, 0)"
          .call axes.y0

        el_y1Axis.attr transform: "translate(#{ WIDTH - padding.right }, 0)"
          .call axes.y1

        xLabel.attr
          transform: "translate(#{ [WIDTH/2, HEIGHT - 50] })"
        y0Label.attr
          transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"
        y1Label.attr
          transform: "translate(#{ WIDTH - 10 }, #{ HEIGHT/2 }) rotate(90)"

        plots.selectAll '.series'
          .data references
          .call plotSeries

        api.update()

      svg = selection.selectAll ".plot"
        .data [1]
        .call (svg) ->
          svg = svg.enter()
            .append "svg"
            .classed plot: true

          svg.append "defs"
            .call (defs) ->
              defs.append "clipPath"
                .classed "temperatures-path": true
                .attr id: "temperaturesPath"
                .append "rect"

              defs.selectAll "marker"
                .data scales.color.range()
                .enter()
                .append "marker"
                .attr
                  id: (d) -> "end-arrow-#{d}"
                  viewBox: "0 -5 10 10"
                  markerWidth: 6
                  markerHeight: 6
                  orient: "auto"
                .append "path"
                .attr d: "M 10,-5 L 0,0 L 10,5"
                .style fill: Object


          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#temperaturesPath)"
            .call (plots) ->
              plots.append "rect"
                .classed bg: true
                .on mousemove: api.explore

              plots.append "g"
                .classed solutions: true

              plots.append "g"
                .classed scanline: true
                .append "path"

          svg.append "g"
            .classed axis: true, x: true

          svg.append "g"
            .classed axis: true, y0: true

          svg.append "g"
            .classed axis: true, y1: true

          svg.append "g"
            .classed label: true, y0: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .classed "fill-celsius": true
                .text "Celsius"

              yLabel.append "tspan"
                .classed unit: true
                .text " ["

              yLabel.append "tspan"
                .classed "fill-celsius": true
                .text "C"

              yLabel.append "tspan"
                .classed unit: true
                .text "]"

          svg.append "g"
            .classed label: true, y1: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Fahrenheit "
                .classed "fill-fahrenheit": true

              yLabel.append "tspan"
                .text "Rankine"
                .classed "fill-rankine": true

              yLabel.append "tspan"
                .classed unit: true
                .text " ["

              yLabel.append "tspan"
                .classed "fill-fahrenheit": true
                .text "F"

              yLabel.append "tspan"
                .classed unit: true
                .text ","

              yLabel.append "tspan"
                .classed "fill-rankine": true
                .text "R"

              yLabel.append "tspan"
                .classed unit: true
                .text "]"

          svg.append "g"
            .classed label: true, x: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em", y: -10
            .call (xLabel) ->
              xLabel.append "tspan"
                .text "Kelvin"


              xLabel.append "tspan"
                .classed unit: true
                .text " ["

              xLabel.append "tspan"
                .classed "fill-kelvin": true
                .text "K"

              xLabel.append "tspan"
                .classed unit: true
                .text "]"

      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".temperatures-path rect"
      el_xAxis = svg.select ".axis.x"
      el_y0Axis = svg.select ".axis.y0"
      el_y1Axis = svg.select ".axis.y1"
      xLabel = svg.select ".label.x text"
      y0Label = svg.select ".label.y0 text"
      y1Label = svg.select ".label.y1 text"

      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.temperatures": api.resize

      api.resize()

    api.dispatch = dispatch

    return api

  return Temperatures
