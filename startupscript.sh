#!/bin/bash

# sometimes curl isn't installed by default
if ! command -v curl &> /dev/null; then
    echo "curl not installed, installing..."
    sudo apt-get install -y curl
fi

INSTALL_JAVA=false
if ! command -v java &> /dev/null; then
    echo "java not installed"
    INSTALL_JAVA=true
else
    if java --version | grep 16. &> /dev/null 
    then
        echo "java is installed, but openjdk 16 not detected"
        INSTALL_JAVA=true
    fi
fi

# minecraft 1.17 needs at least java 16
if $INSTALL_JAVA; then
    echo "downloading openjdk 16..."
    sudo mkdir -p /usr/java/openjdk
    cd /usr/java/openjdk
    curl -O -J --progress-bar https://download.java.net/java/GA/jdk16.0.1/7147401fd7354114ac51ef3e1328291f/9/GPL/openjdk-16.0.1_linux-x64_bin.tar.gz
    
    echo "installing openjdk 16..."
    tar -xzf openjdk-16.0.1_linux-x64_bin.tar.gz
    echo "" >> /etc/profile
    echo "#OpenJDK 16" >> /etc/profile
    echo "JAVA_HOME=/usr/java/openjdk/jdk-16.0.1" >> /etc/profile
    echo 'PATH=$PATH:$HOME/bin:$JAVA_HOME/bin' >> /etc/profile
    echo "export JAVA_HOME" >> /etc/profile
    echo "export PATH" >> /etc/profile
    source /etc/profile

    # set update-alternatives (can cause some problems otherwise)
    sudo update-alternatives --install "/usr/bin/java" "java" "/usr/java/openjdk/jdk-16.0.1/bin/java" 1
    sudo update-alternatives --set "java" "/usr/java/openjdk/jdk-16.0.1/bin/java"
fi

echo "openjdk 16 installed"
