# A tool to set the dual monitor brightness

function dmb(){
    if [$2] 
    	then
    	    xrandr --output $2 --brightness $1
    	else
    	    xrandr --output HDMI-1-0 --brightness $1
    fi
}
