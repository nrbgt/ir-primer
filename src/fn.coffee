require.config
  paths:
    underscore: "./bower_components/underscore/underscore"
  shim:
    underscore:
      exports: "_"
define ["underscore"], (_) ->
  Fn = (d3, MathJax) ->
    _replacements = -> {}

    api = (selection) ->
      selection.each (d, i) ->
        d = d or {}
        d.template = d.template or _.template d3.select(@).text()

        jax = d3.select @
          .datum d
          .style visibility: "hidden"
          .text "$$ #{ d.template _replacements d } $$"

        MathJax.Hub.Queue [
          "Typeset"
          MathJax.Hub
          @
          ->
            preview = jax.select(".MathJax_Preview").node()
            if preview
              jax.style visibility: "visible"
        ]

    api.replacements = (val) ->
      _replacements unless not arguments.length
      _replacements = d3.functor val
      api

    return api

  return Fn
