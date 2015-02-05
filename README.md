# IR Primer
A visual explanation of the infrared spectrum

## Development
Install [NodeJS](http://nodejs.org). Install [bower](http://bower.io).

```bash
npm install .
bower install
```

Source files are written in whitespace-picky preprocessed languages, and are configured to run continuously, watching for changes in `src/` and output to `dist/`:
- `npm run jade` for HTML from [Jade](http://jade-lang.com)
- `npm run stylus` for CSS from [Stylus](http://learnboost.github.io/stylus/)
- `npm run coffee` for Javascript from [Coffeescript](http://coffeescript.org)

For your hacking convenience, all of these are wrapped together with a live-updating server:

```bash
npm run live
```

This will generate an `.html` file for each of the explanations, which has all self-contained dependencies.

## IPython/Jupyter Notebook integration
A small python wrapper around the built javascript/css allows all the explanations to be embedded inside an [IPython Notebook](http://ipython.org/notebook.html), generally one per cell.
```python
from irprimer import fresnel, planck, slides
fresnel()
...
planck()
```

Additionally provided is a function for generating a self-contained [Reveal.js](http://lab.hakim.se/reveal-js/) slideshow. Put this in another `skip` slide.
```python
slides()
```

## Contributing
Issues and pull requests welcome, especially for improvement of the science and teach-ability of the content!

## License
IR Primer is published under the [BSD 3-clause](./README.md) license. Bower dependencies are licensed respectively.
