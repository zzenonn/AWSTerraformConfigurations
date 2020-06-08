#!/bin/bash

aws ecr delete-repository --repository-name catdog/cat
aws ecr delete-repository --repository-name catdog/dog 
aws ecr delete-repository --repository-name catdog/home