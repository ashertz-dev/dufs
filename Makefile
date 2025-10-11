# 镜像名和版本
IMAGE_NAME ?= ghcr.io/scclabs/dufs
IMAGE_TAG  ?= v0.41.0-rc5
# IMAGE_TAG  ?= v0.41.0-$(shell date +%Y%m%d%H%M%S)

# buildx builder 名字（临时）
BUILDER := tmp-builder-$(shell date +%s)

# 平台
PLATFORMS := linux/amd64,linux/arm64

# 捕获 Ctrl+C / 错误时清理 buildx
.SHELLFLAGS = -ec

.PHONY: all build push clean

all: build

build:
	@echo ">>> 创建临时 buildx builder: $(BUILDER)"
	@echo ">>> 构建并推送镜像: $(IMAGE_NAME):$(IMAGE_TAG) for platforms: $(PLATFORMS)"
	@docker buildx create --name $(BUILDER) --use 
	@trap 'echo Cleaning up...; docker buildx rm -f $(BUILDER)' INT TERM EXIT; \
	BUILDKIT_NO_CLIENT_TOKEN=1 docker buildx build \
		--platform $(PLATFORMS) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
        --build-arg HTTP_PROXY=http://host.docker.internal:6152 \
        --build-arg HTTPS_PROXY=http://host.docker.internal:6152 \
        --build-arg NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 \
		--push \
		.


push:
    docker push $(IMAGE_NAME):$(IMAGE_TAG)

clean:
	@docker buildx rm -f $(BUILDER) || true