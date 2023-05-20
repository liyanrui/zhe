BEGIN { start = 0; macros[0] = 0 }
{
    if ($0 ~ /^ *@宏开 *$/) { start = 1; next }
    if ($0 ~ /^ *@宏闭 *$/) { start = 0; next }
    if (start) {
        k = 1; x = $0; y = ""
        # 先处理有参数的宏：不支持嵌套调用
        while (match(x, /(（[^（）‘’]*）)/, s) > 0) {
            a = s[1]
            before_a = substr(x, 1, RSTART - 1)
            after_a = substr(x, RSTART + RLENGTH)
            y = y before_a
            x = after_a
            # 处理转义
            if ((before_a ~ /‘ *$/) || (after_a ~ /^ *’/)) {
                y = y a
                continue
            } else {
                # 构造 m4 宏间接调用，即 indir(`宏名', 参数)
                if (match(a, /（([^，）]+)/, t) > 0) {
                    sub(/^ */, "", t[1])
                    sub(/ *$/, "", t[1])
                    if (macros[t[1]]) {
                        i = index(a, t[1])
                        prefix = substr(a, 1, i - 1)
                        suffix = substr(a, i + length(t[1]))
                        a = prefix "`" t[1] "'" suffix
                        gsub(/（/, "(", a)
                        gsub(/）/, ")", a)
                        gsub(/，/, ", ", a)
                        a = "`'indir" a "`'"
                    }
                }
                y = y a
            }
        }
        y = y x
        gsub(/‘/, "`", y)
        gsub(/’/, "'", y)
        $0 = y
        # 处理无括号宏（无参宏）
        z = ""
        for (i in macros) {
            if (!macros[i]) continue;
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

