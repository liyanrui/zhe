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
    if (start) {
        x = $0
        while (match(x, /（/, s)) {
            before = substr(x, 1, RSTART - 1)
            after = substr(x, RSTART + RLENGTH)
            x = substr(x, RSTART)
            stack[1] = RSTART
            a = advance(x, stack)
        }
    } else {
        # 扫描宏定义
        x = $0
        while (match(x, /define\(([^,]+)/, s) > 0) {
            x = substr(x, RSTART + RLENGTH)
            sub(/^ *` */, "", s[1])
            sub(/ *' *$/, "", s[1])
            macros[s[1]] = s[1]
        }
    }
    print $0
}

function advance(x, stack) {
    
}
