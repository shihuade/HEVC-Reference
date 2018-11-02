#!/bin/bash

runUsage()
{
    echo -e "\033[31m ***************************************** \033[0m"
    echo " Usage:                                                "
    echo "      $0  \$InputYUV  \$CfgFile  \$EncParam            "
    echo "                                                       "
    echo "          \$CfgFile   pattern or cfg file name         "
    echo "          \$EncParam  optional enc param               "
    echo "                                                       "
    echo "     example:  $0  xx_scc_1920x1080_30fps scc \"-aq 1\""
    echo -e "\033[31m ***************************************** \033[0m"
}

runInit()
{
    CurDir=`pwd`
    ScriptYUVInfo="./run_ParseYUVInfo.sh"
    BinDir="./bin"
    CfgDir="./cfg"
    BitStreamDir="./BitStream"

    mkdir -p ${BinDir}
    mkdir -p ${BitStreamDir}

    HMBuildDir="${CurDir}/HM-16.19+SCM/build/linux"
    HMBinDir="${CurDir}/HM-16.19+SCM/bin"
    HMDecoder="HMDecoder"
    HMEncoder="HMEncoder"
    Suffix="HMDec"

    aCfgList=("encoder_intra_high_throughput_rext.cfg" "encoder_intra_main_scc.cfg"\
              "encoder_lowdelay_main10.cfg"     "encoder_randomaccess_main10.cfg"\
              "encoder_intra_main.cfg"          "encoder_lowdelay_P_main.cfg"\
              "encoder_lowdelay_main_rext.cfg"  "encoder_randomaccess_main_rext.cfg"\
              "encoder_intra_main10.cfg"        "encoder_lowdelay_P_main10.cfg" \
              "encoder_lowdelay_main_scc.cfg"   "encoder_randomaccess_main_scc.cfg"\
              "encoder_intra_main_rext.cfg"     "encoder_lowdelay_main.cfg"\
              "encoder_randomaccess_main.cfg")
}

runInitHMParams()
{
    HMEncoder="HMEncoder"
    Profile="main"
    Level="42"
    YUVWidth="1280"
    YUVHeight="720"
    FrameRate="30"
    FramNum="10000"

    Suffix="HMEnc"
    HMEncCfgFile="./HMConfigure/encoder_lowdelay_main.cfg"
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

runPromptHMEnc()
{
    echo -e "\033[32m ****************************************************** \033[0m"
    echo -e "\033[32m InputYUV        is : $InputYUV                         \033[0m"
    echo -e "\033[32m OutputBitStream is : $OutputBitStream                  \033[0m"
    echo -e "\033[32m ReconstructYUV  is : $ReconstructYUV                   \033[0m"
    echo -e "\033[32m HMEncOption     is : $HMEncOption                      \033[0m"
    echo -e "\033[32m HMEncOptionPlus is : $HMEncOptionPlus                  \033[0m"
    echo -e "\033[32m HMEncCMD        is : $HMEncCMD                         \033[0m"
    echo -e "\033[32m ****************************************************** \033[0m"
}

runPromptHMDec()
{
    echo -e "\033[32m ****************************************************** \033[0m"
    echo -e "\033[32m InputBitStream  is : $InputBitStream                    \033[0m"
    echo -e "\033[32m OutputYUV       is : $OutputYUV                        \033[0m"
    echo -e "\033[32m HMDecOption     is : $HMDecOption                      \033[0m"
    echo -e "\033[32m HMDecCMD        is : $HMDecCMD                         \033[0m"
    echo -e "\033[32m ****************************************************** \033[0m"
}

runParseYUVFileInfo()
{
    YUVInfo=(`${ScriptYUVInfo} ${InputYUV}`)
    YUVWidth="${YUVInfo[0]}"
    YUVHeight="${YUVInfo[1]}"
    FrameRate="${YUVInfo[2]}"
    [ -z "${FrameRate}" ] && FrameRate="30"

    YUVName=`basename ${InputYUV}`
}

runEncodeWithHM()
{
    HMEncOption="-c ${HMEncCfgFile} -wdt ${YUVWidth}  -hgt ${YUVHeight} -fr ${FrameRate} -f ${FramNum} "
    HMEncOptionPlus="${EncParam}"
    HMEncCMD="${BinDir}/${HMEncoder}  -i ${InputYUV} ${HMEncOption} ${HMEncOptionPlus} -b ${OutputBitStream}"

    runPromptHMEnc

    #encode with HM encoder
${HMEncCMD}
    if [ $? -ne 0 ]; then
        echo -e "\033[31m ****************************************************** \033[0m"
        echo -e "\033[31m HM encode failed! please double check!                 \033[0m"
        echo -e "\033[31m ****************************************************** \033[0m"
    fi
}

runDecodeWithHM()
{
    #HMDecOption="--OutputDecodedSEIMessagesFilename HMDec_SEI_Info.txt "
    HMDecCMD="${HMDecoder} -b ${InputBitStream} ${HMDecOption} -o ${OutputYUV} "

    runPromptHMDec
    #encode with HM encoder
    ${HMDecCMD}
}

runHMEncAllCfg()
{
    for cfg in ${aCfgList[@]}
    do
        beMatch=`echo $cfg | grep ${CfgFile}`
        if [ "${beMatch}X" = "X" ];then
            continue
        fi

        echo -e "\033[34m encode with cfg file: $cfg \033[0m"
        Label=`basename $cfg | awk 'BEGIN {FS=".cfg"} {print $1}'`
        HMEncCfgFile="${CfgDir}/${cfg}"

        OutputBitStream="${BitStreamDir}/${YUVName}_${Suffix}_${Label}.265"
        runEncodeWithHM
    done
}

runCheck()
{
    if [ ! -e ${InputYUV} ];then
        echo -e "\033[31m InputYUV not exist, please double check! \033[0m"
        exit 1
    fi
}

runMain()
{
    runInit
    runInitHMParams
    runCheck
    runParseYUVFileInfo

    runBuildHM
    runHMEncAllCfg
}

#****************************************************************
if [ $# -lt 2 ];then
    runUsage
    exit 1
fi

InputYUV=$1
CfgFile=$2
EncParam=$3

runMain




