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
              .classed "density-path": true
              .attr id: "densityPath"
              .append "rect"

          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#densityPath)"
            .call (plots) ->
              plots.append "rect"
                .classed bg: true
                .on mousemove: api.explore

              plots.append "g"
                .classed solutions: true

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

              xLabel.append "tspan"
                .classed unit: true
                .text " [km]"

          svg.append "g"
            .classed label: true, y: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Temperature "
              yLabel.append "tspan"
                .classed unit: true
                .text "[K]"

      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".density-path rect"
      el_xAxis = svg.select ".axis.x"
      el_y0Axis = svg.select ".axis.y0"
      el_y1Axis = svg.select ".axis.y1"
      xLabel = svg.select ".label.x text"
      yLabel = svg.select ".label.y text"

      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.density": api.resize

      api.resize()

    return api

  return Density
