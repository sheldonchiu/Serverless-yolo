FROM openfaas/classic-watchdog:0.18.0 as watchdog

FROM sheldonchiu/yolo:latest

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog

# Add non root user
# RUN useradd -ms /bin/bash app
# RUN chown app /home/app

# WORKDIR /home/app

# USER app

# Populate example here - i.e. "cat", "sha512sum" or "node index.js"
ENV fprocess="bash"
# Set to true to see request in function logs
ENV write_debug="true"

EXPOSE 8080

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]
