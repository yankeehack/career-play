FROM node:6.11-alpine

# Create a virtualenv for the application dependencies.
# # If you want to use Python 3, add the -p python3.4 flag.
RUN npm install serve -g
RUN npm install && npm build
ADD . /app

CMD ["/app/run"]