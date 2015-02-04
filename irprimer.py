import os
from random import random
import time

from subprocess import Popen
from IPython.display import Javascript, HTML

replacements = {
    "//netdna.bootstrapcdn.com/font-awesome/4.1.0/":
        "./bower_components/Font-Awesome/",
    "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/":
        "./bower_components/jquery/dist/",
    "https://cdn.mathjax.org/mathjax/latest/":
        "./bower_components/MathJax/",
    "https://cdnjs.cloudflare.com/ajax/libs/require.js/2.1.10/require.min.js":
        "./bower_components/requirejs/require.js"
}


def slides(infile="An IR Primer.ipynb",
           tmpfile="An IR Primer.slides.html",
           outfile="An IR Primer.slides.local.html"):
    Javascript("IPython.notebook.save_notebook()")

    time.sleep(1)

    Popen([
        "ipython", "nbconvert",
        infile,
        "--to=slides",
        "--reveal-prefix=./bower_components/reveal.js"
    ])

    time.sleep(1)

    with open(tmpfile, "r") as f:
        html = f.read()

    for remote, local in replacements.items():
        html = html.replace(remote, local)

    os.unlink(outfile)
    with open(outfile, "w+") as f:
        f.write(html)


def planck():
    return HTML("""
        <style>
            @import url("planck.css");
            #planck-{id}{{
                background-color: white;

            }}
            .reveal #planck-{id} {{
                margin-top: -200px;
                margin-left: -300px;
            }}
        </style>
        <div id="planck-{id}" class="stretch"></div>
        <script>
            require(["./bower_components/d3/d3.min.js", "./planck.js"],
                function(d3, Planck){{
                    var planck = Planck(d3);
                    d3.select("#planck-{id}")
                        .style({{
                            "background-color": "white",
                            width: window.innerWidth * 0.9 + "px",
                            height: window.innerHeight * 0.9 + "px",
                        }})
                        .call(planck)
                }});
        </script>

    """.format(id=str(random()).split(".")[1])
    )
