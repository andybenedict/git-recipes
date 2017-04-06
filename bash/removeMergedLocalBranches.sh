#!/bin/bash

#Define a default pattern for limiting the branches to be removed
pattern=""
#Define a default branch to check against
target="origin/master"

#Define xterm control code variables
green="\033[1;32m"
yellow="\033[1;33m"
red="\033[1;31m"
end="\033[m"

#parse the options
while getopts ":fghp:t:" opt; do
  case $opt in
    #Help Data
    h)
      echo -e "\nusage: ./removeMergedLocalBranches.sh -f -g [-p <pattern>] [-t <targetBranch>]\n"
      echo -e "  Options:"
      echo -e "\t-f   fetch from all remotes before checking local branches\n"
      echo -e "\t-g   output messaging in greyscale\n"
      echo -e "\t-p   the grep pattern used to limit the branches to remove"
      echo -e "\t       *note* all patterns start from the first character"
      echo -e "\t          of the branch name, so in order to match any part"
      echo -e "\t          of the branch name, begin your pattern with .*\n"
      echo -e "\t-t   target branch to base check on   Default: origin/master"
      
      exit 0
      ;;
    #turn on greyscale mode
    g)
      green=""
      yellow=""
      red=""
      end=""
      ;;
    #Fetch before check
    f)
      git fetch --all
      ;;
    #Set pattern if supplied
    p)
      pattern=$OPTARG
      ;;
    #Set target if supplied
    t)
      target=$OPTARG
      ;;
    #user has supplied an invalid option
    \?)
      echo -e "${red}Invalid option: -$OPTARG${end}" >&2
      exit 1
      ;;
    #user has not supplied a required argument
    :)
      echo -e "${red}Option -$OPTARG requires an argument.${end}" >&2
      exit 1
      ;;
  esac
done

#Fetch the SHA-1 hash for the target branch
targetsha=`git rev-parse $target 2> /dev/null`
if [ $? -ne 0 ]; then
    echo -e "${red}The target specified cannot be resolved, please double check the reference.${end}" >&2
    exit 1
fi

#Check to see if the current branch has been merged, output a notice if it is
currentBranchMatch=`git branch --merged $targetsha | grep "^* $pattern" | xargs`
if [ -n "$currentBranchMatch" ]
then
    echo -e "\n${yellow}The current branch has been merged into $target, but cannot be deleted.${end}"
    other=" other"
else
    other=""
fi

#Check for branches that have been merged
branches=`git branch --merged $targetsha | grep "^  $pattern" | xargs`
if [ -z "$branches" ]
then
    if [ -z "$pattern" ]
    then
        echo -e "\n${green}No$other local branches merged into $target found${end}\n"
        exit 0
    else
        echo -e "\n${green}No$other local branches merged into $target match the pattern '$pattern'${end}\n"
        exit 0
    fi
fi

#Remove the branches that have been merged
if [ -z "$pattern" ]
then
    echo -e "\n${green}Deleting local branches merged into $target${end}\n"
else
    echo -e "\n${green}Deleting local branches merged into $target that match the pattern '$pattern'${end}\n"
fi
git branch -D $branches
