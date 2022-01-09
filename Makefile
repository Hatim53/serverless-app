build-app:
	cd src && zip ../lambda_function.zip lambda_function.py requirements.txt && cd -

deploy-lambda:
	cd infra/ && sudo terraform init && sudo terraform plan -out deploy-plan && sudo terraform apply "deploy-plan" && cd -
