#!/bin/bash

runInit()
{
    CurDir=`pwd`
    BinDir="./bin"
    mkdir -p ${BinDir}

    HMBuildDir="${CurDir}/HM-16.19+SCM/build/linux"
    HMBinDir="${CurDir}/HM-16.19+SCM/bin"
    HMDecoder="HMDecoder"
    HMEncoder="HMEncoder"
}

runBuildHM()
{
    echo -e "\033[32m ****************************************************** \033[0m"
    echo -e "\033[32m    start to build HM                                   \033[0m"
    echo -e "\033[32m ****************************************************** \033[0m"

    cd ${HMBuildDir}
    make clean
    make
    if [ $? -ne 0 ]; then
        echo -e "\033[31m ****************************************************** \033[0m"
        echo -e "\033[31m    HM build failed! pelease double check!              \033[0m"
        echo -e "\033[31m ****************************************************** \033[0m"
        exit 1
    fi

    mkdir -p ${BinDir}
    cp -f "${HMBinDir}/TAppDecoderStatic"  "${BinDir}/${HMDecoder}"
    cp -f "${HMBinDir}/TAppEncoderStatic"  "${BinDir}/${HMEncoder}"

    cd -
}

runMain()
{
    runInit
    runBuildHM
}

#****************************************************************
runMain




