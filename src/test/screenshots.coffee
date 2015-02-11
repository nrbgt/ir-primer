explanations = [
  "planck"
  "temperatures"
  "wavelengths"
  "fresnel"
  "refraction"
  "density"
  "An IR Primer.slides.local"
]

casper.start()
  .then ->
    @viewport 1080, 1080
    @each explanations, (self, explanation)->
      self.thenOpen "http://localhost:8080/#{ explanation }.html", ->
        @wait 4000, ->
          @capture "dist/screenshots/#{ explanation }.png"

casper.run()
