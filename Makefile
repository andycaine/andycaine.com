SHELL := /bin/bash
STACK_NAME ?= andycaine-dot-com

clean:
	rm -rf public
	rm -rf .aws-sam
	rm -f packaged.yaml

public:
	docker run -it \
		-v ${PWD}:/src \
		-e HUGO_ENV=production \
		-p8080:8080 hugomods/hugo:0.135.0 --gc --minify

dev:
	docker run -it \
		-v ${PWD}:/src \
		-v ${PWD}/hugo_cache:/tmp/hugo_cache \
		-p8080:8080 hugomods/hugo:0.135.0 server -p 8080

.aws-sam/build: public template.yaml
	sam build

packaged.yaml: .aws-sam/build
	sam package --resolve-s3 --output-template-file $@

publish: packaged.yaml
	sam publish --template packaged.yaml

deploy: .aws-sam/build
	sam deploy \
    	--capabilities CAPABILITY_IAM CAPABILITY_AUTO_EXPAND \
    	--stack-name ${STACK_NAME} \
    	--resolve-s3

destroy:
	sam delete --stack-name ${STACK_NAME}
