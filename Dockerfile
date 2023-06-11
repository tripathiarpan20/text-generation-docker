FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 as runtime

ARG COMMIT=ea0eabd266ba3a56e7692dda0f5021af1afb8e0f
ARG VENV=/workspace/venv

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Create workspace working directory
WORKDIR /workspace

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        python3.10-venv \
        python3-tk \
        bash \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        unzip \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 libtcmalloc-minimal4 \
        apt-transport-https ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python and pip
RUN ln -s /usr/bin/python3.10 /usr/bin/python && \
    curl https://bootstrap.pypa.io/get-pip.py | python && \
    rm -f get-pip.py

# Create and use the Python venv
RUN python3 -m venv ${VENV}

# Install Torch
RUN source ${VENV}/bin/activate && \
    pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip3 install --no-cache-dir xformers && \
    deactivate

# Clone the git repo of Text Generation Web UI and set version
WORKDIR /workspace
RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /workspace/text-generation-webui && \
    git reset ${COMMIT} --hard

# Complete Jupyter installation
RUN source ${VENV}/bin/activate && \
    pip3 install jupyterlab ipywidgets jupyter-archive jupyter_contrib_nbextensions && \
    jupyter contrib nbextension install --user && \
    jupyter nbextension enable --py widgetsnbextension && \
    pip3 install gdown && \
    deactivate

# Install the dependencies for Text Generation Web UI
WORKDIR /workspace/text-generation-webui
RUN source ${VENV}/bin/activate && \
    pip3 install -r requirements.txt && \
    deactivate

# Download model
RUN source ${VENV}/bin/activate && \
    cd /workspace/text-generation-webui && \
    python3 download-model.py PygmalionAI/pygmalion-6b

# Install runpodctl
RUN wget https://github.com/runpod/runpodctl/releases/download/v1.10.0/runpodctl-linux-amd -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Move Text Generation Web UI and venv to the root so it doesn't conflict with Network Volumes
WORKDIR /workspace
RUN mv /workspace/venv /venv
RUN mv /workspace/text-generation-webui /text-generation-webui

# Copy startup scripts for text-generation
COPY start_chatbot_server.sh /text-generation-webui/
COPY start_textgen_server.sh /text-generation-webui/

# Set up the container startup script
COPY start.sh /start.sh
RUN chmod a+x /start.sh

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]