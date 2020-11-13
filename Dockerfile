FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openssh-server
RUN apt-get install -y git build-essential
RUN apt-get install -y software-properties-common
RUN apt-get update
RUN mkdir /var/run/sshd
RUN echo 'root:Intel123!' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir /mediasdk
WORKDIR /mediasdk
RUN apt-get install -y gpg-agent wget
RUN wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | apt-key add -
RUN apt-add-repository 'deb [arch=amd64] https://repositories.intel.com/graphics/ubuntu bionic main'

#Install run-time packages for dev
RUN apt-get update
RUN apt-get -y install \
    intel-opencl \
    intel-level-zero-gpu level-zero
    
#view correct permission
RUN stat -c "%G" /dev/dri/render*
RUN groups ${USER}

#Run mediasdk example
ADD head-pose-face-detection-female-and-male.mp4 /mediasdk
RUN ffmpeg \
    -i head-pose-face-detection-female-and-male.mp4 \
    -an -vcodec copy -bsf h264_mp4toannexb \
    -f h264 bbb1920x1080.264

#decode to raw YUV format using ffmpeg
RUN ffmpeg -i bbb1920x1080.264 bbb1920x1080.yuv
RUN sample_decode h264 -i bbb1920x1080 -o bbb1920x1080.yuv
RUN ll

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
