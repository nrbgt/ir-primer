define [], ()->
  loader = (id, Explanation, d3, $)->
    explanation = Explanation d3

    wrapper = d3.select "##{ id }"
      .style
        width: "100%"
        height: "1080px"
      .call explanation

    if window.Reveal
      section = d3.select($ wrapper.node()
        .parents "section"
        .first()[0])

      section.selectAll ".input, .prompt"
        .remove()

      resize = ->
        """
        wrapper.style
          width: "#{ window.innerWidth - 50}px"
          height: "#{ window.innerHeight - 50}px"

        section.style
          width: "#{ window.innerWidth }px"
          height: "#{ window.innerHeight }px"
          top: "-#{ window.innerHeight / 2}px"
          left: "-#{ window.innerWidth / 6}px"
        """
        explanation.resize()

      _window = d3.select window
        .on 'resize.#{ id }', resize

      Reveal.addEventListener 'slidechanged', ->
        resize()
