define(`%中文',
`\usemodule[zhfonts][size=$2]
\setupzhfonts[serif][regular=$1]'
)
define(`%宋体', `simsun')
define(`%小四', `11pt')
define(`%文始', `\starttext')
define(`%文终', `\stoptext')
define(`%插图', `\placefigure[here][]{$1}{\externalfigure[$2][$3]}')
define(`*版宽', `\textwidth')
define(`%宽', `width=$1')
