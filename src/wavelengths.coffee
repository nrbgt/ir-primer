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

  converters = [Exp.laws.Celsius, Exp.laws.Fahrenheit, Exp.laws.Rankine]

  references = converters.map (convert, i) ->
    scaleIdx: i
    points: domains.x.map (k)-> [k, convert k]

  Wavelengths = (_d3)->
    api = ->

    return api

  return Wavelengths
