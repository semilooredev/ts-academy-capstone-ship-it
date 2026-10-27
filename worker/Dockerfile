# syntax=docker/dockerfile:1
# .NET does not support QEMU builds for this sample; retain the upstream
# platform notes and use exact SDK/runtime patch tags.
# hadolint ignore=DL3029
FROM --platform=${BUILDPLATFORM} mcr.microsoft.com/dotnet/sdk:7.0.410 AS build
ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM"

WORKDIR /source
COPY *.csproj .
RUN dotnet restore -a $TARGETARCH

COPY . .
RUN dotnet publish -c release -o /app -a $TARGETARCH --self-contained false --no-restore

FROM mcr.microsoft.com/dotnet/runtime:7.0.20 AS final
WORKDIR /app

RUN groupadd --gid 10002 worker && \
    useradd --uid 10002 --gid worker --no-create-home --shell /usr/sbin/nologin worker

COPY --from=build --chown=worker:worker /app .

USER worker
ENTRYPOINT ["dotnet", "Worker.dll"]
