#!/bin/bash

#Default to the HEAD commit
commit=HEAD

#Define xterm control code variables
green="\033[1;32m"
red="\033[1;31m"
end="\033[m"

#parse the options
while getopts ":vhgc:" opt; do
  case $opt in
    #Help Data
    h)
      echo -e "\nusage: ./mergeCheck.sh -v -g [-c <commit>]\n"
      echo -e "  Options:"
      echo -e "\t-v   output more data about the merge including the full diff\n"
      echo -e "\t-g   output messaging in greyscale\n"
      echo -e "\t-c   merge commit to validate   Default: HEAD"
      
      exit 0
      ;;
    #turn on verbose mode
    v)
      verbose='true'
      ;;
    #turn on gray scale mode
    g)
      green=""
      red=""
      end=""
      ;;
    #see if a commit is specified
    c)
      commit=$OPTARG
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

#Fetch the SHA-1 hash for the merge commit
commitsha=`git rev-parse $commit 2> /dev/null`
if [ $? -ne 0 ]; then
    echo -e "${red}Commit not found.${end}" >&2
    exit 1
else
    echo -e "\n${green}Generating Merge Statistics for ${commitsha}${end}"
fi

#Fetch the SHA-1 hash for the left parent
leftparent=`git rev-parse $commit^1 2> /dev/null`
if [ $? -ne 0 ]; then
    echo -e "${red}No Parents found.${end}" >&2
    exit 1
fi

#Fetch the SHA-1 hash for the right parent
rightparent=`git rev-parse $commit^2 2> /dev/null`
if [ $? -ne 0 ]; then
    echo -e "${red}Commit is not a merge.${end}" >&2
    exit 1
fi

#Verify that the merge only has 2 parents
thirdparent=`git rev-parse $commit^3 2> /dev/null`
if [ $? -eq 0 ]; then
    echo -e "${red}Statistics can only be generated for merges with two parents.${end}" >&2
    exit 1
else
    echo -e "${green}Comparing merge of \n  ${rightparent} \n    into \n  ${leftparent}${end}"
fi

#Fetch the SHA-1 hash for the merge base
mergebase=`git merge-base $commit^1 $commit^2 2> /dev/null`
if [ $? -ne 0 ]; then
    echo -e "${red}Merge base not found.${end}" >&2
    exit 1
else
    echo -e "${green}Merge base is ${mergebase}${end}"
fi

echo -e "\n${green}Parsing Commits${end}"

#If not verbose, output summary data
if [ -z ${verbose+x} ]; then
    changes=`diff <(git diff $leftparent $commitsha) <(git diff $mergebase $rightparent) | grep -E "^> \+|^< \+|^> \-|^< \-" | wc -l`
    echo -e " $changes changes found between the resolution and the original diff:"
    
    echo -e "\n${green}Resolution Summary${end}"
    git diff --stat $leftparent $commitsha | grep insertions | grep deletions

    echo -e "\n${green}Original Diff Summary${end}"
    git diff --stat $mergebase $rightparent | grep insertions | grep deletions
#If verbose, output complete data
else
    diff <(git diff $leftparent $commitsha) <(git diff $mergebase $rightparent) | grep -E "^> \+|^< \+|^> \-|^< \-"
    
    echo -e "\n${green}Resolution${end}"
    git diff --stat $leftparent $commitsha

    echo -e "\n${green}Original Diff${end}"
    git diff --stat $mergebase $rightparent
fi
