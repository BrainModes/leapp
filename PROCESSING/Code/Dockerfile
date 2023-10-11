FROM ubuntu:18.04
MAINTAINER Patrik Bey <patrik.bey@charite.de>
# needed for  ants within mrtrix3
ARG DEBIAN_FRONTEND=noninteractive

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

# Download FreeSurfer
RUN apt-get -qq update && \
    apt-get install -yq --no-install-recommends \
      bc \
      bzip2 \
      ca-certificates \
      curl \
      libgomp1 \
      perl-modules \
      tar \
      tcsh \
      wget \
      libxmu6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    wget -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz \
    | tar zxv -C /opt \
      --exclude='freesurfer/trctrain' \
      --exclude='freesurfer/subjects/fsaverage_sym' \
      --exclude='freesurfer/subjects/fsaverage3' \
      --exclude='freesurfer/subjects/fsaverage4' \
      --exclude='freesurfer/subjects/fsaverage5' \
      --exclude='freesurfer/subjects/fsaverage6' \
      --exclude='freesurfer/subjects/cvs_avg35' \
      --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
      --exclude='freesurfer/subjects/bert' \
      --exclude='freesurfer/subjects/V1_average' \
      --exclude='freesurfer/average/mult-comp-cor' \
      --exclude='freesurfer/lib/cuda' \
      --exclude='freesurfer/lib/qt' && \
    echo "cHJpbnRmICJrcnp5c3p0b2YuZ29yZ29sZXdza2lAZ21haWwuY29tXG41MTcyXG4gKkN2dW12RVYzelRmZ1xuRlM1Si8yYzFhZ2c0RVxuIiA+IC9vcHQvZnJlZXN1cmZlci9saWNlbnNlLnR4dAo=" | base64 -d | sh

# Set up the environment
ENV OS=Linux \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA= \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FSF_OUTPUT_FORMAT=nii.gz \
    MNI_DIR=/opt/freesurfer/mni \
    LOCAL_DIR=/opt/freesurfer/local \
    FREESURFER_HOME=/opt/freesurfer \
    FSFAST_HOME=/opt/freesurfer/fsfast \
    MINC_BIN_DIR=/opt/freesurfer/mni/bin \
    MINC_LIB_DIR=/opt/freesurfer/mni/lib \
    MNI_DATAPATH=/opt/freesurfer/mni/data \
    FMRI_ANALYSIS_DIR=/opt/freesurfer/fsfast \
    PERL5LIB=/opt/freesurfer/mni/lib/perl5/5.8.5 \
    MNI_PERL5LIB=/opt/freesurfer/mni/lib/perl5/5.8.5 \
    PATH=/opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:$PATH


RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
       libxext6 \
       libxpm-dev \
       libxt6 \
       unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "Downloading MATLAB Compiler Runtime ..." \
    && curl -fsSL --retry 5 -o /tmp/mcr.zip https://ssd.mathworks.com/supportfiles/downloads/R2016b/deployment_files/R2016b/installers/glnxa64/MCR_R2016b_glnxa64_installer.zip \
    && unzip -q /tmp/mcr.zip -d /tmp/mcrtmp \
    && /tmp/mcrtmp/install -destinationFolder /opt/matlabmcr-2016b -mode silent -agreeToLicense yes \
    && rm -rf /tmp/*

RUN echo "MATLAB compiler installation finished"
# Install miniconda2
# still need python 2 for gradunwarp
ENV PATH="/usr/local/miniconda/bin:$PATH"
# RUN curl -fsSLO https://repo.continuum.io/miniconda/Miniconda2-4.5.4-Linux-x86_64.sh && \
####### updated conda version
RUN curl -fsSLO https://repo.continuum.io/miniconda/Miniconda2-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda2-4.7.12.1-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda2-4.7.12.1-Linux-x86_64.sh && \
    conda config --add channels conda-forge && \
    conda install -y mkl=2019.3 mkl-service=2.0.2 numpy=1.16.4 nibabel=2.4.1 pandas=0.24.2 && sync && \
    conda clean -tipsy && sync && \
    pip install --no-cache-dir pybids==0.9.1

RUN echo "Miniconda installation finished"

# Install connectome-workbench
WORKDIR /opt
RUN apt-get -qq update && \
    apt-get install -yq libfreetype6 libglib2.0 && \
    # wget -q https://ftp.humanconnectome.org/workbench/workbench-linux64-v1.3.2.zip -O wb.zip \
    wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip -O wb.zip \
    && unzip wb.zip \
    && rm wb.zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV CARET7DIR="/opt/workbench/bin_linux64"

RUN echo "Workbench installation finished"


# Install HCP Pipelines and MSM binaries
RUN apt-get -qq update && \
    apt-get install -yq --no-install-recommends gcc g++ libglu1 && \
    rm -rf /tmp/* && \
    wget -qO- https://github.com/Washington-University/HCPpipelines/archive/v4.0.0.tar.gz | tar xz -C /tmp && \
    mv /tmp/* /opt/HCP-Pipelines && \
    mkdir /opt/HCP-Pipelines/MSMBinaries && \
    wget -q https://github.com/ecr05/MSM_HOCR/releases/download/1.0/msm_ubuntu14.04 -O /opt/HCP-Pipelines/MSMBinaries/msm &&  \
    chmod 755 /opt/HCP-Pipelines/MSMBinaries/msm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "HCP pipelines installation finished"


WORKDIR /

ENV HCPPIPEDIR=/opt/HCP-Pipelines
ENV HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates \
    HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries \
    HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config \
    HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts \
    HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts \
    HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts \
    HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts \
    HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts \
    HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts \
    HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts \
    HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts \
    HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts \
    HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts \
    MSMBINDIR=${HCPPIPEDIR}/MSMBinaries \
    MSMCONFIGDIR=${HCPPIPEDIR}/MSMConfig

## Install the validator
# RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash - && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends nodejs && \
#     npm install -g bids-validator@1.2.3 && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# RUN echo "BIDS validator installation finished"


# RUN wget -q http://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
#     chmod 775 fslinstaller.py && \
#     python2 /fslinstaller.py -d /opt/fsl -V 6.0.4 -q && \
#     rm -f /fslinstaller.py
# RUN which immv || ( echo "FSLPython not properly configured; re-running" && rm -rf /opt/fsl/fslpython && /opt/fsl/etc/fslconf/fslpython_install.sh -f /opt/fsl || ( cat /tmp/fslpython*/fslpython_miniconda_installer.log && exit 1 ) )

# Install FSL
RUN curl https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.1-centos6_64.tar.gz \
         | tar -xz -C /usr/local
RUN /usr/local/fsl/etc/fslconf/fslpython_install.sh -f /usr/local/fsl

RUN echo "FSL installation finished"

# Configure environment
# ENV FSLDIR=/usr/local/fsl
ENV FSLDIR=/opt/fsl
ENV FSL_DIR="${FSLDIR}" \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PATH=${FSLDIR}/bin:$PATH \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=${FSLDIR} \
    LD_LIBRARY_PATH=${FSLDIR}/lib:$LD_LIBRARY_PATH \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    FSLOUTPUTTYPE=NIFTI_GZ

# install gradient_unwarp.py (v1.1.0)
WORKDIR /tmp
RUN wget -q https://github.com/Washington-University/gradunwarp/archive/v1.1.0.zip && \
  unzip v1.1.0.zip && \
  cd gradunwarp-1.1.0 && \
  python setup.py install && \
  rm -rf gradunwarp-1.1.0 v1.1.0.zip

RUN echo "gradunwarp installation finished"

# Fix Topup scripts

RUN wget -q https://raw.githubusercontent.com/Washington-University/HCPpipelines/dc7aae3a7a1cae920b390500d85536681b14108c/global/scripts/TopupPreprocessingAll.sh -O /opt/HCP-Pipelines/global/scripts/TopupPreprocessingAll.sh

# Install MCR 2016b
ENV MATLABCMD="/opt/matlabmcr-2016b/v91/toolbox/matlab" \
    MATLAB_COMPILER_RUNTIME="/opt/matlabmcr-2016b/v91" \
    LD_LIBRARY_PATH="/opt/matlabmcr-2016b/v91/runtime/glnxa64:/opt/matlabmcr-2016b/v91/bin/glnxa64:/opt/matlabmcr-2016b/v91/sys/os/glnxa64:$LD_LIBRARY_PATH"


# overwrite matlab mcr shared object
RUN rm /opt/matlabmcr-2016b/v91/sys/os/glnxa64/libstdc++.so.6 && \
    ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/matlabmcr-2016b/v91/sys/os/glnxa64/libstdc++.so.6


# install mrtrix3 for tractography
RUN echo "START: mrtrix3 installation"


# Install MRtrix3 compile-time dependencies.
RUN apt-get -qq update \
    && apt-get install -yq --no-install-recommends \
          git \
          libeigen3-dev \
          libfftw3-dev \
          libgl1-mesa-dev \
          libpng-dev \
          libtiff5-dev \
          zlib1g-dev 
        #   qt5-default \
        #   libqt5opengl5  \s
        #   libqt5opengl5-dev \
        #   libqt5svg5-dev 



# ENV PATH="/opt/qt5/bin:$PATH"
#### trying apt update && apt upgrade

RUN git clone -b "master" --depth 1 https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3

RUN cd /opt/mrtrix3/ && \
    ./configure -nogui && \
    ./build -persistent -nopaginate

#save env path mrtrix3
ENV MRTRIXDIR=/opt/mrtrix3
# add mrtrix to PATH variable
ENV PATH="/opt/mrtrix3/bin:$PATH"

# Install ANTs

RUN apt-get update
RUN apt-get install -y ants
ENV ANTSDIR=/usr/lib/ants
ENV ANTSPATH=${ANTSDIR}
# add ants to PATH variable
ENV PATH="/usr/lib/ants:$PATH"


# include dcm2niix for DICOM conversion
RUN wget -q https://github.com/rordenlab/dcm2niix/releases/download/v1.0.20200331/dcm2niix_lnx.zip && \
    unzip dcm2niix_lnx.zip && \
    mkdir /usr/lib/dcm2niix && \
    mv dcm2niix /usr/lib/dcm2niix/dcm2niix && \
    rm -r dcm2niix_lnx.zip

ENV PATH="/usr/lib/dcm2niix:$PATH"



# fix freesurfer recon-all.v6
RUN mkdir ${HCPPIPEDIR_FS}/custom
RUN wget -q https://raw.githubusercontent.com/Washington-University/HCPpipelines/master/FreeSurfer/custom/recon-all.v6.hires && \
    mv recon-all.v6.hires ${HCPPIPEDIR_FS}/custom/recon-all.v6.hires && \
    chmod -R 755 ${HCPPIPEDIR_FS}/custom/recon-all.v6.hires 

RUN wget -q https://raw.githubusercontent.com/Washington-University/HCPpipelines/master/FreeSurfer/custom/conf2hires && \
    mv conf2hires ${HCPPIPEDIR_FS}/custom/conf2hires && \
    chmod -R 755 ${HCPPIPEDIR_FS}/custom/conf2hires 

RUN wget -q https://raw.githubusercontent.com/Washington-University/HCPpipelines/master/FreeSurfer/custom/longmc && \
    mv longmc ${HCPPIPEDIR_FS}/custom/longmc && \
    chmod -R 755 ${HCPPIPEDIR_FS}/custom/longmc

ENV PATH="${HCPPIPEDIR_FS}/custom:${PATH}"
 # add structural processing scripts

RUN mv /opt/HCP-Pipelines/PreFreeSurfer/scripts/BiasFieldCorrection_sqrtT1wXT1w.sh \
    /opt/HCP-Pipelines/PreFreeSurfer/scripts/BiasFieldCorrection_sqrtT1wXT2w.sh
RUN echo "Fixing BiasFieldCorrection_sqrtT1wXT1w Typo"

# set environment variables
ENV FSLDIR=/usr/local/fsl
ENV FSL_DIR="${FSLDIR}" \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PATH=${FSLDIR}/bin:$PATH \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=${FSLDIR} \
    LD_LIBRARY_PATH=${FSLDIR}/lib:$LD_LIBRARY_PATH \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    FSLOUTPUTTYPE=NIFTI_GZ

# update python3 & install needed libraries
RUN apt-get update
RUN apt-get -y install python3-pip
RUN pip3 install nibabel && \
    pip3 install matplotlib && \
    pip3 install progressbar && \
    pip3 install scipy

# add structural processing steps
RUN mkdir /opt/LeAPP-Structural
ENV LEAPP_STRUCTDIR=/opt/LeAPP-Structural
COPY Code/Structural ${LEAPP_STRUCTDIR}
RUN chmod -R 755 ${LEAPP_STRUCTDIR}

# add functional processing scripts
RUN mkdir /opt/LeAPP-Functional
ENV LEAPP_FUNCTDIR=/opt/LeAPP-Functional
COPY Code/Functional ${LEAPP_FUNCTDIR}
RUN chmod -R 755 ${LEAPP_FUNCTDIR}

# add diffusion processing scripts
RUN mkdir /opt/LeAPP-Diffusion
ENV LEAPP_DWIDIR=/opt/LeAPP-Diffusion
COPY Code/Diffusion ${LEAPP_DWIDIR}
RUN chmod -R 755 ${LEAPP_DWIDIR}

# RUN mkdir /opt/L2TVB-Templates
ENV LEAPP_TEMPLATES=/opt/LeAPP-Templates
COPY Code/Templates.zip /opt/Templates.zip
RUN unzip -q /opt/Templates.zip -d /opt
RUN mv /opt/Templates/* /opt/LeAPP-Templates
RUN rm /opt/Templates.zip
RUN rm -r /opt/Templates
RUN chmod -R 755 ${LEAPP_TEMPLATES}

# add TVB miscelaneous scripts
RUN mkdir /opt/LeAPP-Misc
ENV LEAPP_MISCDIR=/opt/LeAPP-Misc
COPY Code/Misc ${LEAPP_MISCDIR}
RUN chmod -R 755 ${LEAPP_MISCDIR}

COPY Code/RUN.sh /usr/local/bin/RUN.sh
RUN chmod +x /usr/local/bin/RUN.sh

# call run script 
CMD ["bash", "/usr/local/bin/RUN.sh"]