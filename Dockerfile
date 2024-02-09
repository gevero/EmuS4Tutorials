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