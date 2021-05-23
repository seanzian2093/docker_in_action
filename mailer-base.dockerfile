FROM debian:buster-20190910
ARG VERSION=unknown
LABEL maintainer="seanzian@outlook.com"
RUN groupadd -r -g 2200 example && \
    useradd -rM -g 2200 example
ENV APPROOT="/app" \
    APP="mailer.sh" \
    VERSION="${VERSION}"
LABEL base.name="Mailer Archetype" \
    base.version="${VERSION}"
WORKDIR ${APPROOT}
ADD . ${APPROOT}
ENTRYPOINT ["/app/mailer.sh"]
EXPOSE 33333