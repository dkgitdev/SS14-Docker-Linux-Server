# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build

# Update and install necessary tools
RUN apt-get -y update && \
    apt-get -y install curl unzip wget git jq

# Download and extract SS14 server (latest version compatible with .NET 9)
# Using manifest to get current server build

#YEAH, but no htmlq in apt :(
#RUN SERVER_URL="https://wizards.cdn.spacestation14.com"$(curl 'https://wizards.cdn.spacestation14.com/fork/wizards' \
#        --compressed \
#        -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0' \
#        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
#        -H 'Accept-Language: ru,en-GB;q=0.9,en-US;q=0.8,en;q=0.7' \
#        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
#        -H 'Referer: https://docs.spacestation14.com/' | htmlq --attribute href 'main > div:first-of-type ul li:nth-of-type(2) a') && \
RUN SERVER_URL="https://wizards.cdn.spacestation14.com/fork/wizards/version/e9974ed8a4ffc2d01dc565a319487ba81cd7614a/file/SS14.Server_linux-x64.zip" && \
    echo "Downloading server from: $SERVER_URL" && \
    curl "$SERVER_URL" \
        --compressed \
        -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
        -H 'Accept-Language: ru,en-GB;q=0.9,en-US;q=0.8,en;q=0.7' \
        -H 'Accept-Encoding: gzip, deflate, br, zstd' \
        -H 'Referer: https://docs.spacestation14.com/' \
        -o SS14.Server_linux-x64.zip && \
    unzip SS14.Server_linux-x64.zip -d /ss14-default/

# Download and build Watchdog
RUN wget https://github.com/space-wizards/SS14.Watchdog/archive/refs/heads/master.zip -O Watchdog.zip && \
    unzip Watchdog.zip -d Watchdog && \
    cd Watchdog/SS14* && \
    dotnet publish -c Release -r linux-x64 --no-self-contained && \
    cp -r SS14.Watchdog/bin/Release/net9.0/linux-x64/publish /ss14-default

# Server stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS server

# Copy from the build stage
COPY --from=build /ss14-default /ss14-default

# Install necessary tools
RUN apt-get -y update && apt-get -y install unzip

# Expose necessary ports
EXPOSE 1212/tcp
EXPOSE 1212/udp
EXPOSE 8080/tcp

# Set volume
VOLUME [ "/ss14" ]

# Add configurations
ADD appsettings.yml /ss14-default/publish/appsettings.yml
ADD server_config.toml /ss14-default/publish/server_config.toml

COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set the entry point for the container
ENTRYPOINT ["/start.sh"]
