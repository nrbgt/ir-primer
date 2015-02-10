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
    x: [0, 12]
    y: [
      [0, 1.6e4]
      [0.1, 10]
      [1e-20, 1e-18]
    ]

  expwn = Exp.scientificNotation


  Wavelengths = (_d3)->
    d3 = _d3

    scales =
      x: d3.scale.linear().domain domains.x
      y: [
        d3.scale.linear().domain domains.y[0]
        d3.scale.log().domain domains.y[1]
        d3.scale.log().domain domains.y[2]
      ]

    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y: [
        d3.svg.axis().scale(scales.y[0]).orient 'left'
        d3.svg.axis().scale(scales.y[1]).orient 'left'
        d3.svg.axis().scale(scales.y[2]).orient 'right'
      ]

    seriesPath = (y)->
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
          .attr d: (d)->
            fn = seriesPath scales.y[d.scaleIdx]
            fn d.points

    dispatch = d3.dispatch "update"

    api = (selection) ->
      selection.classed
        explanation: true
        wavelengths: true

      WAVELENGTH = 0

      api.explore = ->
        [mouseX, mouseY] = d3.mouse @
        WAVELENGTH = Math.min(
          domains.x[1]
          Math.max scales.x.invert(mouseX), domains.x[0]
        )
        api.update()

      api.update = ->
      api.resize = ->
        # do things based on window resize
        WIDTH = selection.node().clientWidth
        HEIGHT = selection.node().clientHeight

        scales.x.range [padding.left, WIDTH - padding.right]
        scales.y[0].range [HEIGHT / 2, padding.top]
        scales.y[1].range [HEIGHT / 2, padding.top]
        scales.y[2].range [HEIGHT / 2, padding.top]

        svg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr width: WIDTH - padding.right, height: HEIGHT

        # TODO: need two of these
        clip.attr
          width: WIDTH,
          height: scales.y[0].range()[0],
          x: 0

        el_xAxis.attr transform: "translate(0, #{ HEIGHT / 2 })"
          .call axes.x

        el_y0Axis.attr transform: "translate(#{ padding.left }, 0)"
          .call axes.y[0]

        el_y1Axis.attr transform: "translate(#{ padding.left }, #{ HEIGHT / 2})"
          .call axes.y[1]
          .selectAll "text"
          .text ->
            parseFloat this.textContent unless not this.textContent


        el_y2Axis.attr transform: "translate(#{ WIDTH - padding.right }, #{ HEIGHT / 2})"
          .call axes.y[2]
          .text -> expwn this.textContent


        xLabel.attr
          transform: "translate(#{ [ WIDTH / 2, HEIGHT / 2] })"
        y0Label.attr
          transform: "translate(10, #{ HEIGHT / 4 }) rotate(-90)"
        y1Label.attr
          transform: "translate(10, #{ HEIGHT * (3/4) }) rotate(-90)"
        y2Label.attr
          transform: "translate(#{ WIDTH - 10 }, #{ HEIGHT/3/4 }) rotate(90)"


        api.update()

      svg = selection.selectAll ".plot"
        .data [1]
        .call (svg) ->
          svg = svg.enter()
            .append "svg"
            .classed plot: true

          svg.append "defs"
            .append "clipPath"
              .classed "wavelengths-path": true
              .attr id: "wavelengthsPath"
              .append "rect"

          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#wavelengthsPath)"
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
            .classed axis: true, y2: true

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

          svg.append "g"
            .classed label: true, y0: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Wavenumber"

              yLabel.append "tspan"
                .classed unit: true
                .text " [cm⁻¹]"


          svg.append "g"
            .classed label: true, y1: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Energy "

              yLabel.append "tspan"
                .classed unit: true
                .text " [eV]"

          svg.append "g"
            .classed label: true, y2: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Energy "

              yLabel.append "tspan"
                .classed unit: true
                .text " [J]"

      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".wavelengths-path rect"
      el_xAxis = svg.select ".axis.x"
      el_y0Axis = svg.select ".axis.y0"
      el_y1Axis = svg.select ".axis.y1"
      el_y2Axis = svg.select ".axis.y2"
      xLabel = svg.select ".label.x text"
      y0Label = svg.select ".label.y0 text"
      y1Label = svg.select ".label.y1 text"
      y2Label = svg.select ".label.y2 text"

      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.temperatures": api.resize

      api.resize()

    api.dispatch = dispatch

    return api

  return Wavelengths
