define(`calc',
       `syscmd(`echo "io.write(string.format(\"%0.3f\", $1))" | lua')')
