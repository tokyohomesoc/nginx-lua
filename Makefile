.SILENT :
.PHONY : nginx-lua

nginx-lua:
	docker build -t tokyohomesoc/nginx-lua:test .
	docker images
    docker history tokyohomesoc/nginx-lua:test
