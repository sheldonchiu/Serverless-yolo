FROM openfaas/classic-watchdog:0.18.1 as watchdog

FROM python

COPY --from=watchdog /fwatchdog /usr/bin/fwatchdog
RUN chmod +x /usr/bin/fwatchdog
# Add non root user
RUN useradd -ms /bin/bash app

WORKDIR /home/app/

COPY index.py           .
COPY requirements.txt   .

RUN chown -R app /home/app && \
  mkdir -p /home/app/python && chown -R app /home/app
USER app
ENV PATH=$PATH:/home/app/.local/bin:/home/app/python/bin/
ENV PYTHONPATH=$PYTHONPATH:/home/app/python

RUN pip install -r requirements.txt --target=/home/app/python

RUN mkdir -p function
RUN touch ./function/__init__.py

WORKDIR /home/app/

USER root

WORKDIR /home/app/darknet

RUN wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names \
  && wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg \
  && wget -q https://pjreddie.com/media/files/yolov3.weights

WORKDIR /home/app/

COPY function function

RUN chown -R app:app ./ && \
  chmod -R 777 /home/app/python

USER app

ENV fprocess="python3 index.py"
EXPOSE 8080

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1

CMD ["fwatchdog"]