define ["./explanation.js"], (Exp)->
  d3 = null

  # magic numbers
  padding =
    top: 40
    left: 120
    right: 120
    bottom: 90
    middle: 20
  sliderPadding =
    top: 80
    left: 10
    right: 10
    bottom: 110
    temperature: 40
    solution: 140

  domains =
    x: [0.1, 100]
    y: [
      [0, 1e5]
      [0, 3000]
      [0.01, 13]
      [1e-21, 1e-17]
    ]

  labels = [
    "Wavenumber"
    "Frequency [THz]"
    "Energy [EV]"
    "Energy [J]"
  ]

  converters = [
    Exp.laws.Wavenumber
    Exp.laws.Frequency
    Exp.laws.EnergyEV
    Exp.laws.EnergyJ
  ]

  expwn = Exp.scientificNotation


  Wavelengths = (_d3)->
    d3 = _d3

    scales =
      x: d3.scale.log().domain domains.x
      y: [
        d3.scale.linear().domain domains.y[0]
        d3.scale.linear().domain domains.y[1]
        d3.scale.log().domain domains.y[2]
        d3.scale.log().domain domains.y[3]
      ]
      color: d3.scale.ordinal().range ["green", "purple", "red", "blue"]


    axes =
      x: d3.svg.axis().scale(scales.x).orient 'bottom'
      y: [
        d3.svg.axis().scale(scales.y[0]).orient 'left'
        d3.svg.axis().scale(scales.y[1]).orient 'right'
        d3.svg.axis().scale(scales.y[2]).orient 'left'
        d3.svg.axis().scale(scales.y[3]).orient 'right'
      ]

    seriesPath = (y)->
      d3.svg.line()
        .x (d) -> scales.x d[0]
        .y (d) -> y d[1]

    wavelengths = (i for i in [0.1..1.99] by 0.01)
      .concat (i for i in [2..19.5] by 0.5)
      .concat (i for i in [20..100] by 1)

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


    makeSeries = (fn, i)->
      scaleIdx: i
      points: wavelengths.map (wavelength)->[
        wavelength
        fn wavelength
      ]

    colorizeLegend = (d, i) ->
      if i then scales.color i - 1  else "black"

    dispatch = d3.dispatch "update"

    api = (selection) ->
      selection.classed
        explanation: true
        wavelengths: true

      WAVELENGTH = 0

      references = converters.map makeSeries

      api.explore = ->
        [mouseX, mouseY] = d3.mouse @
        WAVELENGTH = Math.min(
          domains.x[1]
          Math.max scales.x.invert(mouseX), domains.x[0]
        )
        api.update()

      api.update = ->
        scaleSolutions = converters.map (convert)->
          [
            WAVELENGTH
            convert WAVELENGTH
          ]

        plots.selectAll ".solution.interactive"
          .data scaleSolutions
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
                x2: (d, i) -> if i % 2 then -20 else 20
                y2: 0
                "marker-start": (d, i) -> "url(#end-arrow-#{scales.color i})"

            solutionLabel.attr
              transform: (d, i) ->
                y = scales.y[i] d[1]

                y = if Number.isNaN y then 0 else y

                if i % 2 == 0
                  "translate(#{padding.left}, #{y})"
                else
                  "translate(#{scales.x.range()[1]}, #{y})"


          .select "text"
            .text (d, i) -> if i == 3 then expwn d[1] else "#{d[1].toFixed 2}"

        plots.selectAll ".scanline path"
          .data [
            [
              [scales.x(WAVELENGTH), scales.y[0].range()[0]]
              [scales.x(WAVELENGTH), scales.y[0].range()[1]]
            ],
            [
              [scales.x(WAVELENGTH), scales.y[2].range()[0]]
              [scales.x(WAVELENGTH), scales.y[2].range()[1]]
            ]
          ]
          .attr
            d: d3.svg.line()

        solutions
          .selectAll ".solution.legend"
          .data [[WAVELENGTH, WAVELENGTH]].concat scaleSolutions
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
              .text (d, i) -> ["Wavelength"].concat(labels)[i]
              .style fill: colorizeLegend

            solution.select ".value"
              .text (d, i) -> d[1].toFixed 2
              .style fill: colorizeLegend

      api.resize = ->
        # do things based on window resize
        WIDTH = selection.node().clientWidth
        HEIGHT = selection.node().clientHeight
        MID = HEIGHT / 2

        scales.x.range [padding.left, WIDTH - padding.right]

        scales.y[0].range [MID, padding.top]
        scales.y[1].range [MID, padding.top]

        scales.y[2].range [HEIGHT - padding.bottom, MID + padding.middle]
        scales.y[3].range [HEIGHT - padding.bottom, MID + padding.middle]

        svg.attr width: WIDTH, height: HEIGHT

        plotsBg.attr width: WIDTH - padding.right, height: HEIGHT

        solutions.attr
          transform: "translate(#{ WIDTH - 2.5 * padding.left }, #{ 2 * padding.top})"

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
          width: WIDTH,
          height: HEIGHT - padding.top - padding.bottom,
          x: 0
          y: padding.top

        el_xAxis.attr
            transform: "translate(0, #{ HEIGHT - padding.bottom })"
          .call axes.x
          .selectAll "text"
          .text ->
            parseFloat @textContent unless not @textContent



        el_y0Axis.attr
            transform: "translate(#{ padding.left }, 0)"
          .call axes.y[0]

        el_y1Axis.attr
            transform: "translate(#{ WIDTH - padding.right }, 0)"
          .call axes.y[1]

        el_y2Axis.attr
            transform: "translate(#{ padding.left }, 0)"
          .call axes.y[2]

        el_y3Axis.attr
            transform: "translate(#{ WIDTH - padding.right }, 0)"
        .call axes.y[3]
        .selectAll "text"
          .text ->
            if @textContent[0] == "1"
              @textContent
            else
              ""


        xLabel.attr
          transform: "translate(#{ [ WIDTH / 2, HEIGHT - 30] })"

        y0Label.attr
          transform: "translate(10, #{ HEIGHT / 4 }) rotate(-90)"
        y1Label.attr
          transform: "translate(#{ WIDTH - 10 }, #{ HEIGHT / 4 }) rotate(90)"

        y2Label.attr
          transform: "translate(10, #{ HEIGHT * (3/4) }) rotate(-90)"
        y3Label.attr
          transform: "translate(#{ WIDTH - 10 }, #{ HEIGHT * (3/4) }) rotate(90)"


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

          defs = svg.append "defs"

          defs.call Exp.defs.spectrum

          defs.append "clipPath"
            .classed "wavelengths-path": true
            .attr id: "wavelengthsPath"
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

          svg.append "g"
            .classed plots: true
            .attr "clip-path": "url(#wavelengthsPath)"
            .call (plots) ->
              plots
                .append "g"
                .classed spectrum: true
                .call (spectrum) ->
                  spectrum.append "rect"
                    .style fill: "url(#spectrumGradient)"
                  spectrum.append "text"
                    .text "Visible Light"
                    .attr
                      dy: "1em"
                      "text-anchor": "end"

              plots.call Exp.drawIrBands

              plots.append "rect"
                .classed bg: true
                .on mousemove: api.explore

              plots.append "g"
                .classed solutions: true

              for i in [0, 1]
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
            .classed axis: true, y2: true

          svg.append "g"
            .classed axis: true, y3: true

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

          svg.append "g"
            .classed label: true, y0: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Wavenumber"
                .classed "fill-wavenumber": true

              yLabel.append "tspan"
                .classed unit: true
                .text " [cm⁻¹]"

          svg.append "g"
            .classed label: true, y1: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Frequency "
                .classed "fill-frequency": true

              yLabel.append "tspan"
                .classed unit: true
                .text " [THz]"

          svg.append "g"
            .classed label: true, y2: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Energy "
                .classed "fill-energy-ev": true

              yLabel.append "tspan"
                .classed unit: true
                .text " [eV]"

          svg.append "g"
            .classed label: true, y3: true
            .append "text"
            .attr "text-anchor": "middle", dy: ".71em"
            .call (yLabel) ->
              yLabel.append "tspan"
                .text "Energy "
                .classed "fill-energy-j": true


              yLabel.append "tspan"
                .classed unit: true
                .text " [J]"

          svg.append "g"
            .classed wavelength: true, interactive: true
            .attr "text-anchor": "middle"
            .append "text"

      plots = svg.select ".plots"
      solutions = plots.select ".solutions"
      plotsBg = plots.select ".bg"
      defs = svg.select "defs"
      clip = defs.select ".wavelengths-path rect"
      el_xAxis = svg.select ".axis.x"
      el_y0Axis = svg.select ".axis.y0"
      el_y1Axis = svg.select ".axis.y1"
      el_y2Axis = svg.select ".axis.y2"
      el_y3Axis = svg.select ".axis.y3"
      xLabel = svg.select ".label.x text"
      y0Label = svg.select ".label.y0 text"
      y1Label = svg.select ".label.y1 text"
      y2Label = svg.select ".label.y2 text"
      y3Label = svg.select ".label.y3 text"
      spectrum = svg.selectAll ".spectrum"
      irBand = svg.selectAll ".ir-band"


      # listen for window resize
      # it is still the job of the owner of `selection` to update)
      d3.select window
        .on "resize.temperatures": api.resize

      api.resize()

    api.dispatch = dispatch

    return api

  return Wavelengths
