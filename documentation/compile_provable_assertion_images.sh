#!/usr/bin/env bash

name="provable_assertion_images";

for i in {0..7}
do
    pdflatex "\def\sourceNo{$i}\input{$name.tex}";
    convert -density 600x600 $name.pdf -quality 90 $name.$i.png;
done

rm $name.aux $name.log $name.pdf