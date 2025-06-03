FROM python:3.10
LABEL maintainer="jorgepezuela"

RUN mkdir /app
ADD agentclean.py /app/main.py
ADD requirements.txt requirements.txt

RUN pip install -r requirements.txt && chmod +x /app/main.py && useradd -u 1001 none
USER none

WORKDIR /app

ENTRYPOINT ["python", "main.py"]
