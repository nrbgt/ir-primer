# specify base docker image
FROM dockerfile/nodejs

# npm install all the things
ADD ["README.md", "package.json", "/srv/ir-primer/"]

WORKDIR /srv/ir-primer
RUN npm install

# npm install all the things
ADD ["bower.json", ".bowerrc", "/srv/ir-primer/"]

VOLUME /srv/ir-primer/src
VOLUME /srv/ir-primer/dist
VOLUME /srv/ir-primer/bin

EXPOSE 8080

# the command that gets run inside the docker container
CMD ["./node_modules/.bin/coffee"]
