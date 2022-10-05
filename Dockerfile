# syntax=docker/dockerfile:1.0.0-experimental

# our intermediate container that will be dumped, just need the node_modules installed
FROM node:16.16-alpine3.15 as intermediate

# install libs needed for other installations/setup
# python3 make g++ required for NR metric lib
RUN apk add git openssh-client npm python3 make g++

# add ssh key from outer env so we can install our onerail libs
RUN mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

# this is our work dir inside the container
WORKDIR /usr/src/app

# copy only the package.json and package-lock.json files
COPY package*.json ./

# patch-package: In your Dockerfile, remember to copy over the patch files before running... npm i
COPY patches ./patches

# copy tsconfig* files so we can ts build
COPY tsconfig*.json ./

# copy the src TS file for building
COPY src ./src

# install the libs specified in the package-lock file for dependencies and devDependencies (the @types/), and exact versions
# build the typescript
# and remove the devDependencies which are not needed anymore
RUN --mount=type=ssh npm i --production=false --unsafe-perm --save-exact --fund=false --audit=false && \
    npm run build && \
    npm prune --production

# our actual lean container
FROM node:16.16-alpine3.15

# create same work dir
WORKDIR /usr/src/app

# copy over all files that are not excluded in .dockerignore over to container
COPY . .

# from the other container copy the node_modules (which are excluded in .dockeringore)
COPY --from=intermediate /usr/src/app/node_modules ./node_modules

# copy the built JS files
COPY --from=intermediate /usr/src/app/dist ./dist

# these are not needed in the copy but can't be excluded in .dockerignore
RUN rm -rf src/ && rm tsconfig*.json && rm package-lock.json

# get the azure env we are running so startup works correctly/can fetch from correct key vault
#NODE_ENV should always be production in container, and if the value is passed it should be that too, unless testing
ARG NODE_ENV=production
#required param
ARG ENV_NAME
ARG NEW_RELIC_LICENSE_KEY
ENV NODE_ENV=${NODE_ENV} ENV_NAME=${ENV_NAME} NEW_RELIC_LICENSE_KEY=${NEW_RELIC_LICENSE_KEY}

# port to listen on in the container
EXPOSE 8000

# Start our app
CMD npm run start
