FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /source

# Copy everything
COPY . .

# Restore & publish
RUN dotnet restore "./NayifatAPI/NayifatAPI.csproj"
RUN dotnet publish "./NayifatAPI/NayifatAPI.csproj" -c Release -o /app

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .

# Make port 80 available
ENV ASPNETCORE_URLS=http://+:80
EXPOSE 80

# Start the app
ENTRYPOINT ["dotnet", "NayifatAPI.dll"] 