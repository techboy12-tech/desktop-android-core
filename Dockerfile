# ===================================================================
# SWAPLAB ENGINE: DESKTOP ANDROID CORE (PUBLIC BASE IMAGE)
# Repo: swaplab-engine/desktop-android-core
# Description: Public base image providing a transparent, optimized,
# and pre-configured environment strictly for Android builds.
# ===================================================================
FROM ubuntu:22.04 AS desktop-android-core

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8

# -------------------------------------------------------------------
# 1. System Dependencies Installation
# -------------------------------------------------------------------
# Kept: openjdk-21-jdk, git, unzip, gradle dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openjdk-21-jdk \
    jq \
    python3 \
    unzip \
    curl \
    zip \
    git \
    locales \
    wget \
    gnupg \
    lsb-release \
    apt-transport-https \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

# -------------------------------------------------------------------
# 2. Security Tools (Transparency Layer)
# -------------------------------------------------------------------
# Trivy (SCA - Software Composition Analysis)
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends trivy && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# 3. Android SDK & Build Tools Installation
# -------------------------------------------------------------------
ARG ANDROID_SDK_VERSION=11076708
ARG ANDROID_BUILD_TOOLS_VERSION=35.0.0
ARG ANDROID_PLATFORM_VERSION=35
ENV ANDROID_HOME=/usr/lib/android-sdk
ENV PATH=$PATH:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Download & Setup Command Line Tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    curl -o android_tools.zip https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip && \
    unzip -d ${ANDROID_HOME}/cmdline-tools android_tools.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm android_tools.zip

# Accept Licenses & Install Platforms
RUN yes | sdkmanager --licenses && \
    sdkmanager --install "platform-tools" "platforms;android-${ANDROID_PLATFORM_VERSION}" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"

# -------------------------------------------------------------------
# 4. Gradle Installation
# -------------------------------------------------------------------
ARG GRADLE_VERSION=8.11.1
ENV GRADLE_HOME=/opt/gradle/gradle-${GRADLE_VERSION}
RUN curl -o gradle.zip -L https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -d /opt/gradle gradle.zip && \
    rm gradle.zip

# -------------------------------------------------------------------
# 5. Node.js Environment
# -------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# 6. Mobile Development CLI Suite (Android Focused)
# -------------------------------------------------------------------
# Installing all necessary CLIs for SwapLab Desktop support
# - xml2js & plist: Kept for compatibility with Cordova Hooks (config.xml parsing)
RUN npm install -g \
    @capacitor/cli@7.1.0 \
    cordova \
    framework7-cli \
    xml2js \
    plist

# Final Environment Variables Setup
ENV GRADLE_USER_HOME=/github/workspace/.gradle
ENV PATH=${PATH}:${GRADLE_HOME}/bin

CMD ["npm", "version"]