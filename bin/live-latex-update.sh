#!/bin/bash

file="$1"
windowid="$2"
basename="${file%.tex}"
logfile="${basename}.log"
auxfile="${basename}.aux"


if head -n 5 "$file" | grep -i -q 'xelatex' > /dev/null 2>&1 ; then
    execprog="xelatex"
    echo "XeLaTeX document detected."
elif sed -n -e '/\\documentclass/,/\\begin{[[:space:]]*document[[:space:]]*}/p' "$file" \
	| grep '\usepackage\(\[.*\]\|\){.*\(pstricks\|pst-\).*}' > /dev/null 2>&1 ; then
    execprog="latex"
    echo "Using plain LaTeX"
else
    execprog="pdflatex" 
    echo "Using PDFLaTeX."
fi 
if ${execprog} -interaction=nonstopmode -halt-on-error -file-line-error -synctex=1 "$file"  ; then
   if cat "$logfile" | grep -i -q "undefined citations\|undefined references" > /dev/null 2>&1 ; then
      if bibtex "$auxfile"  ; then
           if ! ${execprog} -interaction=nonstopmode -halt-on-error -file-line-error -synctex=1 "$file" ; then
                echo -n "failure" > "$HOME/.config/live-latex-preview/lastresult" 2>/dev/null
                echo
                echo "failure"
                exit 1
           fi
      else 
            echo -n "bibfail" > "$HOME/.config/live-latex-preview/lastresult" 2>/dev/null
            echo
            echo "bibfail"
            exit 2
      fi
   fi
   if cat "$logfile" | grep -i -q 'rerun to get' > /dev/null 2>&1 ; then
           if ! ${execprog} -interaction=nonstopmode -halt-on-error -file-line-error -synctex=1 "$file" ; then
              echo -n "failure" > "$HOME/.config/live-latex-preview/lastresult" 2>/dev/null
              echo
              echo "failure"
              exit 1
           fi
   fi
   if [ $execprog == "latex" ] ; then
       dvifile=${basename}.dvi
       psfile=${basename}.ps
       if [ ! -e $dvifile ] ; then
           echo "'${dvifile} does not exist. failure"
	   exit 1
       else
	   if ! dvips $dvifile ; then
	       echo "'${dvifile}' corrupted. failure"
	   fi
       fi

       if [ ! -e $psfile ] ; then
           echo "'${psfile} does not exist. failure"
	   exit 1
       else
	   if ! ps2pdf $psfile ; then
	       echo "'${psfile}' corrupted. failure"
	   fi
       fi

   fi
   if [[ $windowid != "999999" ]] ; then
       echo "Updating MuPDF window."
       xdotool key --window $windowid r &> /dev/null
   fi
   echo -n "success" > "$HOME/.config/live-latex-preview/lastresult" 2>/dev/null
   echo
   echo "success"
else
   echo -n "failure" > "$HOME/.config/live-latex-preview/lastresult" 2>/dev/null
   echo
   echo "failure"
   exit 1
fi
exit 0
