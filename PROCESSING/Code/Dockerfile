FROM ubuntu:22.04
LABEL maintainer="Patrik Bey <patrik.bey@bih-charite.de>"
LABEL version="0.1"

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    OS=Linux

# Install OS packages using apt-get
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
    libxmu6 \
    git \
    libeigen3-dev \
    libfftw3-dev \
    libgl1-mesa-dev \
    libpng-dev \
    libtiff5-dev \
    zlib1g-dev \
    libxext6 \
    libxpm-dev \
    libxt6 \
    libfreetype6 \
    libglib2.0 \
    gcc \
    g++ \
    libglu1 \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo "START:    intalling FreeSurfer"

RUN wget -q ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/6.0.0/freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz 
RUN tar zxv -f freesurfer-Linux-centos6_x86_64-stable-pub-v6.0.0.tar.gz -C /opt \
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
ENV FS_OVERRIDE=0 \
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

# # # fix freesurfer recon-all.v6
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
#  # add structural processing scripts

RUN echo "FINISHED:    intalling FreeSurfer"


RUN apt-get update -qq
RUN echo "START:    installing MATLAB Compiler Runtime" && \
    wget -qO /tmp/mcr.zip https://ssd.mathworks.com/supportfiles/downloads/R2016b/deployment_files/R2016b/installers/glnxa64/MCR_R2016b_glnxa64_installer.zip
RUN unzip -q /tmp/mcr.zip -d /tmp/mcrtmp
RUN /tmp/mcrtmp/install -destinationFolder /opt/matlabmcr-2016b -mode silent -agreeToLicense yes && \
    rm -rf /tmp/*

# overwrite matlab mcr shared object
RUN rm /opt/matlabmcr-2016b/v91/sys/os/glnxa64/libstdc++.so.6 && \
    ln -s /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/matlabmcr-2016b/v91/sys/os/glnxa64/libstdc++.so.6

ENV MATLABCMD="/opt/matlabmcr-2016b/v91/toolbox/matlab" \
    MATLAB_COMPILER_RUNTIME="/opt/matlabmcr-2016b/v91" 

ENV LD_LIBRARY_PATH="/opt/matlabmcr-2016b/v91/runtime/glnxa64:/opt/matlabmcr-2016b/v91/bin/glnxa64:/opt/matlabmcr-2016b/v91/sys/os/glnxa64:$LD_LIBRARY_PATH"

RUN echo "FINISHED:    installing MATLAB Compiler Runtime"
# Install miniconda2
# still need python 2 for gradunwarp

RUN echo "START:    installing Miniconda"


####### updated conda version
RUN wget -q https://repo.continuum.io/miniconda/Miniconda2-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda2-4.7.12.1-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda2-4.7.12.1-Linux-x86_64.sh

ENV PATH="/usr/local/miniconda/bin:$PATH"

RUN conda config --add channels conda-forge && \
    conda install -y mkl=2019.3 mkl-service=2.0.2 numpy=1.16.4 nibabel=2.4.1 pandas=0.24.2 && sync && \
    conda clean -tipsy && sync 



RUN echo "FINISHED:    installing Miniconda"

# # Install connectome-workbench
RUN echo "START:    installing connectome-workbench"
WORKDIR /opt
RUN wget -q https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v1.5.0.zip -O wb.zip \
    && unzip wb.zip \
    && rm wb.zip && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV CARET7DIR="/opt/workbench/bin_linux64"

RUN echo "FINISHED:    installing connectome-workbench"

RUN echo "START:   installing HCP pipelines"
# Install HCP Pipelines and MSM binaries
RUN wget -qO- https://github.com/Washington-University/HCPpipelines/archive/v4.0.0.tar.gz | tar xz -C /tmp && \
    mv /tmp/* /opt/HCP-Pipelines && \
    mkdir /opt/HCP-Pipelines/MSMBinaries && \
    wget -q https://github.com/ecr05/MSM_HOCR/releases/download/1.0/msm_ubuntu14.04 -O /opt/HCP-Pipelines/MSMBinaries/msm &&  \
    chmod 755 /opt/HCP-Pipelines/MSMBinaries/msm && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# RUN echo "Fixing BiasFieldCorrection_sqrtT1wXT1w Typo"
RUN mv /opt/HCP-Pipelines/PreFreeSurfer/scripts/BiasFieldCorrection_sqrtT1wXT1w.sh \
    /opt/HCP-Pipelines/PreFreeSurfer/scripts/BiasFieldCorrection_sqrtT1wXT2w.sh


RUN echo "FINISHED:   installing HCP pipelines"

RUN echo "START:   installing FSL"

### UPDATE to FSL6.0.6 from 6.0.4 to enable installation via fslinsaller.py
RUN wget -q http://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py -O /usr/local/fslinstaller.py 
RUN chmod 775 /usr/local/fslinstaller.py && \
    python2 /usr/local/fslinstaller.py -d /opt/fsl -V 6.0.6 && \
    rm -f /usr/local/fslinstaller.py

ENV FSLDIR=/opt/fsl
ENV FSL_DIR="${FSLDIR}" \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PATH=${FSLDIR}/bin:$PATH \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=${FSLDIR} \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    FSLOUTPUTTYPE=NIFTI_GZ

ENV LD_LIBRARY_PATH="${FSLDIR}/lib:$LD_LIBRARY_PATH"


RUN echo "FINISHED:   installing FSL"

# RUN echo "START:   installing gradunwarp"
# # install gradient_unwarp.py (v1.1.0)
# WORKDIR /tmp

# # RUN wget -q https://github.com/Washington-University/gradunwarp/archive/refs/tags/1.2.2.zip -O 1.2.2.zip

# # RUN unzip 1.2.2.zip && \
# #     cd gradunwarp-1.2.2 && \
# #     pip3 install -r requirements.txt && \
# #     pip3 install . && \
# #     cd .. && \
# #     rm -rf gradunwarp-1.2.2 1.2.2.zip

# ##########################
# #
# # UKBIOBANK GRADUNWARP, check compatibility!
# # https://git.fmrib.ox.ac.uk/fsl/gradunwarp
# #
# ##########################
# RUN conda create --solver=classic -yn gradunwarp.dev
# RUN conda install -y \
#     -c https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/public/ \
#     -c conda-forge \
#     -p /opt/fsl/envs/gradunwarp.dev \
#     fsl-gradunwarp

# RUN echo "FINISHED:   installing gradunwarp"

# Fix Topup scripts
RUN echo "START:   update TopUp scripts"
RUN wget -q https://raw.githubusercontent.com/Washington-University/HCPpipelines/dc7aae3a7a1cae920b390500d85536681b14108c/global/scripts/TopupPreprocessingAll.sh -O /opt/HCP-Pipelines/global/scripts/TopupPreprocessingAll.sh
RUN echo "FINISHED:   update TopUp scripts"

# Set ANTs variables
RUN echo "START:    installing ANTs"

RUN mkdir /opt/ants-tmp
RUN wget -q "https://github.com/ANTsX/ANTs/releases/download/v2.5.0/ants-2.5.0-ubuntu-22.04-X64-gcc.zip" -O /opt/ants-tmp/ants.zip
RUN unzip -q /opt/ants-tmp/ants.zip -d /opt/ants-tmp && \
    mv /opt/ants-tmp/ants-2.5.0 /opt/ants && \
    rm -r /opt/ants-tmp

ENV PATH=/opt/ants/bin:$PATH \
    ANTSDIR=/opt/ants \
    ANTSPATH=${ANTSDIR}

RUN echo "FINISHED:    installing ANTs"

RUN echo "START:    installing MRtrix3"
# # install mrtrix3 for tractography

RUN git clone -b "master" --depth 1 https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3
RUN cd /opt/mrtrix3/ && \
    ./configure -nogui && \
    ./build -persistent -nopaginate

#save env path mrtrix3
ENV MRTRIXDIR=/opt/mrtrix3
# add mrtrix to PATH variable
ENV PATH="/opt/mrtrix3/bin:$PATH"


RUN echo "FINISHED:    installing MRtrix3"


RUN echo "START:    integrate LeAPP Code"
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

RUN echo "FINISHED:    integrate LeAPP Code"

# call run script 
CMD ["bash", "/usr/local/bin/RUN.sh"]