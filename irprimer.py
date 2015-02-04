import os
from random import random
import time

from subprocess import Popen, PIPE
from IPython.display import Javascript, HTML

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


def planck():
    return HTML("""
        <style>
            @import url("./dist/planck.css");
            #planck-%(id)s{
                background-color: white;
            }
        </style>
        <div id="planck-%(id)s" class="stretch"></div>
        <script>
            require(
                [
                    "./dist/bower_components/d3/d3.min.js",
                    "./dist/planck.js"
                ],
                function(d3, Planck){
                    var planck = Planck(d3);
                    var wrapper = d3.select("#planck-%(id)s")
                        .style({
                            "background-color": "white",
                            width: "100%%",
                            height: "800px",
                        })
                        .call(planck);
                    if(window.Reveal){
                        var _window = d3.select(window);
                        Reveal.addEventListener(
                            "slidechanged",
                            function(event){
                                $(window).resize();
                            }
                        );
                        .on("resize.planck-%(id)s", function(){
                            wrapper.style({
                                width: window.innerWidth + "px",
                                height: window.innerHeight + "px"
                            })
                            planck.resize();
                        });
                    }
            });
        </script>
        """ % dict(id=str(random()).split(".")[1]))
