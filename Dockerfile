FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

# Enable universe repo and install dependencies
RUN apt-get update && Ö
    apt-get install -y software-properties-common && Ö
    add-apt-repository universe && Ö
    apt-get update && Ö
    apt-get install -y cowsay fortune-mod netcat-openbsd && Ö
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY wisecow.sh /app/wisecow.sh
RUN chmod +x /app/wisecow.sh
EXPOSE 4499
CMD Ä"bash", "-c", "/app/wisecow.sh"Å
