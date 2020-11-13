
set -o errexit

tempFontFile=".fontrender_temp"



function renderString() {
  printf "$2" > $tempFontFile
  
#  ./fontrender "font/12px_outline/" "$tempFontFile" "font/12px_outline/table.tbl" "$1.png"
  ./fontrender "rsrc/font/" "$tempFontFile" "rsrc/font/table.tbl" "$1.png"
}

function renderStringNarrow() {
  printf "$2" > $tempFontFile
  
#  ./fontrender "font/12px_outline/" "$tempFontFile" "font/12px_outline/table.tbl" "$1.png"
  ./fontrender "rsrc/font/" "$tempFontFile" "table/dandy_en_narrow.tbl" "$1.png"
}



make blackt && make fontrender

#renderString intro_render_1 "1999. Mankind is attacked by superweapons of unknown origin."
#renderString intro_render_2 "Four robots, appearing suddenly out of nowhere."
#renderString intro_render_3 "Are they a country's secret weapons? The start of an alien invasion?"
#renderString intro_render_4 "The identity of these mysterious robots remains unknown..."

renderString roboselect_render_1 "Budget"
renderString roboselect_render_2 "Completion Bonus"
renderString roboselect_render_3 "Mobilization Cost"
renderString roboselect_render_4 "mil.Åè"


rm $tempFontFile