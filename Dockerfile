FROM node:lts-alpine
RUN apk add --no-cache git
WORKDIR /app
RUN git clone --depth 1 --branch release https://github.com/SillyTavern/SillyTavern.git .
RUN npm install --no-audit --no-fund --omit=dev
RUN node docker/build-lib.js
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh
ENV NODE_ENV=production
CMD ["/app/start.sh"]
