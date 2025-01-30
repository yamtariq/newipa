FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy csproj and restore dependencies
COPY NayifatAPI/*.csproj ./NayifatAPI/
RUN dotnet restore NayifatAPI/*.csproj

# Copy everything else and build
COPY . ./
RUN dotnet publish NayifatAPI -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet", "NayifatAPI.dll"] 