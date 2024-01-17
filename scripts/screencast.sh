function screencast() {
    ffmpeg -f x11grab -i :1 -r 30 $1
}
