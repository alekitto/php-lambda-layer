ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

php73.zip:
	docker run -v $(ROOT_DIR):/var/layer lambci/lambda:build-nodejs8.10 /var/layer/build.sh

upload: php73.zip
	./upload.sh

publish: php73.zip
	./publish.sh

clean:
	rm php73.zip

.PHONY: clean upload publish
