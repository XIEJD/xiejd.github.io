#!/bin/bash

fun_test(){
    echo "It's a test."
}

fun_serve(){
    jekyll serve --watch
}

fun_newpost(){
    DATEPREFIX=$(date +%Y-%m-%d);
    TEMPLATE="---
title: $1
date: $DATEPREFIX
---

<!-- START doctoc -->
<!-- END doctoc -->"
    FILENAME="./_posts/$DATEPREFIX-$1";
    touch $FILENAME;
    echo "$TEMPLATE" >> $FILENAME;
    echo "created $FILENAME";
}

main(){
    case "$1" in 
        "test") 
            fun_test;;
        "serve")
            fun_serve;;
        "new")
            fun_newpost $2;;
        * ) 
            echo "Unsupported Command";;
    esac 
    exit 0
}

main $1 $2
