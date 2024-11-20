FROM node:alpine3.20
# The source file-path assumes that we are running docker build
# from the app/ (parent) directory.
COPY .. /usr/local/app
WORKDIR /usr/local/app
RUN npm install
EXPOSE 3000
CMD [ "npm", "run", "start" ]
