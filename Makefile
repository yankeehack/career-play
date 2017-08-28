GCLOUD_PROJECT:=$(shell gcloud config list project --format="value(core.project)")
GCLOUD_SQL_CONNECTION:=$(shell gcloud sql instances describe career-db --format="value(connectionName)")

.PHONY: all
all: deploy

.PHONY: create-bucket
create-bucket:
	gsutil mb gs://$(GCLOUD_PROJECT)
    gsutil defacl set public-read gs://$(GCLOUD_PROJECT)

.PHONY: build
build:
	docker build -t gcr.io/$(GCLOUD_PROJECT)/career -f Dockerfiles/Dockerfile .

.PHONY: build_nginx
build_nginx:
	docker build -t gcr.io/$(GCLOUD_PROJECT)/career-nginx -f Dockerfiles/Dockerfile.nginx .

.PHONY: push
push: build build_nginx
	gcloud docker -- push gcr.io/$(GCLOUD_PROJECT)/career
	gcloud docker -- push gcr.io/$(GCLOUD_PROJECT)/career-nginx

.PHONY: asset_sync
asset_sync:
	python manage.py collectstatic --noinput
	gsutil rsync -R static/ gs://${GCLOUD_PROJECT}/static

.PHONY: template
template:
	sed "s/\$$GCLOUD_PROJECT/$(GCLOUD_PROJECT)/g" career.yaml > career-templated.yaml
	sed -i "" "s/\$$GCLOUD_SQL_CONNECTION/$(GCLOUD_SQL_CONNECTION)/g" career-templated.yaml

.PHONY: deploy
deploy: push asset_sync template
	kubectl create -f career-templated.yaml

.PHONY: deploy_only
deploy_only: template
	kubectl create -f career-templated.yaml

.PHONY: update
update:
	kubectl rolling-update polls --image=gcr.io/${GCLOUD_PROJECT}/career

.PHONY: delete
delete:
	kubectl delete deployment career
	kubectl delete service career