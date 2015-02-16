import os
from random import random
import time

from subprocess import Popen, PIPE
from IPython.display import Javascript, HTML, display_html

replacements = {
    "//netdna.bootstrapcdn.com/font-awesome/4.1.0/":
        "./bower_components/Font-Awesome/",
    "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/":
        "./bower_components/jquery/dist/",
    "https://cdn.mathjax.org/mathjax/latest/":
        "./bower_components/MathJax/",
    "https://cdnjs.cloudflare.com/ajax/libs/require.js/2.1.10/require.min.js":
        "./bower_components/requirejs/require.js",
    "./dist/": "./",
    '<link rel="stylesheet" href="custom.css">': ""
}


def slides(infile="An IR Primer.ipynb",
           outfile="dist/An IR Primer.slides.local.html"):
    Javascript("IPython.notebook.save_notebook()")

    time.sleep(1)

    html, err = Popen([
        "ipython", "nbconvert",
        infile,
        "--to=slides",
        "--reveal-prefix=./bower_components/reveal.js",
        "--stdout"
    ], stdout=PIPE).communicate()

    html = html.decode("utf-8")

    for remote, local in replacements.items():
        html = html.replace(remote, local)

    if os.path.exists(outfile):
        os.unlink(outfile)

    with open(outfile, "w+") as f:
        f.write(html)


class Explanation(object):
    def __init__(self, id=None):
        self.id = id or str(random()).split(".")[1]

    def display(self):
        display_html(self)

    def _repr_html_(self):
        return """
            <style>@import url("./dist/%(name)s.css");</style>
            <div id="%(name)s-%(id)s"></div>
            <script>
                require(
                    [
                        "./dist/%(name)s.js",
                        "./dist/ipython-explanation.js",
                        "./dist/bower_components/d3/d3.min.js",
                        "jquery"
                    ],
                    function(Explanation, Loader, d3, $){{
                        Loader("%(name)s-%(id)s", Explanation, d3, $);
                    }}
                );
            </script>
        """ % {
            "id": self.id,
            "name": self.name
        }


class Planck(Explanation):
    name = "planck"


class Temperatures(Explanation):
    name = "temperatures"


class Density(Explanation):
    name = "density"


class Fresnel(Explanation):
    name = "fresnel"


class Wavelengths(Explanation):
    name = "wavelengths"
