/divert\(-1\)/ {
    action = 0
    print $0
    next
}
/divert\(0\)dnl/ {
    action = 1
    print $0
    next
}
{
   if (!action) {
       print $0
       x = $0
       while(match(x, /define\(/)) {
           s = substr(x, RSTART + RLENGTH)
           x = s
           sub(/,.*$/, "", s)
           sub(/^[` \t]*/, "", s)
           sub(/[' \t]*$/, "", s)
           macros[s] = s
       }
   } else {
       i = 1; n = length($0)
       esc = 0; zhe = 0
       while (i <= n) {
           x = substr($0, i)
           if (index(x, "`") == 1 || index(x, "‘") == 1) esc++
           if (esc) {
               if (index(x, "'") == 1 || index(x, "’") == 1) esc--
           } else {
               if (index(x, "（") == 1) zhe = 1
               if (zhe) {
                   depth = 1
                   for (j = 1; j < n; j++) {
                       y = substr(x, j + 1)
                       if (index(y, "（") == 1) {
                           depth++
                       }
                       if (index(y, "）") == 1) {
                           depth--
                       }
                       if (depth == 0) break
                   }
                   if (depth != 0) {
                       print "错误：在 <" substr(x, 1, length(x) / 10) "...> 存在非封闭括号"
                   } else {
                       m = length("）")
                       before = substr($0, 1, i - 1)
                       macro = substr($0, i, j + m)
                       after = substr($0, i + j + m)
                   }
                   sub(/^（/, "(", macro)
                   sub(/）$/, ")", macro)
                   gsub(/，/, ",", macro)
                   prefix = "`'indir"
                   macro = prefix macro
                   i = i + length(prefix)
                   $0 = before macro after
                   n = length($0)
                   zhe = 0
               }
           }
           i++
       }
       for (a in macros) {
           i = 1; n = length($0)
           esc = 0; zhe = 0
           while (i <= n) {
               x = substr($0, i)
               if (index(x, "`") == 1 || index(x, "‘") == 1) esc++
               if (esc) {
                   if (index(x, "'") == 1 || index(x, "’") == 1) esc--
               } else {
                   if (index(x, a) == 1) {
                       y = substr($0, 1, i - 1)
                       if (!match(y, /indir\($/)) {
                           zhe = 1
                       }
                   }
                   if (zhe) {
                       prefix = "`'indir("
                       before = substr($0, 1, i - 1)
                       macro = prefix a ")"
                       after = substr($0, i + length(a))
                       $0 = before macro after
                       i = i + length(prefix)
                       n = length($0)
                       zhe = 0
                   }
               }
               i++
           }
       }
       gsub(/‘/, "`", $0)
       gsub(/’/, "'", $0)
       print $0
   }
}
