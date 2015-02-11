define ["./explanation.js"], (Exp)->
  d3 = null

  # magic numbers
  padding =
    top: 40
    left: 120
    right: 120
    bottom: 90

  domains =
    x: [0, 90]
    y: [0, 1]

  angles = (i for i in [0..45] by 5)
    .concat (i for i in [45..90] by 1)

  solutionParts = ["rs", "rp", "rtotal"]

  Fresnel = (_d3)->
    d3 = _d3

    scales =
      x: d3.scale.linear().domain domains.x
      y: d3.scale.linear().domain domains.y
      color: d3.scale.ordinal().range ["red", "blue", "green"]

    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y: d3.svg.axis().scale(scales.y).orient 'left'

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
          .attr d: (d)->
            seriesPath d.points

    api = (selection) ->
      selection.classed
        fresnel: true
        explanation: true

      INDEX_N1 = 1.0
      INDEX_N2 = 1.5
      INCIDENT_ANGLE_N1 = 60
      INCIDENT_ANGLE = 60

      api.explore = ->
        [mouseX, mouseY] = d3.mouse @
        INCIDENT_ANGLE = Math.min(
          domains.x[1]
          Math.max scales.x.invert(mouseX), domains.x[0]
        )
        api.update()

      api.update = ->
        serieses = (series: key, points: [] for key in solutionParts)

        angles.map (angle) ->
          data = Exp.laws.Fresnel angle, INCIDENT_ANGLE_N1, INDEX_N1, INDEX_N2
          serieses.map (series) ->
            series.points.push [
              angle
              data[series.series]
            ]

        scaleSolution = Exp.laws.Fresnel INCIDENT_ANGLE, INCIDENT_ANGLE_N1, INDEX_N1, INDEX_N2

        scaleSolutions = solutionParts.map (part)->
          [
            INCIDENT_ANGLE
            scaleSolution[part]
          ]

        solutions.selectAll ".solution.reference"
          .data scaleSolutions
          .call (solution) ->
            solution.enter()
              .append "g"
              .classed solution: true, reference: true
              .call (solution) ->
                solution.append "circle"
                  .attr r: 5
                  .style stroke: (d, i) -> scales.color i
          .attr transform: (d, i) ->
            "translate(#{scales.x d[0]}, #{scales.y d[1]} )"

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

        svg.attr width: WIDTH, height: HEIGHT


        plotsBg.attr width: WIDTH - padding.right, height: HEIGHT
        clip.attr
          width: WIDTH,
          height: scales.y.range()[0],
          x: 0

        el_xAxis.attr transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call axes.x

        el_yAxis.attr transform: "translate(#{ padding.left }, 0)"
          .call axes.y

        xLabel.attr
          transform: "translate(#{ [WIDTH/2, HEIGHT - 50] })"
        yLabel.attr
          transform: "translate(10, #{ HEIGHT/2 }) rotate(-90)"

        api.update()

      svg = selection.selectAll ".plot"
        .data [1]
        .call (svg) ->
          svg = svg.enter()
            .append "svg"
            .classed plot: true

          svg.append "defs"
            .append "clipPath"
              .classed "fresnel-path": true
              .attr id: "fresnelPath"
              .append "rect"

          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#fresnelPath)"
            .call (plots) ->
              plots.append "rect"
                .classed bg: true
                .on mousemove: api.explore

              plots.append "g"
                .classed solutions: true

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
              yLabel.append "tspan"
                .text "Reflection"

              yLabel.append "tspan"
                .classed unit: true
                .text " [Rs, Rp, Rtotal]"

      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".fresnel-path rect"
      el_xAxis = svg.select ".axis.x"
      el_yAxis = svg.select ".axis.y"
      xLabel = svg.select ".label.x text"
      yLabel = svg.select ".label.y text"

      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.fresnel": api.resize

      api.resize()

    return api

  return Fresnel
