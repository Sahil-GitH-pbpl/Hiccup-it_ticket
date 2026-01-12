FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV TZ=Asia/Kolkata

WORKDIR /app

COPY requirements /app/requirements
RUN pip install --no-cache-dir -r requirements

COPY . /app
RUN mkdir -p /app/logs /app/uploads

EXPOSE 7410

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7410", "--workers", "3"]
