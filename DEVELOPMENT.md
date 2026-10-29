## Using development copy of mc-image-helper

In the cloned copy of [`mc-image-helper`](https://github.com/itzg/mc-image-helper), create an up-to-date snapshot build of the tgz distribution using:

```shell
./gradlew distTar
```

**NOTE** The distribution's version will be `0.0.0-<branch>-SNAPSHOT`

Assuming Java 18 or newer:

```shell
cd build/distributions
jwebserver -b 0.0.0.0 -p 8008
```

```shell
--build-arg MC_HELPER_VERSION=1.8.1-SNAPSHOT \
--build-arg MC_HELPER_BASE_URL=http://host.docker.internal:8008
```

Now the image can be built like normal, and it will install mc-image-helper from the locally built copy.
