#!/bin/bash

code4libjournal:
	OUTDIR=data/code4libjournal
	mkdir -p data/code4libjournal
	./scripts/code4libjournal.pl > data/code4libjournal/code4libjournal.bib
