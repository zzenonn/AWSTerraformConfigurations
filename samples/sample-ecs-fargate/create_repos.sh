#!/bin/bash

aws ecr create-repository --repository-name catdog/cat --image-tag-mutability "IMMUTABLE" --image-scanning-configuration scanOnPush=true
aws ecr create-repository --repository-name catdog/dog --image-tag-mutability "IMMUTABLE" --image-scanning-configuration scanOnPush=true
aws ecr create-repository --repository-name catdog/home --image-tag-mutability "IMMUTABLE" --image-scanning-configuration scanOnPush=true