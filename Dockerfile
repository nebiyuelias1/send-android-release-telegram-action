FROM openjdk:17-jdk-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    wget \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Android SDK
ENV ANDROID_SDK_ROOT /sdk
ENV PATH "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
ENV GRADLE_USER_HOME /workspace/.gradle

# Install Android SDK Command Line Tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
    unzip tools.zip && \
    rm tools.zip && \
    mv cmdline-tools latest

# Install Android SDK components and bundletool
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" && \
    wget -q https://github.com/google/bundletool/releases/download/1.17.1/bundletool-all-1.17.1.jar -O /usr/local/bin/bundletool.jar && \
    chmod +x /usr/local/bin/bundletool.jar && \
    rm -rf $ANDROID_SDK_ROOT/.temp

    # Create Gradle cache volume
VOLUME /workspace/.gradle

WORKDIR /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
 