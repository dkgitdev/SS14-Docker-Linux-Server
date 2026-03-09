# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ENV DOTNET_NUGET_SIGNATURE_VERIFICATION=false

# Update and install necessary tools
RUN apt-get -y update && \
    apt-get -y install curl unzip wget git

# Download and build Watchdog
RUN git clone --recursive https://github.com/space-wizards/SS14.Watchdog
RUN cd SS14.Watchdog && dotnet publish -v d -c Release -r linux-x64 --no-self-contained
RUN cp -r SS14.Watchdog/SS14.Watchdog/bin/Release/net10.0/linux-x64/publish /ss14-default

# Server stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS server
ENV DOTNET_NUGET_SIGNATURE_VERIFICATION=false
# Install necessary tools
RUN apt-get -y update && \
    apt-get -y install unzip

COPY ./files/SS14.Server_linux-x64.zip ./SS14.Server_linux-x64.zip
RUN unzip SS14.Server_linux-x64.zip -d /ss14-default/

# Copy from the build stage
COPY --from=build /ss14-default /ss14-default

# Expose necessary ports
EXPOSE 1212/tcp
EXPOSE 1212/udp
EXPOSE 8080/tcp

# Set volume
VOLUME [ "/ss14" ]

# Add configurations
ADD appsettings.yml /ss14-default/appsettings.yml
ADD server_config.toml /ss14-default/server_config.toml

COPY start.sh /ss14-default/start.sh
RUN chmod +x /ss14-default/start.sh
WORKDIR /ss14-default/
# Set the entry point for the container
ENTRYPOINT ["sh", "start.sh"]
