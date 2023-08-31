if(NOT DEFINED KAUTIL_THIRD_PARTY_DIR)
    set(KAUTIL_THIRD_PARTY_DIR ${CMAKE_CURRENT_BINARY_DIR}/third_party)
    file(MAKE_DIRECTORY "${KAUTIL_THIRD_PARTY_DIR}")
endif()

if(NOT EXISTS ${KAUTIL_THIRD_PARTY_DIR}/cmake/CMakeExecuteGit.cmake)
    file(DOWNLOAD https://raw.githubusercontent.com/kautils/CMakeExecuteCommand/v0.0.1/CMakeExecuteGit.cmake "${KAUTIL_THIRD_PARTY_DIR}/cmake/CMakeExecuteCommand.cmake")
endif()

include("${KAUTIL_THIRD_PARTY_DIR}/cmake/CMakeExecuteGit.cmake")

macro(CMakeGitCloneMinimal prfx)
    
    cmake_parse_arguments( ${prfx} "CLEAR;FORCE_UPDATE;VERBOSE;VERBOSE_GIT" "TAG;BRANCH;HASH;REPOSITORY_URI;REPOSITORY_NAME;REPOSITORY_REMOTE;DESTINATION" "" ${ARGV})
    
    set(${prfx}_prfx_unsetter)
    set(${prfx}_unsetter)
    list(APPEND ${prfx}_prfx_unsetter ${prfx}_unsetter;CLEAR;FORCE_UPDATE;VERBOSE;VERBOSE_GIT;TAG;BRANCH;HASH;REPOSITORY_URI;REPOSITORY_NAME;REPOSITORY_REMOTE;DESTINATION)
    list(APPEND ${prfx}_unsetter __repo_tag)
    set(__repo_tag ${${prfx}_TAG})
    set(__repo_branch ${${prfx}_BRANCH})
    set(__repo_digest ${${prfx}_HASH})

    list(APPEND ${prfx}_unsetter __repo_uri __repo_remote __repo_name __repo_force_update)
    set(__repo_remote ${${prfx}_REPOSITORY_REMOTE})
    if(NOT DEFINED __repo_remote)
        set(__repo_remote origin)
    endif()
    set(__repo_uri ${${prfx}_REPOSITORY_URI})
    set(__repo_name ${${prfx}_REPOSITORY_NAME})
    set(__repo_force_update ${${prfx}_FORCE_UPDATE})
    
    list(APPEND ${prfx}_unsetter __result_var)
    set(__result_var ${prfx})
    
    list(APPEND ${prfx}_unsetter __dest __dest_p __dest_c)
    set(__dest ${${prfx}_DESTINATION})
    set(__dest_p ${__dest}/${__repo_name})
    set(__dest_c ${__dest_p}/${__repo_name})
    
    list(APPEND ${prfx}_unsetter __repo_tag __repo_branch __repo_digest)
    set(__repo_tag ${${prfx}_TAG})
    set(__repo_branch ${${prfx}_BRANCH})
    set(__repo_digest ${${prfx}_HASH})
    
    if(${${prfx}_VERBOSE})
        include(CMakePrintHelpers)
        foreach(__var ${${prfx}_unsetter})
            cmake_print_variables(${__var})
        endforeach()
        unset(__var)
    endif()
    
    list(APPEND ${prfx}_unsetter __verbose_option)
    if(${${prfx}_VERBOSE})
        set(__verbose_option VERBOSE)
    endif()
    
    if((NOT DEFINED __repo_tag) AND ((NOT DEFINED __repo_branch) AND (NOT DEFINED __repo_digest)))
        message(FATAL_ERROR "must specify id to clone via HASH or TAG or BRANCH.")
    elseif( (DEFINED __repo_tag) AND ((DEFINED __repo_branch) OR (DEFINED __repo_digest)))
        message(FATAL_ERROR "only one id can be selected in HASH or TAG or BRANCH.")
    elseif( (DEFINED __repo_branch) AND ((DEFINED __repo_tag) OR (DEFINED __repo_digest)))
        message(FATAL_ERROR "only one id can be selected in HASH or TAG or BRANCH.")
    elseif( (DEFINED __repo_digest) AND ((DEFINED __repo_tag) OR (DEFINED __repo_branch)))
        message(FATAL_ERROR "only one id can be selected in HASH or TAG or BRANCH.")
    endif()
    
    
    if(${__repo_force_update} OR (${${__result_var}} STREQUAL "") OR (NOT EXISTS ${${__result_var}}/.git))
        file(MAKE_DIRECTORY ${__dest_c})
        CMakeExecuteGit(execgit COMMAND git init DIR ${__dest_c} ${__verbose_option} ASSERT)
        CMakeExecuteGit(execgit COMMAND git remote add origin ${__repo_uri} DIR ${__dest_c} ${__verbose_option})
        
        if(DEFINED __repo_tag)
            CMakeExecuteGit(execgit COMMAND git fetch ${__repo_remote} --tags ${__repo_tag} --depth=1 DIR ${__dest_c} ${__verbose_option} ASSERT)
            CMakeExecuteGit(execgit COMMAND git checkout tags/${__repo_tag} DIR ${__dest_c} ${__verbose_option} ASSERT)
            CMakeExecuteGit(execgit COMMAND git rev-list -n 1 ${__repo_tag} DIR ${__dest_c} ${__verbose_option} ASSERT)
            set(__want_hash ${execgit_OUTPUT_VARIABLE})
        elseif(DEFINED __repo_branch)
            CMakeExecuteGit(execgit COMMAND git fetch ${__repo_remote} ${__repo_branch} DIR ${__dest_c} ${__verbose_option} ASSERT)
            CMakeExecuteGit(execgit COMMAND git checkout ${__repo_branch} DIR ${__dest_c} ${__verbose_option} ASSERT)
            CMakeExecuteGit(execgit COMMAND git rev-list -n 1 ${__repo_branch} DIR ${__dest_c} ${__verbose_option} ASSERT)
            set(__want_hash ${execgit_OUTPUT_VARIABLE})
        elseif(DEFINED __repo_digest)
            CMakeExecuteGit(execgit COMMAND git fetch ${__repo_remote} ${__repo_digest} DIR ${__dest_c} ${__verbose_option} ASSERT)
            CMakeExecuteGit(execgit COMMAND git checkout ${__repo_digest} DIR ${__dest_c} ${__verbose_option} ASSERT)
            set(__want_hash ${__repo_digest})
        endif()
        
        if(DEFINED execgit_RESULT_VARIABLE AND (0 EQUAL ${execgit_RESULT_VARIABLE}))
            string(SUBSTRING ${__want_hash} 0 7 __want_hash)
            unset(${__result_var} CACHE)
            set(${__result_var} ${__dest_p}/${__want_hash}  CACHE STRING "")
            if(EXISTS ${${__result_var}})
                file(REMOVE_RECURSE ${${__result_var}})
            endif()
            file(RENAME ${__dest_c} ${${__result_var}})
        endif()
        CMakeExecuteGit(execgit CLEAR)
    endif()
    
    foreach(__var ${${prfx}_unsetter})
        unset(${__var})
    endforeach()
    foreach(__var ${${prfx}_prfx_unsetter})
        unset(${prfx}_${__var})
    endforeach()
    unset(__var)
    
    unset(${prfx}_UNPARSED_ARGUMENTS)
    unset(${prfx}_unsetter)
    unset(${prfx}_prfx_unsetter)
    
endmacro()
