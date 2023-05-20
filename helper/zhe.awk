BEGIN { start = 0; macros[0] = 0 }
{
    if ($0 ~ /^ *@宏开 *$/) { start = 1; next }
    if ($0 ~ /^ *@宏闭 *$/) { start = 0; next }
    if (start) {
        k = 1; x = $0
        # 先处理有参数的宏
        while (match(x, /[^‘](（[^（）’]*）)[^’]/, s) > 0) {
            x = substr(x, RSTART + RLENGTH)
            if (match(s[1], /（([^，）]+)/, t) > 0) {
                sub(/^ */, "", t[1])
                sub(/ *$/, "", t[1])
                if (macros[t[1]]) {
                    a[k] = s[1]
                    b[k] = s[1]
                    accessed[t[1]] = 1 # 记录有参数的宏被访问过
                    j = index(b[k], t[1])
                    prefix = substr(b[k], 1, j - 1)
                    suffix = substr(b[k], j + length(t[1]))
                    b[k] = prefix "`" t[1] "'" suffix
                    gsub(/（/, "(", b[k])
                    gsub(/）/, ")", b[k])
                    gsub(/，/, ", ", b[k])
                    b[k] = "`'indir" b[k] "`'"
                    k++
                }
            }
        }
        for (i = 1; i < k; i++) {
            j = index($0, a[i])
            prefix = substr($0, 1, j - 1)
            suffix = substr($0, j + length(a[i]))
            $0 = prefix b[i] suffix
        }
        gsub(/‘/, "`", $0)
        gsub(/’/, "'", $0)
        # 处理无括号宏（无参宏）
        z = ""
        for (i in macros) {
            if (!macros[i] || accessed[i]) continue;
            x = $0
            while ((j = index(x, macros[i])) > 0) {
                u = length(macros[i])
                y = substr(x, j + u)
                z = z substr(x, 1, j - 1)
                prefix = substr(x, j-1, 1)
                if ((substr(x, j-1, 1) != "`") && (substr(x, j + u, 1) != "'")) {
                    z = z "`'indir(`" macros[i] "')`'"
                } else {
                    z = z macros[i]
                }
                x = y
            }
            z = z x
            $0 = z
            z = ""
        }
    } else {
        # 扫描宏定义
        k = 0; x = $0
        # 先处理有参数的宏
        while (match(x, /define\(([^,]+)/, s) > 0) {
            x = substr(x, RSTART + RLENGTH)
            sub(/^ *` */, "", s[1])
            sub(/ *' *$/, "", s[1])
            macros[s[1]] = s[1]
        }
    }
    print $0
}

