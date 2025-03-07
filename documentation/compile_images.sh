#!/usr/bin/env bash

for i in {0..5}
do
    pdflatex "\def\sourceNo{$i}\input{design_images.tex}";
    convert -density 600x600 design_images.pdf -quality 90 design_images.$i.png;
done

rm design_images.aux design_images.log design_images.pdf