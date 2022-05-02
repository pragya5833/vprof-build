FROM node:15.14-alpine
# USER node 
# RUN mkdir -p /home/node/app && chown -R node:node /home/node/app
WORKDIR /home/node/app 
COPY . .
RUN npm install -g
EXPOSE 4005
CMD ["npm","start"]