# TODO：支持嵌套宏调用
BEGIN {
    # 一些全局变量
    start = 0
    macros[0] = 0
    stack[0] = 0
}
{
    if ($0 ~ /^ *@宏开 *$/) { start = 1; next }
    if ($0 ~ /^ *@宏闭 *$/) { start = 0; next }
    if (!start) {
        # 扫描宏定义
        x = $0
        while (match(x, /define\(([^,]+)/, s) > 0) {
            x = substr(x, RSTART + RLENGTH)
            sub(/^ *` */, "", s[1])
            sub(/ *' *$/, "", s[1])
            macros[s[1]] = s[1]
        }
    } else {
        x = $0; x_id = 1
        while (match(x, /[（\(]/, s)) {
            new_start = RSTART + RLENGTH
            before = substr(x, 1, new_start - 1)
            x = substr(x, new_start)
            x_id = x_id + new_start - 1
            # 处理转义
            escape = 0
            if (before ~ /‘/) {
                escape = 1
                step = advance(x, "‘", "’")
                if (escape < 2) {
                    print "[[错误：在 <" substr(x, 1, 5) "......> 附近存在非封闭引号！]]"
                } else {
                    x = substr(x, step + 1)
                    x_id = x_id + step
                    continue
                }
            }
            # 对宏调用语句进行标点符号替换
            step = advance(x, "（", "）")
            before = substr($0, 1, x_id - 2)
            after = substr($0, x_id + step)
            macro_body = substr($0, x_id - 1, step + 1)
            gsub(/（/, "(", macro_body)
            gsub( /）/, ")", macro_body)
            gsub( /，/, ",", macro_body)
            gsub( /‘/, "`", macro_body)
            gsub( /’/, "'", macro_body)
            $0 = before macro_body after
            # 有参宏（可能是嵌套形式）处理
            x = substr($0, x_id)
            step = advance(x, "(", ")")
            macro_body = substr($0, x_id - 1, step + 1)
            macro_body = indir_wrapper(macro_body)
            # $0 = before macro_body after
            # old_x_id = x_id
            # x_id = x_id - 2 + length("`'indir(`")
            internal_x_id = 1
            d = length("`'indir(`")
            x = substr(macro_body, d)
            g = x
            # 处理嵌套调用
            while (match(x, /\(/) > 0) {
                internal_new_start = RSTART + RLENGTH
                x = substr(x, internal_new_start)
                internal_x_id = internal_x_id + internal_new_start - 1
                internal_x_step = advance(x, "(", ")")
                internal_macro_body = substr(g, internal_x_id - 1, internal_x_step + 1)
                internal_macro_body = indir_wrapper(internal_macro_body)
                internal_before = substr(g, 1, internal_x_id - 2)
                internal_after = substr(g, internal_x_id + internal_x_step)
                g = internal_before internal_macro_body internal_after
                internal_x_id = internal_x_id - 2 + length("`'indir(`")
                x = substr(g, internal_x_id)
            }
            macro_body = "`'indir(" g
            $0 = before macro_body after
            x = after
            x_id = x_id - 1 + length(macro_body)
        }
        gsub(/‘/, "`")
        gsub(/’/, "'")
        # 处理无括号宏（无参宏）
        before = ""
        for (i in macros) {
            if (!macros[i]) continue;
            x = $0
            while ((j = index(x, macros[i])) > 0) {
                u = length(macros[i])
                before = before substr(x, 1, j - 1)
                after = substr(x, j + u)
                if (before ~ / *[（`‘(]$/ || after ~ /^[’）')] */) {
                    before = before macros[i]
                } else {
                    before = before "`'indir(`" macros[i] "')`'"
                }
                x = after
            }
            before = before x
            $0 = before
            before = ""
        }
    }
    print $0
}
function advance(x, left_mark, right_mark,   k, step, l, r)
{
    k = 1; step = 0
    while (1) {
        if (k == 0) {
            escape++
            break
        }
        l = index(x, left_mark)
        r = index(x, right_mark)
        if (r == 0) {
            break
        } else if (l == 0 || l > r) {
            x = substr(x, r + 1)
            step = step + r
            k--
        } else {
            x = substr(x, l + 1)
            step = step + l
            k++
        }
    }
    return step
}
# s 必须为`(...)` 形式的字符串
function indir_wrapper(s,    prefix, suffix) {
    if (match(s, /\(([^,\)]+)/, t) > 0) {
        sub(/^ */, "", t[1])
        sub(/ *$/, "", t[1])
        if (macros[t[1]]) {
            i = index(s, t[1])
            prefix = substr(s, 1, i - 1)
            suffix = substr(s, i + length(t[1]))
            s = prefix "`" t[1] "'" suffix
            s = "`'indir" s "`'"
        }
    }
    return s
}
