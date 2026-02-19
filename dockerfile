FROM ubuntu:22.04


# Arg par default si non surcharger au build
ARG SSH_USER=onionuser
ARG SSH_PORT=4242
ARG WEB_PORT=80

# j'installe tout ce dont jai besoin
RUN apt-get update && apt-get install -y \
nginx tor openssh-server vim \
&& rm -rf /var/lib/apt/lists/*

# Je cree le user a mettre en dynamique arg ensuite je pense par la suite et ne pas oublier de set un pwd sinon user bloquer et creation de tout les fichier et repertoire qui von me servir
# Cree un nouvel utilisateur nomme "onionuser" avec un  home (-m cree /home/onionuser) et definit son shell par défaut sur /bin/bash.
# Supprime le mot de passe de l'utilisateur onionuser (desactive l'authentification par mot de passe pour cet utilisateur).
# Cree le repertoire /home/onionuser/.ssh avec les permissions 0700 (seul le proprietaire peut y acceder), et l'assigne a l'utilisateur et groupe onionuser
# Cree un fichier vide authorized_keys dans le répertoire .ssh (ce fichier contiendra les clef publiques SSH autorisees).
# Definit les permissions 0600 sur le fichier authorized_keys (lecture/ecriture pour le propriétaire seulement, obligatoire pour SSH).
# Assigne recursivement l'utilisateur et le groupe onionuser comme proprietaires de tout le contenu du répertoire .ssh.
RUN useradd -m -s /bin/bash ${SSH_USER} && \ 
   passwd -d ${SSH_USER} && \
    install -d -m 0700 -o ${SSH_USER} -g ${SSH_USER} /home/${SSH_USER}/.ssh && \
    touch /home/${SSH_USER}/.ssh/authorized_keys && \
    chmod 0600 /home/${SSH_USER}/.ssh/authorized_keys && \
    chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh

# Copie via /tmp car defois ca ajoute des \n ou autres
# Copie la clef publique ft_onion_key.pub depuis le contexte de build vers /tmp/ dans l'image, en assignant directement onionuser comme propiertaire.
COPY --chown=${SSH_USER}:${SSH_USER} ./ssh_key_folder/ft_onion_key.pub /tmp/ft_onion_key.pub

# Copie du fichier et setting des droits
# Lit le contenu de la clef temporaire et l'ecrit dans le fichier authorized_keys (remplace le contenu vide par la clef publique).
# Supprime la clef publique temporaire de /tmp/ pour des raisons de sécurite (ne pas laisser de clef en clair).
# Assure que le fichier authorized_keys appartient bien a onionuser (deja fait en haut mais la ca marche donc je laisse)
# Fixe definitivement les permissions 600 sur authorized_keys (SSH refuse les connexions si >600).

RUN cat /tmp/ft_onion_key.pub > /home/${SSH_USER}/.ssh/authorized_keys && \
    rm /tmp/ft_onion_key.pub && \
    chown ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh/authorized_keys && \
    chmod 600 /home/${SSH_USER}/.ssh/authorized_keys


# Config nginx
COPY nginx.conf.template /tmp/nginx.conf.template
RUN sed "s/__WEB_PORT__/${WEB_PORT}/g" \
        /tmp/nginx.conf.template > /etc/nginx/sites-available/default

# Config SSH
COPY sshd_config.template /tmp/sshd_config.template
RUN sed -e "s/__SSH_PORT__/${SSH_PORT}/g" \
        -e "s/__SSH_USER__/${SSH_USER}/g" \
        /tmp/sshd_config.template > /etc/ssh/sshd_config

# Config TOR
COPY torrc.template /tmp/torrc.template
RUN sed -e "s/__SSH_PORT__/${SSH_PORT}/g" \
        -e "s/__WEB_PORT__/${WEB_PORT}/g" \
        /tmp/torrc.template > /etc/tor/torrc

# Page statique
COPY html/* /var/www/html

# Configurer permissions Tor (debian-tor c'est le user par default on est sur ubuntu va comprendre)
RUN chown -R debian-tor:debian-tor /var/lib/tor && chmod 700 /var/lib/tor

# Creer le repertoire de logs Tor
RUN mkdir -p /var/log/tor && chown debian-tor:debian-tor /var/log/tor && chmod 750 /var/log/tor   

# Healthcheck: verifier que les services sont actifs
# HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
#   CMD pgrep -x nginx && pgrep -x tor && pgrep -x sshd || exit 1   

# Demarrer les services ssh et tor dans mon entry point et lancer ngninx en premier plan pour maintenant le container actif explication dans 'entrypoint
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
