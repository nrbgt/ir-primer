define [], ->
  d3 = null

  Fresnel = (_d3)->
    d3 = _d3

    api = (selection) ->
      selection.classed fresnel: true, explanation: true

    return api

  return Fresnel
