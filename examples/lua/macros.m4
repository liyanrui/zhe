zhdefine(计算器, `syscmd(`echo "io.write(string.format(\"%0.3f\", $1))" | lua')')
zhdefine(计算, ` indir(计算器, $1) ')
