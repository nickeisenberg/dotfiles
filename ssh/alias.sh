#--------------------------------------------------
# External and intenal ssh aliases to the jetson
# Sets up a tunnel so that neo4j will work
#--------------------------------------------------
exjet() {
    ip=$(jq -r '.external_home_ip' ~/.credentials/ipaddr.json)
    ssh -p 2201 -L 7474:localhost:7474 -L 7687:localhost:7687 "eisenbnt@$ip"
}

injet() {
    ip=$(jq -r '.eisenbnt_at_SDRD3' ~/.credentials/ipaddr.json)
    ssh -p 2201 -L 7474:localhost:7474 -L 7687:localhost:7687 "eisenbnt@$ip"
}
#--------------------------------------------------
