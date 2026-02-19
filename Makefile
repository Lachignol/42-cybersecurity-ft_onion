NAME = ft_onion

-include .env

# Valeurs par défaut si non définies par .env
SSH_USER ?= Lachignol
SSH_PORT ?= 4242
WEB_PORT ?= 80

# Si les variables sont vides dans .env , utiliser les valeurs par défaut
ifeq ($(SSH_USER),)
SSH_USER = Lachignol
endif
ifeq ($(SSH_PORT),)
SSH_PORT = 4242
endif
ifeq ($(WEB_PORT),)
WEB_PORT = 80
endif

export SSH_USER SSH_PORT WEB_PORT

all: build run addr addr_ssh

build:
	docker build --no-cache \
	--build-arg SSH_USER="$(SSH_USER)" \
	--build-arg SSH_PORT="$(SSH_PORT)" \
	--build-arg WEB_PORT="$(WEB_PORT)" \
	-t ${NAME} .

run:
	docker run -d --name ${NAME} ${NAME}

addr:
	@echo "Address of website:"
	@echo "Waiting for Tor to generate hidden service address..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		if docker exec ${NAME} test -f /var/lib/tor/web/hostname 2>/dev/null; then \
			docker exec ${NAME} cat /var/lib/tor/web/hostname; \
			break; \
		fi; \
		if [ $$i -eq 10 ]; then \
			echo "ERROR: Tor hidden service address not generated after 10 seconds"; \
			exit 1; \
		fi; \
		sleep 1; \
	done


addr_ssh:
	@echo "Address of ssh:"
	@echo "Waiting for Tor to generate hidden service address..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		if docker exec ${NAME} test -f /var/lib/tor/ssh/hostname 2>/dev/null; then \
			docker exec ${NAME} cat /var/lib/tor/ssh/hostname; \
			break; \
		fi; \
		if [ $$i -eq 10 ]; then \
			echo "ERROR: Tor hidden service address not generated after 10 seconds"; \
			exit 1; \
		fi; \
		sleep 1; \
	done

bash:
	docker exec -it $(NAME) bash

clean:
	@docker stop ${NAME} 2>/dev/null || true
	@echo "Container stop."

fclean: clean
	@docker rm ${NAME} 2>/dev/null || true
	@docker rmi ${NAME} 2>/dev/null || true
	@echo "Image and container delete with success."

generate_key :
	mkdir -p ./ssh_key_folder
	@if [ -f ./ssh_key_folder/ft_onion_key ]; then \
		echo "ERREUR: one key is already present in  ./ssh_key_folder/ft_onion_key"; \
		echo "For delete : rm ./ssh_key_folder/ft_onion_key*"; \
		exit 1; \
	fi
	ssh-keygen -t ed25519 -f ./ssh_key_folder/ft_onion_key -N "" -C "ft-onion@42"
	@echo "Generate key in ./ssh_key_folder/"
	@echo "⚠️  WARNING: private key not protected by password"
	@echo "    private key: ./ssh_key_folder/ft_onion_key"
	@echo "    public key: ./ssh_key_folder/ft_onion_key.pub"

re: fclean build

.PHONY: all build run addr clean fclean
