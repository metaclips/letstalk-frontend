FROM node:latest

# make the ui folder the current working directory
WORKDIR /ui

# copy all files to directory
COPY . .

ENV PORT=8080
ENV VUE_APP_BACKEND_SERVER=https://143.244.167.147:8080

RUN npm install
# build app for production with minification
EXPOSE ${PORT}

CMD [ "npm", "run", "serve" ]