SHELL := /bin/bash
STACK_NAME ?= andycaine-dot-com

clean:
	rm -rf public
	rm -rf .aws-sam
	rm -f packaged.yaml

public:
	HUGO_ENV=production hugo --gc --minify

dev:
	hugo server

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
