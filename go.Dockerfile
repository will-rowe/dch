FROM golang:1.23

RUN apt-get update && apt-get install -y \
    zsh \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Get OhMyZSH
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true

# Set Zsh as the default shell
RUN chsh -s /bin/zsh

# Copy custom .zshrc file to the container's user directory
COPY .zshrc /root/.zshrc
RUN chmod 644 /root/.zshrc
RUN echo "source /root/.zshrc" >> /root/.zshenv
