define ["./explanation.js"], (Exp)->
  d3 = null

  # magic numbers
  padding =
    top: 40
    left: 120
    right: 120
    bottom: 110

  domains =
    x: [0, 2.5e4]
    y: [
      [0, 300]
      [0, 1]
    ]

  elevations = (i for i in [0..2.5e4] by 500)

  solutionParts = ["K", "rP", "rD"]


  references = solutionParts.map (key, i) ->
    series: key
    scaleIdx: if i == 2 then 1 else i
    points: []

  labels = [
    "Altitude [m]"
    "Temperature [K]"
    "Relative Pressure"
    "Relative Density"
  ]

  elevations.map (elevation) ->
    data = Exp.laws.Density elevation
    references.map (series) ->
      series.points.push [
        elevation
        data[series.series]
      ]

  Density = (_d3)->
    d3 = _d3

    scales =
      x: d3.scale.linear().domain domains.x
      y: [
        d3.scale.linear().domain domains.y[0]
        d3.scale.linear().domain domains.y[1]
      ]
      color: d3.scale.ordinal().range ["blue", "red", "green"]

    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y: [
        d3.svg.axis().scale(scales.y[0]).orient 'left'
        d3.svg.axis().scale(scales.y[1]).orient 'right'
      ]

    seriesPath = (y) ->
      d3.svg.line()
        .x (d) -> scales.x d[0]
        .y (d) -> y d[1]

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
          .attr d: (d, i)->
            fn = seriesPath scales.y[d.scaleIdx]
            fn d.points

    colorizeLegend = (d, i) ->
      if i then scales.color i - 1 else "black"


    api = (selection) ->
      selection.classed
        density: true
        explanation: true

      ELEVATION = 60

      api.explore = ->
        [mouseX, mouseY] = d3.mouse @
        ELEVATION = Math.min(
          domains.x[1]
          Math.max scales.x.invert(mouseX), domains.x[0]
        )
        api.update()

      api.update = ->
        scaleSolution = Exp.laws.Density ELEVATION

        scaleSolutions = solutionParts.map (part)->
          [
            ELEVATION
            scaleSolution[part]
          ]

        svg.selectAll ".solution.interactive"
          .data [
            [ELEVATION, scaleSolutions[0][1]]
            [ELEVATION, scaleSolutions[1][1]]
            [ELEVATION, scaleSolutions[2][1]]
          ]
          .call (solutionLabel) ->
            solutionLabel.enter()
              .append "g"
              .classed solution: true, interactive: true
              .append "line"
              .style
                stroke: (d, i) -> scales.color i
              .attr
                x1: 0
                y1: 0
                x2: (d, i) -> if i == 0 then 20 else -20
                y2: 0
                "marker-start": (d, i) -> "url(#end-arrow-#{scales.color i})"
          .attr
            transform: (d, i) ->
              if i == 0
                "translate(#{padding.left + 5}, #{scales.y[0] d[1]})"
              else
                "translate(#{scales.x.range()[1] - 5}, #{scales.y[1] d[1]})"
          .select "text"
            .text (d, i)->
                "#{['m','K','rP','rD'][i]} = #{d[1].toFixed 2}"


        plots.select ".scanline path"
          .datum [
            [scales.x(ELEVATION), scales.y[0].range()[0]]
            [scales.x(ELEVATION), scales.y[0].range()[1]]
          ]
          .attr
            d: d3.svg.line()

        solutions
          .attr
            transform: "translate(#{ scales.x.range()[1] - padding.left * 2 }, #{ 2 * padding.top})"
          .selectAll ".solution.legend"
          .data [[ELEVATION, ELEVATION]].concat scaleSolutions
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
              .text (d, i) -> labels[i]
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
        scales.y.map (scale)->
          scale.range [HEIGHT - padding.bottom, padding.top]

        svg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr
          y: padding.top
          width: WIDTH - padding.right
          height: HEIGHT - padding.top


        plots.selectAll '.series'
          .data references
          .call plotSeries


        clip.attr
          width: WIDTH,
          height: scales.y[0].range()[0],
          y: padding.top
          x: 0

        el_xAxis.attr transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call axes.x

        el_y0Axis.attr transform: "translate(#{ padding.left }, 0)"
          .call axes.y[0]

        el_y1Axis.attr
            transform: "translate(#{ WIDTH - padding.right }, 0)"
          .call axes.y[1]

        xLabel.attr
          transform: "translate(#{ WIDTH/2 }, #{scales.y[0].range()[0] + 40})"
        y0Label.attr
          transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"
        y1Label.attr
          transform: "translate(#{ WIDTH - 10 }, #{ HEIGHT/2 }) rotate(90)"

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
                .classed "density-path": true
                .attr id: "densityPath"
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
            .attr "clip-path": "url(#densityPath)"
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
            .classed label: true, x: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em", y: -10
            .call (xLabel) ->
              xLabel.append "tspan"
                .text "Altitude"
                .classed "fill-altitude": true

              xLabel.append "tspan"
                .classed unit: true
                .text " ["

              xLabel.append "tspan"
                .classed "fill-altitude": true
                .text "m"

              xLabel.append "tspan"
                .classed unit: true
                .text " meters]"

          svg.append "g"
            .classed label: true, y0: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Temperature "
                .classed "fill-temperature": true
              yLabel.append "tspan"
                .classed unit: true
                .text "["
              yLabel.append "tspan"
                .classed "fill-temperature": true
                .text "K"
              yLabel.append "tspan"
                .classed unit: true
                .text "]"

          svg.append "g"
            .classed label: true, y1: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em", y: -10
            .call (yLabel) ->
              yLabel.append "tspan"
                .classed unit: true
                .text "Relative "
              yLabel.append "tspan"
                .text "Pressure "
                .classed "fill-relative-pressure": true
              yLabel.append "tspan"
                .text "Density "
                .classed "fill-relative-density": true
              yLabel.append "tspan"
                .classed unit: true
                .text "["
              yLabel.append "tspan"
                .text "bar "
                .classed "fill-relative-pressure": true
              yLabel.append "tspan"
                .text "ρ"
                .classed "fill-relative-density": true
              yLabel.append "tspan"
                .classed unit: true
                .text "]"

      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".density-path rect"
      el_xAxis = svg.select ".axis.x"
      el_y0Axis = svg.select ".axis.y0"
      el_y1Axis = svg.select ".axis.y1"
      xLabel = svg.select ".label.x text"
      y0Label = svg.select ".label.y0 text"
      y1Label = svg.select ".label.y1 text"

      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.density": api.resize

      api.resize()

    return api

  return Density
