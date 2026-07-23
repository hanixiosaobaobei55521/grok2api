FROM nginx:1.27-alpine
RUN printf "ok\n" > /usr/share/nginx/html/healthz && \
    printf "ok\n" > /usr/share/nginx/html/index.html && \
    sed -i "s/listen       80;/listen       8080;/" /etc/nginx/conf.d/default.conf
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
