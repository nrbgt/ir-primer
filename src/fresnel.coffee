define ["./explanation.js"], (Exp)->
  d3 = null

  # magic numbers
  padding =
    top: 40
    left: 120
    right: 120
    bottom: 200

  domains =
    x: [0, 90]
    y: [0, 1]
    iofr: [0, 3]

  angles = (i for i in [0..90] by 0.5)

  solutionParts = ["rs", "rp", "rtotal"]

  Fresnel = (_d3)->
    d3 = _d3

    scales =
      x: d3.scale.linear().domain domains.x
      y: d3.scale.linear().domain domains.y
      color: d3.scale.ordinal().range ["red", "blue", "green"]
      iofr: d3.scale.linear().domain domains.iofr

    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y: d3.svg.axis().scale(scales.y).orient 'left'
      iofr: d3.svg.axis().scale(scales.iofr).orient 'bottom'

    seriesPath = d3.svg.line()
      .x (d) -> scales.x d[0]
      .y (d) -> scales.y d[1]

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
          .data (d)-> [d.points]
          .attr d: seriesPath

    colorizeLegend = (d, i) ->
      if i then scales.color i - 1 else "black"

    api = (selection) ->
      selection.classed
        fresnel: true
        explanation: true

      INDEX_N = [1.0, 1.5]
      INCIDENT_ANGLE_N1 = 60
      INCIDENT_ANGLE = 60

      api.explore = ->
        [mouseX, mouseY] = d3.mouse @
        INCIDENT_ANGLE = Math.min(
          domains.x[1]
          Math.max scales.x.invert(mouseX), domains.x[0]
        )
        api.update()

      api.exploreIofR = (d, i)->
        [mouseX, mouseY] = d3.mouse @
        INDEX_N[d.key - 1] = scales.iofr.invert mouseX
        api.update()

      api.update = ->
        serieses = (series: key, points: [] for key in solutionParts)

        angles.map (angle) ->
          data = Exp.laws.Fresnel angle, INCIDENT_ANGLE_N1, INDEX_N[0], INDEX_N[1]
          serieses.map (series) ->
            series.points.push [
              angle
              data[series.series]
            ]

        scaleSolution = Exp.laws.Fresnel INCIDENT_ANGLE, INCIDENT_ANGLE_N1, INDEX_N[0], INDEX_N[1]

        scaleSolutions = solutionParts.map (part)->
          [
            INCIDENT_ANGLE
            scaleSolution[part]
          ]

        plots.selectAll ".scanline path"
          .data [
            [
              [scales.x(INCIDENT_ANGLE), scales.y.range()[0]]
              [scales.x(INCIDENT_ANGLE), scales.y.range()[1]]
            ]
          ]
          .attr
            d: d3.svg.line()

        labels = [
          "Incident Angle"
          "Reflection (Perpendicular)"
          "Reflection (Parallel)"
          "Reflection (Average)"
        ]

        solutions
          .selectAll ".solution.legend"
          .data [[INCIDENT_ANGLE, INCIDENT_ANGLE]].concat scaleSolutions
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
                transform: (d, i) -> """
                translate(
                  #{1.5 * padding.left} #{padding.top + ((i + 1) * 30)}
                )"""

            solution.select ".scale"
              .text (d, i) -> labels[i]
              .style fill: colorizeLegend

            solution.select ".value"
              .text (d, i) -> d[1].toFixed 2
              .style fill: colorizeLegend

        solutions.selectAll ".solution.interactive"
          .data [
            [INCIDENT_ANGLE, scaleSolutions[0][1]]
            [INCIDENT_ANGLE, scaleSolutions[1][1]]
            [INCIDENT_ANGLE, scaleSolutions[2][1]]
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
                x2: 20
                y2: 0
                "marker-start": (d, i) -> "url(#end-arrow-#{scales.color i})"
          .attr
            transform: (d, i) -> "translate(#{padding.left}, #{scales.y d[1]})"

        iofrValues
          .attr
            transform: (d) ->
              "translate(#{ scales.iofr INDEX_N[d.key - 1] }, 0)"
          .select "text"
          .text (d) -> INDEX_N[d.key - 1].toFixed 2

        plots.selectAll '.series'
          .data serieses
          .call plotSeries

        api

      api.resize = (event) ->
        # do things based on window resize
        WIDTH = selection.node().clientWidth
        HEIGHT = selection.node().clientHeight

        scales.x.range [padding.left, WIDTH - padding.right]
        scales.y.range [HEIGHT - padding.bottom, padding.top]
        scales.iofr.range [padding.left, (WIDTH - padding.left - padding.right) / 2]

        svg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr
          y: padding.top
          width: WIDTH - padding.right
          height: HEIGHT - padding.top


        iofr.attr
          transform: (d, i) ->
            "translate(#{ i * (WIDTH / 2) }, #{ HEIGHT - 80 })"

        iofrBg.attr
          y: -20
          x: padding.left
          width: scales.iofr.range()[1] - scales.iofr.range()[0]
          height: 50

        clip.attr
          width: WIDTH,
          height: scales.y.range()[0],
          y: padding.top
          x: 0

        el_xAxis.attr transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call axes.x

        el_yAxis.attr transform: "translate(#{ padding.left }, 0)"
          .call axes.y

        el_iofrAxis
          .call axes.iofr

        xLabel.attr
          transform: "translate(#{ WIDTH/2 }, #{scales.y.range()[0] + 40})"
        yLabel.attr
          transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"

        iofrLabel.attr
          transform: "translate(#{ WIDTH / 4 }, 50)"

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
                .classed "fresnel-path": true
                .attr id: "fresnelPath"
                .append "rect"

              defs.selectAll "marker.arrow"
                .data scales.color.range()
                .enter()
                .append "marker"
                .classed arrow: true
                .attr
                  id: (d) -> "end-arrow-#{d}"
                  viewBox: "0 -5 10 10"
                  markerWidth: 6
                  markerHeight: 6
                  orient: "auto"
                .append "path"
                .attr d: "M 10,-5 L 0,0 L 10,5"
                .style fill: Object

          svg.selectAll ".iofr"
            .data d3.entries
              1: "Originating Index of Refraction"
              2: "Incident Index of Refraction"
            .enter()
            .append "g"
            .classed iofr: true
            .on "mousemove", api.exploreIofR
            .call (iofr) ->
              iofr.append "rect"
                .classed bg: true
              iofr.append "text"
                .classed label: true
                .text (d, i) -> "n#{d.key}: #{d.value}"
                .attr
                  "text-anchor": "middle"

              iofr.append "g"
                .classed interactive: true
                .append "text"
                .attr
                  dy: "-.35em"
                  "text-anchor": "middle"
              iofr.append "g"
                .classed axis: true

          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#fresnelPath)"
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
            .classed axis: true, y: true

          svg.append "g"
            .classed label: true, x: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em", y: -10
            .call (xLabel) ->
              xLabel.append "tspan"
                .text "Incident Angle"

              xLabel.append "tspan"
                .classed unit: true
                .text " [deg]"

          svg.append "g"
            .classed label: true, y: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              spans =

              yLabel.selectAll "tspan"
                .data [
                    ["Reflection", [], null]
                    [" [", "unit", null]
                    ["Rs ", null, scales.color 0]
                    ["Rp ", null, scales.color 1]
                    ["Rtotal", null, scales.color 2]
                    ["]", "unit", null]
                  ]
                .enter()
                .append "tspan"
                .text (d)-> d[0]
                .attr
                  class: (d)-> d[1]
                .style
                  fill: (d)-> d[2]

      plots = svg.select ".plots"
      iofr = svg.selectAll ".iofr"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      iofrBg = iofr.selectAll ".bg"
      iofrLabel = svg.selectAll ".iofr .label"
      iofrValues = iofr.selectAll ".interactive"
      defs = svg.select "defs"
      clip = defs.select ".fresnel-path rect"
      el_xAxis = svg.select ".axis.x"
      el_yAxis = svg.select ".axis.y"
      el_iofrAxis = svg.selectAll ".iofr .axis"
      xLabel = svg.select ".label.x text"
      yLabel = svg.select ".label.y text"

      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.fresnel": api.resize

      api.resize()

    return api

  return Fresnel
