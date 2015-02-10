define [], ->
  d3 = null

  Refraction = (_d3)->
    d3 = _d3

    api = (selection) ->
      selection.classed refraction: true, explanation: true

    api.update = ->
      # do things based on user interaction
      api

    api.resize = (event) ->
      # do things based on window resize
      api.update()

    # listen for window resize
    # it is still the job of the owner of `selection` to update)
    d3.select window
      .on "resize.refraction": api.resize

    return api

  return Fresnel
