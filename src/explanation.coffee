define [], ()->
    C =
      boltzman1: -> 3.74e8
      boltzman2: -> 1.44e4
      wien: -> 2898

    laws =
      Planck: (temperature, wavelength) ->
        C.boltzman1() / (
          (wavelength ** 5) * (
            Math.exp(C.boltzman2() / (wavelength * temperature)) - 1
          )
        )

      Wien: (temperature) ->
        C.wien() / temperature

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

    Explanation =
      laws: laws
      constants: C
      scientificNotation: scientificNotation
