
# 8.1 build image from docker file

## docker image build subcommand
## --no-cache flag to disable the use of cache

## VOLUME instruction in building time is more limiting
## no way to specify bind-mount or read-only volume
## VOLUME does two thing - create defined location in image fs; add volume definition to iamge metadata

## ADD instruction
## fetch remote resource files if URL is specified
## extract the contents of any source if it is determied to be an archive file.

# 8.3 Injecting downstream build-time behavior

## ONBUILD instruction defines other instructions to execute if the resulting image is used as base for another build.


# 8.4 Creating maintainable dockerfiles

## ARG instruction and --build-arg options
## provide build arguments with one or more --build-arg options in docker image build
## use ARG instrctuion to fetch them in build time.
version=0.6; docker image build -t dockerinaction/mailer-base:${version} \
    -f mailer-base.dockerfile \
    --build-arg VERSION=${version} \
    .

## check the versioin in meta data
docker image inspect --format "{{json .Config.Labels}}" dockerinaction/mailer-base:0.6
