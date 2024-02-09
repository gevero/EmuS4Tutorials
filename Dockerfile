# Base rocky linux image
FROM rockylinux:9

# install preliminary libraries
RUN yum install -y wget bzip2 which git mesa-libGLU libXrender libXcursor libXft libXinerama make

# get miniconda and install and setup it
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh
ENV PATH "$PATH:/opt/conda/bin"
RUN conda init
RUN source /root/.bashrc

# install relevant conda packages
RUN conda create -n "photonics" python=3.9
SHELL ["conda", "run", "-n", "photonics", "/bin/bash", "-c"] # Make RUN commands use the new environment:
RUN conda install nomkl
RUN conda install -y numpy scikit-learn=1.02
RUN conda install -y scipy=1.7.3
RUN conda install -y jupyter=1.0.0
RUN conda install -y gcc_linux-64=7.5.0 gxx_linux-64=7.5.0 gfortran_linux-64=7.5.0
RUN conda install -y nose
RUN conda install -y xarray matplotlib

# installing gmsh
RUN mkdir programs
WORKDIR /programs
RUN wget --quiet https://gmsh.info/bin/Linux/gmsh-4.12.2-Linux64.tgz
RUN tar -xvzf gmsh-4.12.2-Linux64.tgz && rm *.tgz
WORKDIR /usr/bin
RUN ln -s /programs/gmsh-4.12.2-Linux64/bin/gmsh
WORKDIR /programs

# installing EMUstack
WORKDIR /usr/bin
RUN ln -s /opt/conda/bin/f2py f2py3
WORKDIR /programs
RUN git clone https://github.com/bjornsturmberg/EMUstack.git
WORKDIR /programs/EMUstack/backend/fortran/
RUN rm Makefile && mv Makefile-pre_compiled_libs Makefile
RUN make
WORKDIR /programs

# installing S4
RUN dnf install -y gcc-c++
RUN git clone https://github.com/UnipvPhysicsLectures/S4_Legacy.git
WORKDIR /programs/S4_Legacy
RUN make clean && make S4_pyext
WORKDIR /programs
RUN mv S4_Legacy S4

# getting code and setup env vars
ENV OPENBLAS_NUM_THREADS=1
ENV OMP_NUM_THREADS=1
RUN echo -e "ulimit -s unlimited" >> /root/.bashrc
RUN echo -e "conda activate photonics" >> /root/.bashrc
RUN source /root/.bashrc
COPY ./ /ComputationalPhotonics
WORKDIR /ComputationalPhotonics
RUN mkdir msh
RUN chmod +x benchmark

# run jupyterlab
EXPOSE 8888
COPY run.sh /usr/bin/run.sh 
RUN chmod +x /usr/bin/run.sh                                 
ENTRYPOINT [ "/usr/bin/run.sh" ]

# Install Ubuntu package dependencies, needed to add an explicit timezone
# RUN apt-get update && \
#     DEBIAN_FRONTEND=noninteractive \
#     TZ=America \
#     apt-get install -y \
#     python3-numpy \
#     python3-dev \
#     python3-scipy \
#     python3-nose \
#     python3-pip \
#     python3-matplotlib \
#     gfortran \
#     make \
#     gmsh \
#     libatlas-base-dev \
#     libblas-dev \
#     liblapack-dev \
#     libsuitesparse-dev \
#     nano \
#     ssh

# install jupyter and jupyterlab, oh my zsh and then cleanup
# RUN pip3 install jupyter -U && pip3 install jupyterlab
# RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.2/zsh-in-docker.sh)" --     -t mh     -p https://github.com/zsh-users/zsh-autosuggestions     -p https://github.com/zsh-users/zsh-completions     -p https://github.com/zsh-users/zsh-syntax-highlighting
# RUN chsh -s /usr/bin/zsh &&  apt-get clean && rm -rf /var/lib/apt/lists/*

# Add the NumBAT source code -> Will be overwritten when used with mounted volumes! (which is good)
# COPY ./ /home/EMUstack/

# Compile the Fortran code, only use when running tests or copying compiled source to host
# WORKDIR /home/EMUstack/backend/fortran/
# RUN make

# Add the backend files to the python path, sets shell so jupyterlab uses zsh and dark mode
# ENV PYTHONPATH "${PYTHONPATH}:/home/EMUstack/backend/"
# ENV SHELL "/usr/bin/zsh"
# COPY overrides.json /usr/local/share/jupyter/lab/settings/

# Run the tests (when desired), Fails 1 test simple_mk_msh with a tolerance issue with ubuntu 22.04
# WORKDIR /home/EMUstack/tests/
# RUN nosetests3

# Change the working directory to final spot
# WORKDIR /home/EMUstack/

# Finish with jupyterlab by default, can always use "/bin/zsh" to start in shell
# EXPOSE 8888
# CMD "jupyter-lab" "--ip='0.0.0.0'" "--port=8888" "--no-browser" "--allow-root"