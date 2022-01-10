build-app:
	cd src && zip ../lambda_function.zip lambda_function.py requirements.txt && cd -

deploy-lambda:
	cd infra/ && terraform init && terraform plan -out deploy-plan && terraform apply "deploy-plan" && cd -
