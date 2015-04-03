require.config
  paths:
    underscore: "./bower_components/underscore/underscore"
    math: "./bower_components/mathjs/dist/math"
  shim:
    underscore: exports: "_"

define ["math", "underscore"], (math, _)->
  console.log _
  iferr = (result, fn) ->
    try
      result = fn()
    catch Err
    result

  C =
    boltzman1: -> 3.74e8
    boltzman2: -> 1.44e4
    wien: -> 2898
    zeroKelvin: -> -273.15
    hevs: -> 4.136e-015
    hjs: -> 6.63e-34
    cms: -> 3.00e+08
    g0: -> 9.80665
    M: -> 0.0289644
    R: -> 8.31432
    L: -> 0.0065
    Tropopause: -> 11000
    TK1: -> 288.15
    TK2: -> 216.65

  laws =
    Planck: (temperature, wavelength) ->
      C.boltzman1() / (
        (wavelength ** 5) * (
          Math.exp(C.boltzman2() / (wavelength * temperature)) - 1
        )
      )

    Wien: (temperature) ->
      C.wien() / temperature

    Celsius: (kelvin) ->
      math.unit kelvin, "K"
        .toNumber "degC"

    Fahrenheit: (kelvin) ->
      math.unit kelvin, "K"
        .toNumber "degF"

    Rankine: (kelvin) ->
      math.unit kelvin, "K"
        .toNumber "degR"

    Frequency: (wavelength) ->
      C.cms() / wavelength / 1e6

    Wavenumber: (wavelength) ->
      1e4 / wavelength

    EnergyEV: (wavelength) ->
      C.hevs() * C.cms() * 1e6 / wavelength

    EnergyJ: (wavelength) ->
      C.hjs() * C.cms() * 1e6 / wavelength

    Fresnel: _.memoize ((incident_angle, incident_angle_n1=60, index_n1=1, index_n2=1.5) ->
      W = {}

      brewster = W.brewster = math.unit math.atan(index_n2 / index_n1), "rad"
        .toNumber "deg"

      critical = W.critical = iferr 90,
        -> math.unit(math.asin(index_n2 / index_n1), "rad").toNumber "deg"

      incident_rad = math.unit(incident_angle, "deg").toNumber "rad"

      cos_incident = W.cos_incident = math.cos incident_rad
      sin_incident = W.sin_incident = math.sin incident_rad

      rs_numerator = W.rs_numerator = iferr 1, ->
        index_n1 * cos_incident - index_n2 * Math.sqrt(
          1 - (index_n1 / index_n2 * sin_incident) ** 2
        )
      rs_denominator = W.rs_denominator = iferr 1, ->
        index_n1 * cos_incident + index_n2 * Math.sqrt(
          1 - (index_n1 / index_n2 * sin_incident) ** 2
        )
      rs = W.rs = (rs_numerator / rs_denominator) ** 2

      rp_numerator = W.rp_numerator = iferr 1, ->
        Math.sqrt(
          1 - (index_n1 / index_n2 * sin_incident) ** 2
        ) - index_n2 * cos_incident
      rp_denominator = W.rp_denominator = iferr 1, ->
        Math.sqrt(
          1 - (index_n1 / index_n2 * sin_incident) ** 2
        ) + index_n2 * cos_incident
      rp = W.rp = (rp_numerator / rp_denominator) ** 2

      rtotal = W.rtotal = math.mean rs, rp

      W), (args...) -> args.join "\t"

    Density: (elevation) ->
      W = E: elevation

      if elevation < C.Tropopause()
        W.K = C.TK1() - C.L() * elevation
        W.rP = (W.K / (W.K + C.L() * elevation)) **
          (C.g0() * C.M() / C.R() / C.L())
      else
        W.K = C.TK2()
        W.rP = Math.exp -C.g0() * C.M() * elevation / C.R() / W.K

      W.rD = W.rP * W.K / C.TK1()
      W

  spectrumOffset = 0.0135
  spectrumColors = [
    '#020005', '#020006', '#030008', '#04000A', '#06000D', '#080110', '#0C0117',
    '#11021F', '#17032A', '#1F053A', '#25084B', '#290A5C', '#2B0E6F', '#291380',
    '#1F237B', '#132E74', '#09376C', '#0A3E66', '#0C4667', '#0E4F6A', '#10596C',
    '#11636D', '#146E6F', '#177970', '#178672', '#1A9574', '#1DA375', '#1DB273',
    '#20C070', '#22CB6B', '#21D662', '#23E054', '#36E842', '#50ED28', '#73EB22',
    '#8FE722', '#A5E221', '#B9DC22', '#CBD621', '#DCCE20', '#ECC420', '#F2B735',
    '#F5AB42', '#F69F49', '#F7944B', '#F98848', '#FA7B42', '#FB6C39', '#FD5B2E',
    '#FC471F', '#F7300F', '#EA220D', '#D42215', '#BF2318', '#A92309', '#981F07',
    '#871B06', '#771805', '#671504', '#591303', '#4D1103', '#420E02', '#370C01',
    '#2E0A01', '#270801', '#210600', '#1E0400', '#1A0300', '#170200', '#130100',
    '#100100', '#0C0100', '#080100', '#060100', '#040100'
  ]

  defs =
    spectrum: (selection) ->
      selection.selectAll "#spectrumGradient"
        .data [1]
        .enter().append "linearGradient"
          .attr id: "spectrumGradient"
          .selectAll "stop"
          .data (i for i in [380..750] by 5)
          .enter()
          .append "stop"
          .attr
            offset: (d, i) -> spectrumOffset * i
          .style
            "stop-color": (d, i) -> spectrumColors[i]
            "stop-opacity": (d, i) ->
              if d < 500
                i / 20
              else if d > 650
                (750 - d) / 100
              else
                1


  scientificNotation = (d) ->
    return unless d
    parseFloat(d).toExponential 1
      .replace /^(.*)e([+-])(\d*)$/,
        (match, mag, sign, exp)->
          mag = if mag == "1.0" then "" else mag.replace(/\.0$/, "") + "×"
          sign = if sign == "-" then "⁻" else ""

          exp = exp.split ""
            .map (e) -> "⁰¹²³⁴⁵⁶⁷⁸⁹"[+e]
            .join ""
          mag + "10" + sign + exp

  drawIrBands = (parent) ->
    parent.selectAll "g.ir-band"
      .data [
        {band: [3, 5], name: "Midwave IR"}
        {band: [8, 12], name: "Longwave IR"}
      ]
      .enter()
      .append "g"
      .classed "ir-band": true
      .call (band) ->
        band.append "rect"
        band.append "text"
          .text ({name}) -> name
          .attr
            dy: "1em"
            "text-anchor": "end"

  # the public API
  Explanation =
    laws: laws
    constants: C
    scientificNotation: scientificNotation
    math: math
    defs: defs
    drawIrBands: drawIrBands
