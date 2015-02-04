# IR Primer
A visual explanation of the infrared spectrum

## Development
Install [NodeJS](http://nodejs.org). Install [bower](http://bower.io).

```bash
npm install .
bower install
```

Source files are written in whitespace-picky preprocessed languages, and are configured to run continuously, watching for changes in `src/` and output to `dist/`:
- `npm run jade` for HTML from [Jade](http://jadelang.org)
- `npm run stylus` for CSS from [Stylus](http://stylus.org)
- `npm run coffee` for Javascript from [Coffeescript](http:/coffeescript)

For your hacking convenience, all of these are wrapped together with a live-updating server:

```bash
npm run live
```

This will generate an `.html` file for each of the explanations, which has all self-contained dependencies.

## IPython Notebook integration
A light wrapper around the javascript allows all the explanation to be embedded inside an IPython Notebook. A few small added files allow for building a standalone [Reveal.js](http://revealjs.org) slideshow.

```python
import irprimer
irprimer.planck()
irprimer.slides()
```
