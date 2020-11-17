FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openssh-server
#RUN apt-get install -y git build-essential
RUN apt-get install -y software-properties-common
RUN apt-get install -y mesa-va-drivers
RUN apt-get install -y libdrm-dev
RUN apt-get install -y vainfo
RUN apt-get install -y git build-essential gcc make yasm autoconf automake cmake libtool checkinstall wget software-properties-common pkg-config libmp3lame-dev libunwind-dev zlib1g-dev libssl-dev
RUN apt-get update \
    && apt-get clean \
    && apt-get install -y --no-install-recommends libc6-dev libgdiplus wget software-properties-common
RUN mkdir /var/run/sshd
RUN echo 'root:Intel123!' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir /mediasdk
WORKDIR mediasdk
RUN export GST_VAAPI_ALL_DRIVERS=1
RUN export LIBVA_DRIVER_NAME=iHD
RUN export LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri
RUN wget https://www.ffmpeg.org/releases/ffmpeg-4.0.2.tar.gz
RUN tar -xzf ffmpeg-4.0.2.tar.gz 
RUN cd ffmpeg-4.0.2
RUN ls
RUN ./ffmpeg-4.0.2/configure --enable-gpl --enable-libmp3lame --enable-decoder=mjpeg,png --enable-encoder=png
RUN make
RUN make install

#Run mediasdk example
ADD head-pose-face-detection-female-and-male.mp4 /mediasdk
WORKDIR /mediasdk
RUN ffmpeg \
    -i head-pose-face-detection-female-and-male.mp4 \
    -an -vcodec copy -bsf h264_mp4toannexb \
    -f h264 bbb1920x1080.264

#decode to raw YUV format using ffmpeg
RUN ffmpeg -i bbb1920x1080.264 bbb1920x1080.yuv
RUN ffmpeg sample_decode h264 -i bbb1920x1080.264 bbb1920x1080.yuv
RUN ls

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
